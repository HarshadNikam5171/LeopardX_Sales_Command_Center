
@isTest
private class SalesTargetTriggerHandlerTest {

    /*
     * TEST 1:
     * Verify that Employee_Month_Key__c is generated
     * automatically when a Sales Target is inserted.
     */
    @isTest
    static void testKeyGeneratedOnInsert() {

        Sales_Target__c target = new Sales_Target__c(
            Target_Employee__c = UserInfo.getUserId(),
            Target_Month__c = Date.newInstance(2027, 3, 1),
            Target_Amount__c = 50000
        );

        // Before Insert trigger generates the key.
        insert target;

        // Query the saved record to verify the generated value.
        Sales_Target__c insertedTarget = [
            SELECT Id, Employee_Month_Key__c
            FROM Sales_Target__c
            WHERE Id = :target.Id
        ];

        String expectedKey = UserInfo.getUserId() + '-2027-03';

        System.assertEquals(
            expectedKey,
            insertedTarget.Employee_Month_Key__c,
            'Employee-month key should be generated during insert.'
        );
    }


    /*
     * TEST 2:
     * Verify that changing Target Month regenerates the key.
     */
    @isTest
    static void testKeyRegeneratedOnUpdate() {

        Sales_Target__c target = new Sales_Target__c(
            Target_Employee__c = UserInfo.getUserId(),
            Target_Month__c = Date.newInstance(2027, 3, 1),
            Target_Amount__c = 50000
        );

        insert target;

        // Change March to April.
        target.Target_Month__c = Date.newInstance(2027, 4, 1);
        update target;

        Sales_Target__c updatedTarget = [
            SELECT Employee_Month_Key__c
            FROM Sales_Target__c
            WHERE Id = :target.Id
        ];

        String expectedKey = UserInfo.getUserId() + '-2027-04';

        System.assertEquals(
            expectedKey,
            updatedTarget.Employee_Month_Key__c,
            'Key should be regenerated when Target Month changes.'
        );
    }


    /*
     * TEST 3:
     * Verify that changing the assigned employee regenerates the key.
     */
    @isTest
    static void testKeyRegeneratedWhenEmployeeChanges() {

        Sales_Target__c target = new Sales_Target__c(
            Target_Employee__c = UserInfo.getUserId(),
            Target_Month__c = Date.newInstance(2027, 5, 1),
            Target_Amount__c = 50000
        );

        insert target;

        // Find another active user to assign the target to.
        User anotherEmployee = [
            SELECT Id
            FROM User
            WHERE IsActive = true
            AND Id != :UserInfo.getUserId()
            LIMIT 1
        ];

        target.Target_Employee__c = anotherEmployee.Id;
        update target;

        Sales_Target__c updatedTarget = [
            SELECT Employee_Month_Key__c
            FROM Sales_Target__c
            WHERE Id = :target.Id
        ];

        String expectedKey = anotherEmployee.Id + '-2027-05';

        System.assertEquals(
            expectedKey,
            updatedTarget.Employee_Month_Key__c,
            'Key should be regenerated when Employee changes.'
        );
    }


    /*
     * TEST 4:
     * Verify that changing only Target Amount does not
     * unnecessarily change the Employee-Month Key.
     */
    @isTest
    static void testKeyUnchangedWhenOnlyAmountChanges() {

        Sales_Target__c target = new Sales_Target__c(
            Target_Employee__c = UserInfo.getUserId(),
            Target_Month__c = Date.newInstance(2027, 6, 1),
            Target_Amount__c = 50000
        );

        insert target;

        String originalKey = UserInfo.getUserId() + '-2027-06';

        // Change only the amount.
        target.Target_Amount__c = 75000;
        update target;

        Sales_Target__c updatedTarget = [
            SELECT Employee_Month_Key__c, Target_Amount__c
            FROM Sales_Target__c
            WHERE Id = :target.Id
        ];

        System.assertEquals(
            originalKey,
            updatedTarget.Employee_Month_Key__c,
            'Key should remain unchanged when only Target Amount changes.'
        );

        System.assertEquals(
            75000,
            updatedTarget.Target_Amount__c,
            'Target Amount should be updated successfully.'
        );
    }


