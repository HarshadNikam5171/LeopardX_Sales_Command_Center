public class OpportunityTriggerHandler {
    public static Set<Id> collectAccountIds(
    List<Opportunity> newRecords,
    List<Opportunity> oldRecords
 ) {
    Set<Id> accountIds = new Set<Id>();

    if (newRecords != null) {
        for (Opportunity opp : newRecords) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }
    }

    if (oldRecords != null) {
        for (Opportunity opp : oldRecords) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }
    }

    return accountIds;
 }

    public static List<AggregateResult> getWonOpportunitySummaries(
    Set<Id> accountIds
 ) {
    if (accountIds == null || accountIds.isEmpty()) {
        return new List<AggregateResult>();
    }

    List<AggregateResult> results = [
        SELECT
            AccountId accountId,
            SUM(Amount) totalRevenue,
            COUNT(Id) wonCount,
            MAX(CloseDate) lastWonDate
        FROM Opportunity
        WHERE IsWon = true
        AND AccountId IN :accountIds
        GROUP BY AccountId
    ];

    return results;
    }
    public static Map<Id, AggregateResult> buildSummaryMap(
    List<AggregateResult> results
    ) {
    Map<Id, AggregateResult> summaryMap =
        new Map<Id, AggregateResult>();

    for (AggregateResult result : results) {

        Id accountId = (Id) result.get('accountId');

        summaryMap.put(accountId, result);
    }

    return summaryMap;
    }
    public static void updateAccountSummaries(Set<Id> accountIds) {

    if (accountIds == null || accountIds.isEmpty()) {
        return;
    }

    // Step 1: Get aggregate query results
    List<AggregateResult> results =
        getWonOpportunitySummaries(accountIds);

    // Step 2: Convert results into a Map
    Map<Id, AggregateResult> summaryMap =
        buildSummaryMap(results);

    // Step 3: Prepare Account records
    List<Account> accountsToUpdate = new List<Account>();

    for (Id accountId : accountIds) {

        // Default values for Accounts without Closed Won Opportunities
        Decimal revenue = 0;
        Integer wonCount = 0;
        Date lastWonDate = null;

        // Check whether aggregate data exists
        if (summaryMap.containsKey(accountId)) {

            AggregateResult result = summaryMap.get(accountId);

            revenue = (Decimal) result.get('totalRevenue');
            wonCount = (Integer) result.get('wonCount');
            lastWonDate = (Date) result.get('lastWonDate');

            if (revenue == null) {
                revenue = 0;
            }
        }

        // Prepare Account record
        accountsToUpdate.add(new Account(
            Id = accountId,
            Total_Won_Revenue__c = revenue,
            Won_Opportunity_Count__c = wonCount,
            Last_Won_Date__c = lastWonDate
        ));
    }

    // Step 4: Update all Accounts in one DML operation
    if (!accountsToUpdate.isEmpty()) {
        update accountsToUpdate;
    }
 }

        // FEATURE 3: Classify Opportunities based on Amount
    public static void classifyOpportunities(
        List<Opportunity> opportunities
    ) {
        for (Opportunity opp : opportunities) {

            if (opp.Amount == null) {
                opp.Opportunity_Size__c = null;
            }
            else if (opp.Amount < 50000) {
                opp.Opportunity_Size__c = 'Small';
            }
            else if (opp.Amount <= 200000) {
                opp.Opportunity_Size__c = 'Medium';
            }
            else {
                opp.Opportunity_Size__c = 'Large';
            }
        }
    }


    // FEATURE 4: Calculate Opportunity Sales Commission
    public static void calculateOpportunityCommission(
        List<Opportunity> opportunities
    ) {
        for (Opportunity opp : opportunities) {

            // Commission is applicable only to Closed Won Opportunities
            if (opp.StageName != 'Closed Won' || opp.Amount == null) {
                opp.Commission_Rate__c = 0;
                opp.Commission_Amount__c = 0;
                continue;
            }

            // Determine commission rate based on Opportunity Amount
            if (opp.Amount < 50000) {
                opp.Commission_Rate__c = 2;
            }
            else if (opp.Amount <= 200000) {
                opp.Commission_Rate__c = 5;
            }
            else {
                opp.Commission_Rate__c = 7;
            }

            // Calculate commission amount
            opp.Commission_Amount__c =
                (opp.Amount * opp.Commission_Rate__c) / 100;
        }
    }

}