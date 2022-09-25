global virtual class AB2CCommonController {
    public static String getConfigValue(String value) {
        List<ccrz__E_Configuration__c> configValues = [SELECT ccrz__TextValue__c FROM ccrz__E_Configuration__c WHERE Name = :value];
        if (configValues.size() > 0) {
            return (String) configValues[0].get('ccrz__TextValue__c');
        }
        return null;
    }
}