    /*
     * TEST 5:
     * Verify that Salesforce rejects duplicate Employee + Month combinations.
     * The unique Employee_Month_Key__c field enforces this rule.
     */
    @isTest
    static void testDuplicateEmployeeMonthRejected() {

        Sales_Target__c firstTarget = new Sales_Target__c(
            Target_Employee__c = UserInfo.getUserId(),
            Target_Month__c = Date.newInstance(2027, 7, 1),
            Target_Amount__c = 50000
        );

        insert firstTarget;

        // Attempt to insert another target for the same employee and month.
        Sales_Target__c duplicateTarget = new Sales_Target__c(
            Target_Employee__c = UserInfo.getUserId(),
            Target_Month__c = Date.newInstance(2027, 7, 1),
            Target_Amount__c = 75000
        );

        /*
         * allOrNone = false:
         * Return SaveResult instead of throwing a DML exception
         * when this individual record fails.
         */
        Database.SaveResult result = Database.insert(duplicateTarget, false);

        System.assertEquals(
            false,
            result.isSuccess(),
            'Duplicate Employee-Month combination should be rejected.'
        );

        System.assertEquals(
            1,
            result.getErrors().size(),
            'An error should be returned for the duplicate record.'
        );

        System.assertEquals(
            StatusCode.DUPLICATE_VALUE,
            result.getErrors()[0].getStatusCode(),
            'Expected a duplicate value error.'
        );
    }


    /*
     * TEST 6:
     * Bulkification test.
     * Verify that the trigger correctly processes 200 records
     * in a single DML operation.
     */
    @isTest
    static void testBulkInsert200Records() {

        List<Sales_Target__c> targets = new List<Sales_Target__c>();

        // Prepare 200 records with unique employee-month combinations.
        for (Integer i = 0; i < 200; i++) {

            Integer yearValue = 2020 + (i / 12);
            Integer monthValue = Math.mod(i, 12) + 1;

            Sales_Target__c target = new Sales_Target__c(
                Target_Employee__c = UserInfo.getUserId(),
                Target_Month__c = Date.newInstance(
                    yearValue,
                    monthValue,
                    1
                ),
                Target_Amount__c = 50000
            );

            targets.add(target);
        }

        Test.startTest();

        // One DML statement inserts all 200 records.
        insert targets;

        Test.stopTest();

        // Collect inserted record IDs for the verification query.
        Set<Id> targetIds = new Set<Id>();

        for (Sales_Target__c target : targets) {
            targetIds.add(target.Id);
        }

        List<Sales_Target__c> insertedTargets = [
            SELECT Id, Target_Month__c, Employee_Month_Key__c
            FROM Sales_Target__c
            WHERE Id IN :targetIds
        ];

        System.assertEquals(
            200,
            insertedTargets.size(),
            'All 200 Sales Target records should be inserted.'
        );

        // Verify the exact generated key for every record.
        Set<String> generatedKeys = new Set<String>();

        for (Sales_Target__c target : insertedTargets) {

            String expectedKey =
                UserInfo.getUserId() + '-' +
                String.valueOf(target.Target_Month__c.year()) + '-' +
                String.valueOf(target.Target_Month__c.month()).leftPad(2, '0');

            System.assertEquals(
                expectedKey,
                target.Employee_Month_Key__c,
                'Incorrect Employee-Month Key generated for a bulk record.'
            );

            generatedKeys.add(target.Employee_Month_Key__c);
        }

        // All 200 generated keys must be unique.
        System.assertEquals(
            200,
            generatedKeys.size(),
            'All 200 Employee-Month Keys should be unique.'
        );
    }

    /*
 * TEST 7:
 * Verify that manually modifying the generated key
 * does not leave an incorrect Employee-Month Key saved.
 */
@isTest
static void testKeyCorrectedWhenManuallyChanged() {

    Sales_Target__c target = new Sales_Target__c(
        Target_Employee__c = UserInfo.getUserId(),
        Target_Month__c = Date.newInstance(2027, 8, 1),
        Target_Amount__c = 50000
    );

    insert target;

    // Simulate someone manually changing the generated key.
    target.Employee_Month_Key__c = 'INVALID-KEY';
    update target;

    Sales_Target__c updatedTarget = [
        SELECT Employee_Month_Key__c
        FROM Sales_Target__c
        WHERE Id = :target.Id
    ];

    String expectedKey = UserInfo.getUserId() + '-2027-08';

    System.assertEquals(
        expectedKey,
        updatedTarget.Employee_Month_Key__c,
        'Trigger should restore the correct key when manually modified.'
    );
    }
}    
