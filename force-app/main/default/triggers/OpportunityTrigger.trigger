
trigger OpportunityTrigger on Opportunity (
    before insert,
    before update,
    after insert,
    after update,
    after delete,
    after undelete
) {

    // FEATURE 3: Classify Opportunities before saving
    // FEATURE 4: Calculate Opportunity Commission
    if (Trigger.isBefore) {

    OpportunityTriggerHandler.classifyOpportunities(
        Trigger.new
    );

    OpportunityTriggerHandler.calculateOpportunityCommission(
        Trigger.new
    );
}

    // EXISTING RULE: Prevent reopening Closed Won Opportunities
    if (Trigger.isBefore && Trigger.isUpdate) {

        for (Opportunity oppRecNew : Trigger.new) {

            Opportunity oppRecOld =
                Trigger.oldMap.get(oppRecNew.Id);

            if (oppRecOld.StageName == 'Closed Won' &&
                oppRecNew.StageName != 'Closed Won') {

                oppRecNew.StageName.addError(
                    'A Closed Won Opportunity cannot be reopened or changed.'
                );
            }
        }
    }

    // FEATURE 2: Recalculate Account sales performance
    if (Trigger.isAfter) {

        List<Opportunity> newRecords =
            Trigger.isDelete ? null : Trigger.new;

        List<Opportunity> oldRecords =
            (Trigger.isInsert || Trigger.isUndelete)
            ? null
            : Trigger.old;

        Set<Id> accountIds =
            OpportunityTriggerHandler.collectAccountIds(
                newRecords,
                oldRecords
            );

        OpportunityTriggerHandler.updateAccountSummaries(
            accountIds
        );
    }
}
