@isTest public class AB2CAutocompleteServiceTest {
    @isTest public static void testGetAutocompleteResultsFor() {
        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        AB2CTestData data = new AB2CTestData();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);

        ccrz__E_ProductIndex__c pindex1 = new ccrz__E_ProductIndex__c(
            ccrz__Active__c = true, ccrz__IndexCurrency__c = 'USD',
            ccrz__IndexPrice__c = '1', ccrz__IndexType__c = 'U0VBUkNI',
            ccrz__Product__r = data.prod1,
            ccrz__Storefront__c = 'AlexanianStore',
            ccrz__ProductName__c = 'AUTOCOMPLETETEST',
            ccrz__ProductStartDate__c = Date.today() - 1, ccrz__ProductStatus__c = 'Released',
            ccrz__ProductEndDate__c = Date.today().addYears(10),
            ccrz__SKU__c = 'AUTOCOMPLETETEST', ccrz__LastIndex__c = true
        );
        insert pindex1;

        ccrz__E_ProductIndex__c pindex2 = new ccrz__E_ProductIndex__c(
            ccrz__Active__c = true, ccrz__IndexCurrency__c = 'USD',
            ccrz__IndexPrice__c = '1', ccrz__IndexType__c = 'U0VBUkNI',
            ccrz__Product__r = data.prod1,
            ccrz__Storefront__c = 'AlexanianStore',
            ccrz__ProductName__c = 'FAILTEST',
            ccrz__ProductStartDate__c = Date.today() - 1, ccrz__ProductStatus__c = 'Released',
            ccrz__ProductEndDate__c = Date.today().addYears(10),
            ccrz__SKU__c = 'AUTOCOMPLETETEST-2x5', ccrz__LastIndex__c = true
        );
        insert pindex2;

        ccrz.cc_RemoteActionResult results = AB2CAutocompleteService.getAutocompleteResultsFor(context, 'AUTO');

        Set<String> autoList = (Set<String>)results.data;
        system.assert(autoList.size() == 1);
    }
}