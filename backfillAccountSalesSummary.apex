// Step 1: Retrieve all existing Account IDs
Set<Id> accountIds = new Map<Id, Account>([
    SELECT Id
    FROM Account
]).keySet();

// Step 2: Recalculate Account sales summaries
OpportunityTriggerHandler.updateAccountSummaries(accountIds);

// Step 3: Log execution details
System.debug('====================================');
System.debug('ACCOUNT SALES SUMMARY BACKFILL');
System.debug('====================================');
System.debug('Accounts processed: ' + accountIds.size());
System.debug('Backfill completed successfully.');