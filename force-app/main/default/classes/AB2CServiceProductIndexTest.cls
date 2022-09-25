@isTest public with sharing class AB2CServiceProductIndexTest {
    @isTest static void testGetReturnClauseMap() {
        Map<String,Object> inputData = new Map<String, Object> {
            'ProductIndex' => 'ShortDescription__c'
        };

        AB2CServiceProductIndex service = new AB2CServiceProductIndex();

        Map<String, Object> response = service.getReturnClauseMap(inputData);
        String responseProdIndex = (String)response.get('ProductIndex');
    }

}