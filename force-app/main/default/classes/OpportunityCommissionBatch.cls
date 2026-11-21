
public class OpportunityCommissionBatch
    implements Database.Batchable<sObject> {

    private Set<Id> opportunityIds;

    // Default constructor: process all Opportunities
    public OpportunityCommissionBatch() {
        this.opportunityIds = null;
    }

    // Constructor: process selected Opportunities
    public OpportunityCommissionBatch(Set<Id> opportunityIds) {
        this.opportunityIds = opportunityIds;
    }

    // Step 1: Select Opportunities
    public Database.QueryLocator start(
        Database.BatchableContext bc
    ) {
        if (opportunityIds == null) {
            return Database.getQueryLocator([
                SELECT Id, Amount, StageName,
                       Commission_Rate__c,
                       Commission_Amount__c
                FROM Opportunity
            ]);
        }

        return Database.getQueryLocator([
            SELECT Id, Amount, StageName,
                   Commission_Rate__c,
                   Commission_Amount__c
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ]);
    }

    // Step 2: Process each batch scope
    public void execute(
        Database.BatchableContext bc,
        List<sObject> scope
    ) {
        List<Opportunity> opportunities =
            (List<Opportunity>) scope;

        // DML automatically fires OpportunityTrigger.
        // The trigger calculates commission.
        update opportunities;
    }

    // Step 3: Finish
    public void finish(Database.BatchableContext bc) {
        System.debug(
            'Opportunity Commission Batch completed successfully.'
        );
    }
}
