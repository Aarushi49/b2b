global with sharing class AB2CServiceSeller extends ccrz.ccServiceSeller {
    @TestVisible private final String newFields = ',AB2C_Country_Code__c,AB2C_Province_Code__c,AB2C_City__c, AB2C_Province__c, AB2C_Country__c, AB2C_Postal_Code__c, AB2C_Phone__c, AB2C_Hours__c, AB2C_Address__c';
    global virtual override Map<String,Object> getFieldsMap(Map<String,Object> inputData) {
        Map<String,Object> retData = super.getFieldsMap(inputData);
        retData.put(ccrz.ccService.OBJECTFIELDS, retData.get(ccrz.ccService.OBJECTFIELDS) + newFields);
        debug('getFieldsMap', inputData, retData);
        return retData;
    }

    private void debug(String functionName, Map<String,Object> inputMap, Map<String,Object> outputMap) {
        System.debug('AB2CServiceSeller:' + functionName + ':input' + JSON.serialize(inputMap));
        System.debug('AB2CServiceSeller:' + functionName + ':output'+ JSON.serialize(outputMap));
    }
}