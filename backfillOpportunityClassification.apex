// Step 1: Retrieve existing Opportunities
List<Opportunity> existingOpportunities = [
    SELECT Id, Amount, Opportunity_Size__c
    FROM Opportunity
];

// Step 2: Prepare records that need reprocessing
List<Opportunity> opportunitiesToUpdate =
    new List<Opportunity>();

for (Opportunity opp : existingOpportunities) {

    String expectedSize;

    // Determine the expected classification
    if (opp.Amount == null) {
        expectedSize = null;
    }
    else if (opp.Amount < 50000) {
        expectedSize = 'Small';
    }
    else if (opp.Amount <= 200000) {
        expectedSize = 'Medium';
    }
    else {
        expectedSize = 'Large';
    }

    // Update only records with an incorrect classification
    if (opp.Opportunity_Size__c != expectedSize) {
        opportunitiesToUpdate.add(opp);
    }
}

// Step 3: Update records in one DML operation
if (!opportunitiesToUpdate.isEmpty()) {
    update opportunitiesToUpdate;
}

// Step 4: Display execution results
System.debug('Total Opportunities: ' + existingOpportunities.size());
System.debug('Records reprocessed: ' + opportunitiesToUpdate.size());
System.debug('Opportunity classification backfill completed.');