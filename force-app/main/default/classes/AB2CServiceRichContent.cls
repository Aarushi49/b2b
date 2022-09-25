global with sharing class AB2CServiceRichContent extends ccrz.ccServiceRichContent {
    global virtual override Map<String, Object> getFieldsMap(Map<String, Object> inputData) {
        inputData = super.getFieldsMap(inputData);
        String objectFields = (String)inputData.get(ccrz.ccService.OBJECTFIELDS);
        objectFields += ',PageTitle__c,MenuId__c,AB2C_Meta_Description__c,AB2C_Meta_Title__c';
        return new Map <String,Object> {ccrz.ccService.OBJECTFIELDS => objectFields};
    }
}