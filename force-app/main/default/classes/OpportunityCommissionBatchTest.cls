
@IsTest
private class OpportunityCommissionBatchTest {

    @IsTest
    static void testCommissionBatchExecution() {

        // Create test Account
        Account acc = new Account(Name = 'Batch Test Account');
        insert acc;

        // Create Opportunities with different commission scenarios
        List<Opportunity> opportunities = new List<Opportunity>();

        opportunities.add(new Opportunity(
            Name = 'Small Won Opportunity',
            AccountId = acc.Id,
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            Amount = 40000
        ));

        opportunities.add(new Opportunity(
            Name = 'Medium Won Opportunity',
            AccountId = acc.Id,
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            Amount = 100000
        ));

        opportunities.add(new Opportunity(
            Name = 'Large Won Opportunity',
            AccountId = acc.Id,
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            Amount = 300000
        ));

        opportunities.add(new Opportunity(
            Name = 'Open Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Amount = 100000
        ));

        insert opportunities;

        

        Test.startTest();

        Set<Id> opportunityIds =
    new Map<Id, Opportunity>(opportunities).keySet();

    Database.executeBatch(
    new OpportunityCommissionBatch(opportunityIds),
    200
    );

        Test.stopTest();

        // Query recalculated records
        Map<Id, Opportunity> actualRecords =
            new Map<Id, Opportunity>([
                SELECT Id, Commission_Rate__c, Commission_Amount__c
                FROM Opportunity
                WHERE Id IN :opportunities
            ]);

        System.assertEquals(
            2,
            actualRecords.get(opportunities[0].Id).Commission_Rate__c
        );
        System.assertEquals(
            800,
            actualRecords.get(opportunities[0].Id).Commission_Amount__c
        );

        System.assertEquals(
            5,
            actualRecords.get(opportunities[1].Id).Commission_Rate__c
        );
        System.assertEquals(
            5000,
            actualRecords.get(opportunities[1].Id).Commission_Amount__c
        );

        System.assertEquals(
            7,
            actualRecords.get(opportunities[2].Id).Commission_Rate__c
        );
        System.assertEquals(
            21000,
            actualRecords.get(opportunities[2].Id).Commission_Amount__c
        );

        System.assertEquals(
            0,
            actualRecords.get(opportunities[3].Id).Commission_Rate__c
        );
        System.assertEquals(
            0,
            actualRecords.get(opportunities[3].Id).Commission_Amount__c
        );
    }


    // TEST 2: Execute Batch using the default constructor
    @IsTest
    static void testBatchDefaultConstructor() {

        Account acc = new Account(
            Name = 'Batch Default Constructor Account'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Default Constructor Won Deal',
            AccountId = acc.Id,
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            Amount = 40000
        );
        insert opp;

        Test.startTest();

        Database.executeBatch(
            new OpportunityCommissionBatch(),
            200
        );

        Test.stopTest();

        Opportunity actual = [
            SELECT Commission_Rate__c,
                   Commission_Amount__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertEquals(2, actual.Commission_Rate__c);
        System.assertEquals(800, actual.Commission_Amount__c);
    }

}
