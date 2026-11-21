
@IsTest
private class OpportunityCommissionQueueableTest {

    @IsTest
    static void testQueueableCommissionCalculation() {

        // Arrange: Create an Account
        Account acc = new Account(
            Name = 'Queueable Test Account'
        );
        insert acc;

        // Arrange: Create Opportunities
        List<Opportunity> opportunities = new List<Opportunity>{

            new Opportunity(
                Name = 'Queueable Small Won',
                AccountId = acc.Id,
                StageName = 'Closed Won',
                CloseDate = Date.today(),
                Amount = 40000
            ),

            new Opportunity(
                Name = 'Queueable Medium Won',
                AccountId = acc.Id,
                StageName = 'Closed Won',
                CloseDate = Date.today(),
                Amount = 100000
            ),

            new Opportunity(
                Name = 'Queueable Open',
                AccountId = acc.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today(),
                Amount = 100000
            )
        };

        insert opportunities;

        // Collect unique Opportunity IDs
        Set<Id> opportunityIds =
            new Map<Id, Opportunity>(opportunities).keySet();

        Test.startTest();

        // Act: Submit Queueable job
        Id jobId = System.enqueueJob(
            new OpportunityCommissionQueueable(opportunityIds)
        );

        Test.stopTest();

        // Assert: Verify calculated commission
        Map<Id, Opportunity> actualRecords =
            new Map<Id, Opportunity>([
                SELECT Id, Commission_Rate__c,
                       Commission_Amount__c
                FROM Opportunity
                WHERE Id IN :opportunityIds
            ]);

        System.assertNotEquals(null, jobId);

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
            0,
            actualRecords.get(opportunities[2].Id).Commission_Rate__c
        );

        System.assertEquals(
            0,
            actualRecords.get(opportunities[2].Id).Commission_Amount__c
        );
    }
}
