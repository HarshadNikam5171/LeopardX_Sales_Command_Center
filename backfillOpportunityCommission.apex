
// FEATURE 4: Backfill commission for existing Opportunities

// Step 1: Retrieve all existing Opportunities
List<Opportunity> opportunities = [
    SELECT Id, StageName, Amount,
           Commission_Rate__c,
           Commission_Amount__c
    FROM Opportunity
];

// Step 2: Calculate commission using our existing handler
OpportunityTriggerHandler.calculateOpportunityCommission(
    opportunities
);

// Step 3: Update all Opportunities in one DML operation
if (!opportunities.isEmpty()) {
    update opportunities;
}

System.debug(
    'Commission backfill completed. Records processed: '
    + opportunities.size()
);
