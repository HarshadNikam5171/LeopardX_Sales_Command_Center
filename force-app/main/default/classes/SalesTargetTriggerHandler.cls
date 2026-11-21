
public class SalesTargetTriggerHandler {

    // BEFORE INSERT
    public static void handleBeforeInsert(
        List<Sales_Target__c> newRecords
    ) {
        for (Sales_Target__c target : newRecords) {

            if (target.Target_Employee__c != null &&
                target.Target_Month__c != null) {

                target.Employee_Month_Key__c =
                    generateEmployeeMonthKey(target);
            }
        }
    }

    // BEFORE UPDATE
    public static void handleBeforeUpdate(
        List<Sales_Target__c> newRecords,
        Map<Id, Sales_Target__c> oldMap
    ) {
        for (Sales_Target__c target : newRecords) {

            Sales_Target__c oldTarget = oldMap.get(target.Id);

            Boolean employeeChanged =
                oldTarget.Target_Employee__c != target.Target_Employee__c;

            Boolean monthChanged =
                oldTarget.Target_Month__c != target.Target_Month__c;

            if (target.Target_Employee__c != null &&
                target.Target_Month__c != null) {

                String expectedKey = generateEmployeeMonthKey(target);

                if (employeeChanged ||
                    monthChanged ||
                    target.Employee_Month_Key__c != expectedKey) {

                    target.Employee_Month_Key__c = expectedKey;
                }
            }
        }
    }

    // REUSABLE KEY GENERATION METHOD
    private static String generateEmployeeMonthKey(
        Sales_Target__c target
    ) {
        String employeeId =
            String.valueOf(target.Target_Employee__c);

        String targetMonth =
            String.valueOf(target.Target_Month__c.year()) + '-' +
            String.valueOf(target.Target_Month__c.month()).leftPad(2, '0');

        return employeeId + '-' + targetMonth;
    }
}
