
@isTest
private class OpportunityTriggerHandlerTest {

    // Helper: Create an Account
    private static Account createAccount(String accountName) {
        Account acc = new Account(
            Name = accountName
        );
        insert acc;
        return acc;
    }

    // Helper: Create an Opportunity
    private static Opportunity createOpportunity(
        Id accountId,
        String opportunityName,
        String stage,
        Decimal amount,
        Date closeDate
    ) {
        return new Opportunity(
            AccountId = accountId,
            Name = opportunityName,
            StageName = stage,
            Amount = amount,
            CloseDate = closeDate
        );
    }

    // TEST 1: Calculate summary after multiple Opportunity inserts
    @isTest
    static void testSummaryOnInsert() {

        Account acc = createAccount('Test Account Insert');

        List<Opportunity> opportunities = new List<Opportunity>{
            createOpportunity(
                acc.Id, 'Won Deal 1', 'Closed Won',
                100, Date.newInstance(2026, 11, 10)
            ),
            createOpportunity(
                acc.Id, 'Won Deal 2', 'Closed Won',
                250, Date.newInstance(2026, 11, 15)
            ),
            createOpportunity(
                acc.Id, 'Open Deal', 'Prospecting',
                500, Date.newInstance(2026, 11, 20)
            )
        };

        Test.startTest();
        insert opportunities;
        Test.stopTest();

        Account updatedAccount = [
            SELECT Total_Won_Revenue__c,
                   Won_Opportunity_Count__c,
                   Last_Won_Date__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertEquals(
            Decimal.valueOf('350'),
            updatedAccount.Total_Won_Revenue__c
        );

        System.assertEquals(
    Decimal.valueOf('2'),
    updatedAccount.Won_Opportunity_Count__c
);

        System.assertEquals(
            Date.newInstance(2026, 11, 15),
            updatedAccount.Last_Won_Date__c
        );
    }

    // TEST 2: Update Amount and reassign Opportunity to another Account
    @isTest
    static void testAmountUpdateAndAccountReassignment() {

        Account accountA = createAccount('Account A');
        Account accountB = createAccount('Account B');

        Opportunity opp = createOpportunity(
            accountA.Id,
            'Reassignment Deal',
            'Closed Won',
            100,
            Date.newInstance(2026, 11, 12)
        );
        insert opp;

        opp.Amount = 200;
        opp.AccountId = accountB.Id;

        Test.startTest();
        update opp;
        Test.stopTest();

        Set<Id> accountIds = new Set<Id>{
    accountA.Id,
    accountB.Id
};

Map<Id, Account> accounts = new Map<Id, Account>([
    SELECT Total_Won_Revenue__c,
           Won_Opportunity_Count__c,
           Last_Won_Date__c
    FROM Account
    WHERE Id IN :accountIds
]);

        System.assertEquals(
            Decimal.valueOf('0'),
            accounts.get(accountA.Id).Total_Won_Revenue__c
        );

        System.assertEquals(
            0,
            accounts.get(accountA.Id).Won_Opportunity_Count__c
        );

        System.assertEquals(
            null,
            accounts.get(accountA.Id).Last_Won_Date__c
        );

        System.assertEquals(
            Decimal.valueOf('200'),
            accounts.get(accountB.Id).Total_Won_Revenue__c
        );

        System.assertEquals(
            1,
            accounts.get(accountB.Id).Won_Opportunity_Count__c
        );
    }

    // TEST 3: Recalculate summary after Opportunity deletion
    @isTest
    static void testSummaryAfterDelete() {

        Account acc = createAccount('Test Account Delete');

        Opportunity opp = createOpportunity(
            acc.Id,
            'Delete Deal',
            'Closed Won',
            500,
            Date.newInstance(2026, 11, 14)
        );
        insert opp;

        Test.startTest();
        delete opp;
        Test.stopTest();

        Account updatedAccount = [
            SELECT Total_Won_Revenue__c,
                   Won_Opportunity_Count__c,
                   Last_Won_Date__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertEquals(
            Decimal.valueOf('0'),
            updatedAccount.Total_Won_Revenue__c
        );

        System.assertEquals(
    Decimal.valueOf('0'),
    updatedAccount.Won_Opportunity_Count__c
);

        System.assertEquals(
            null,
            updatedAccount.Last_Won_Date__c
        );
    }

    // TEST 4: Recalculate summary after Opportunity undelete
    @isTest
    static void testSummaryAfterUndelete() {

        Account acc = createAccount('Test Account Undelete');

        Opportunity opp = createOpportunity(
            acc.Id,
            'Restore Deal',
            'Closed Won',
            750,
            Date.newInstance(2026, 11, 16)
        );
        insert opp;

        delete opp;

        Test.startTest();
        undelete opp;
        Test.stopTest();

        Account updatedAccount = [
            SELECT Total_Won_Revenue__c,
                   Won_Opportunity_Count__c,
                   Last_Won_Date__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertEquals(
            Decimal.valueOf('750'),
            updatedAccount.Total_Won_Revenue__c
        );

        System.assertEquals(
    Decimal.valueOf('1'),
    updatedAccount.Won_Opportunity_Count__c
);

        System.assertEquals(
            Date.newInstance(2026, 11, 16),
            updatedAccount.Last_Won_Date__c
        );
    }

    // TEST 5: Prevent reopening a Closed Won Opportunity
    @isTest
    static void testClosedWonCannotBeReopened() {

        Account acc = createAccount('Test Account Protection');

        Opportunity opp = createOpportunity(
            acc.Id,
            'Protected Deal',
            'Closed Won',
            1000,
            Date.newInstance(2026, 11, 18)
        );
        insert opp;

        opp.StageName = 'Prospecting';

        Test.startTest();

        Boolean exceptionThrown = false;

        try {
            update opp;
        } catch (DmlException ex) {
            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(
            true,
            exceptionThrown,
            'A Closed Won Opportunity must not be reopened.'
        );
    }


    // TEST 6: Handle null and empty Account ID sets
    @isTest
    static void testEmptyAccountIds() {

        Test.startTest();

        List<AggregateResult> nullResults =
            OpportunityTriggerHandler.getWonOpportunitySummaries(null);

        List<AggregateResult> emptyResults =
            OpportunityTriggerHandler.getWonOpportunitySummaries(
                new Set<Id>()
            );

        Test.stopTest();

        System.assertEquals(
            0,
            nullResults.size(),
            'Null Account IDs should return an empty result.'
        );

        System.assertEquals(
            0,
            emptyResults.size(),
            'Empty Account IDs should return an empty result.'
        );
    }

    // TEST 7: Handle Closed Won Opportunity with null Amount
    @isTest
    static void testNullAmountWonOpportunitySummary() {

        Account acc = createAccount('Null Amount Test Account');

        Opportunity opp = createOpportunity(
            acc.Id,
            'Null Amount Won Deal',
            'Closed Won',
            null,
            Date.today()
        );

        Test.startTest();
        insert opp;
        Test.stopTest();

        Account updatedAccount = [
            SELECT Total_Won_Revenue__c,
                   Won_Opportunity_Count__c,
                   Last_Won_Date__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertEquals(
            Decimal.valueOf('0'),
            updatedAccount.Total_Won_Revenue__c,
            'Null revenue should be stored as zero.'
        );

        System.assertEquals(
            Decimal.valueOf('1'),
            updatedAccount.Won_Opportunity_Count__c,
            'The Closed Won Opportunity should still be counted.'
        );

        System.assertEquals(
            Date.today(),
            updatedAccount.Last_Won_Date__c
        );
    }

    // TEST 8: Handle null and empty Account IDs during summary update
    @isTest
    static void testUpdateAccountSummariesWithEmptyIds() {

    Test.startTest();

    OpportunityTriggerHandler.updateAccountSummaries(null);
    OpportunityTriggerHandler.updateAccountSummaries(new Set<Id>());

    Test.stopTest();

    System.assert(true, 'Empty Account ID sets should return safely.');
    }

}
