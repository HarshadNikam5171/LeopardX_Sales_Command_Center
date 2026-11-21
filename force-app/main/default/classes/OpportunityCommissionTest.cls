
@IsTest
private class OpportunityCommissionTest {

    @IsTest
    static void testCommissionRates() {

        List<Opportunity> opportunities = new List<Opportunity>();

        // Test different commission boundaries
        opportunities.add(new Opportunity(
            Name = 'Small Won Deal',
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            Amount = 40000
        ));

        opportunities.add(new Opportunity(
            Name = 'Medium Boundary Deal',
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            Amount = 50000
        ));

        opportunities.add(new Opportunity(
            Name = 'Medium Maximum Deal',
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            Amount = 200000
        ));

        opportunities.add(new Opportunity(
            Name = 'Large Won Deal',
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            Amount = 300000
        ));

        opportunities.add(new Opportunity(
            Name = 'Open Deal',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Amount = 100000
        ));

        Test.startTest();
        insert opportunities;
        Test.stopTest();

        // Query calculated values from Salesforce
        Map<String, Opportunity> results = new Map<String, Opportunity>();

        for (Opportunity opp : [
            SELECT Name, Amount, StageName,
                   Commission_Rate__c, Commission_Amount__c
            FROM Opportunity
            WHERE Id IN :opportunities
        ]) {
            results.put(opp.Name, opp);
        }

        // Verify commission calculations
        System.assertEquals(
            2, results.get('Small Won Deal').Commission_Rate__c
        );
        System.assertEquals(
            800, results.get('Small Won Deal').Commission_Amount__c
        );

        System.assertEquals(
            5, results.get('Medium Boundary Deal').Commission_Rate__c
        );
        System.assertEquals(
            2500, results.get('Medium Boundary Deal').Commission_Amount__c
        );

        System.assertEquals(
            5, results.get('Medium Maximum Deal').Commission_Rate__c
        );
        System.assertEquals(
            10000, results.get('Medium Maximum Deal').Commission_Amount__c
        );

        System.assertEquals(
            7, results.get('Large Won Deal').Commission_Rate__c
        );
        System.assertEquals(
            21000, results.get('Large Won Deal').Commission_Amount__c
        );

        System.assertEquals(
            0, results.get('Open Deal').Commission_Rate__c
        );
        System.assertEquals(
            0, results.get('Open Deal').Commission_Amount__c
        );
    }

    @IsTest
    static void testCommissionRecalculationOnUpdate() {

        Opportunity opp = new Opportunity(
            Name = 'Commission Update Test',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Amount = 100000
        );

        insert opp;

        Test.startTest();

        // Change stage to Closed Won
        opp.StageName = 'Closed Won';
        update opp;

        // Change Amount
        opp.Amount = 300000;
        update opp;

        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT Commission_Rate__c, Commission_Amount__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertEquals(7, updatedOpp.Commission_Rate__c);
        System.assertEquals(21000, updatedOpp.Commission_Amount__c);
    }

    @IsTest
    static void testBulkCommissionCalculation() {

        List<Opportunity> opportunities = new List<Opportunity>();

        for (Integer i = 0; i < 200; i++) {
            opportunities.add(new Opportunity(
                Name = 'Bulk Commission ' + i,
                StageName = 'Closed Won',
                CloseDate = Date.today(),
                Amount = 100000
            ));
        }

        Test.startTest();
        insert opportunities;
        Test.stopTest();

        Integer calculatedCount = [
            SELECT COUNT()
            FROM Opportunity
            WHERE Id IN :opportunities
            AND Commission_Rate__c = 5
            AND Commission_Amount__c = 5000
        ];

        System.assertEquals(
            200,
            calculatedCount,
            'All 200 Opportunities should have correct commission values.'
        );
    }
}
