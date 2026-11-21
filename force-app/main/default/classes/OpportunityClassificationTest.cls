
@IsTest
// @IsTest tells Salesforce that this class contains test code.
// Salesforce executes this class during Apex testing.
private class OpportunityClassificationTest {

    @IsTest
    static void testClassificationBoundaries() {

        // STEP 1: Create a List to store multiple Opportunities.
        // We are testing five different Amount values.

        List<Opportunity> opportunities = new List<Opportunity>{

            // Amount is below 50,000, so expected result is Small.
            new Opportunity(
                Name = 'Small Opportunity',
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(10),
                Amount = 49999
            ),

            // Amount is exactly 50,000, so expected result is Medium.
            new Opportunity(
                Name = 'Medium Lower Boundary',
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(10),
                Amount = 50000
            ),

            // Amount is exactly 200,000, so expected result is Medium.
            new Opportunity(
                Name = 'Medium Upper Boundary',
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(10),
                Amount = 200000
            ),

            // Amount is above 200,000, so expected result is Large.
            new Opportunity(
                Name = 'Large Opportunity',
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(10),
                Amount = 200001
            ),

            // Amount is not provided, so expected result is blank.
            new Opportunity(
                Name = 'Blank Amount Opportunity',
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(10)
            )
        };

        // STEP 2: Start the test execution section.
        // Salesforce resets governor limit tracking for this section.
        Test.startTest();

        // Insert all five Opportunities in one DML operation.
        // This automatically executes our Opportunity trigger.
        // The trigger calls classifyOpportunities().
        insert opportunities;

        // End the test execution section.
        Test.stopTest();

        // STEP 3: Retrieve the saved Opportunities from Salesforce.
        // We need to check what values the trigger actually saved.
        List<Opportunity> savedRecords = [
            SELECT Amount, Opportunity_Size__c
            FROM Opportunity
            WHERE Id IN :opportunities
        ];

        // STEP 4: Verify the actual results against expected results.

        // First Opportunity: Expected Small.
        System.assertEquals(
            'Small',
            savedRecords[0].Opportunity_Size__c
        );

        // Second Opportunity: Expected Medium.
        System.assertEquals(
            'Medium',
            savedRecords[1].Opportunity_Size__c
        );

        // Third Opportunity: Expected Medium.
        System.assertEquals(
            'Medium',
            savedRecords[2].Opportunity_Size__c
        );

        // Fourth Opportunity: Expected Large.
        System.assertEquals(
            'Large',
            savedRecords[3].Opportunity_Size__c
        );

        // Fifth Opportunity: Expected blank.
        System.assertEquals(
            null,
            savedRecords[4].Opportunity_Size__c
        );
    }


    // TEST 2: Check whether classification changes after Amount update.

    @IsTest
    static void testClassificationOnAmountUpdate() {

        // STEP 1: Create an Opportunity with Amount 30,000.
        // Expected classification: Small.

        Opportunity opp = new Opportunity(
            Name = 'Classification Update Test',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Amount = 30000
        );

        // STEP 2: Insert the Opportunity.
        // The before-insert trigger classifies it as Small.
        insert opp;

        // STEP 3: Change its Amount from 30,000 to 100,000.
        opp.Amount = 100000;

        // Update the existing record.
        // This executes the before-update trigger.
        // The handler should now classify it as Medium.
        update opp;

        // STEP 4: Query the updated Opportunity.
        Opportunity savedRecord = [
            SELECT Amount, Opportunity_Size__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        // STEP 5: Verify that the updated classification is Medium.
        System.assertEquals(
            'Medium',
            savedRecord.Opportunity_Size__c
        );
    }


    // TEST 3: Check bulk processing with 200 Opportunities.

    @IsTest
    static void testBulkClassification200Records() {

        // STEP 1: Create an empty List.
        // We will add 200 Opportunities to this List.
        List<Opportunity> opportunities = new List<Opportunity>();

        // STEP 2: Loop 200 times to create 200 Opportunities.
        for (Integer i = 0; i < 200; i++) {

            // Create one Opportunity in every loop iteration.
            opportunities.add(new Opportunity(
                Name = 'Bulk Opportunity ' + i,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(10),

                // Amount changes in every iteration.
                Amount = i * 1000
            ));
        }

        // STEP 3: Start the test execution section.
        Test.startTest();

        // Insert all 200 Opportunities together.
        // Salesforce executes the trigger for this batch.
        // The handler must classify all 200 records.
        insert opportunities;

        // End the test execution section.
        Test.stopTest();

        // STEP 4: Count how many saved Opportunities have
        // a non-blank Opportunity Size value.
        Integer classifiedCount = [
            SELECT COUNT()
            FROM Opportunity
            WHERE Id IN :opportunities
            AND Opportunity_Size__c != null
        ];

        // STEP 5: Verify that all 200 records were classified.
        System.assertEquals(200, classifiedCount);
    }
}
