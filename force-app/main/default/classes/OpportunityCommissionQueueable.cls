
public with sharing class OpportunityCommissionQueueable
    implements Queueable {

    private Set<Id> opportunityIds;

    // Constructor receives selected Opportunity IDs
    public OpportunityCommissionQueueable(Set<Id> opportunityIds) {
        this.opportunityIds = opportunityIds;
    }

    // Queueable execution starts here
    public void execute(QueueableContext context) {

        // Stop if no IDs were provided
        if (opportunityIds == null || opportunityIds.isEmpty()) {
            return;
        }

        // Query selected Opportunities
        List<Opportunity> opportunities = [
            SELECT Id, Amount, StageName,
                   Commission_Rate__c,
                   Commission_Amount__c
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ];

        if (opportunities.isEmpty()) {
            return;
        }

        // OpportunityTrigger automatically recalculates commission.
        update opportunities;
    }
}
