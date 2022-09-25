@isTest class AB2CCategoryLandingControllerTest {
    @isTest static void testGetCategoryLandingDetails(){
        AB2CCategoryLandingController ctlr = new AB2CCategoryLandingController();

        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        AB2CTestData data = new AB2CTestData();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);
        // override store in Promotion Service for unit test
        AB2CPromotionService.storeName = 'DefaultStore';

        // https://cloudcraze.atlassian.net/wiki/spaces/B2BDOCS411/pages/978784882/Global+Test+Data
        // see global test data definition here
        ccrz__E_Category__c testCategory100 = data.categories[2];
        ccrz__E_Category__c testCategory110 = data.categories[8];
        // 100 is parent of 110

        ccrz.cc_RemoteActionResult response = AB2CCategoryLandingController.getCategoryLandingDetails(context, testCategory100.ccrz__SEOId__c);
        Map<String, Object> rdata = (Map<String, Object>)response.data;
        
        String categoryName = (String)rdata.get('categoryName');
        System.assertEquals(testCategory100.Name, categoryName);
        
        AB2CCategoryLandingController.mockException = new DmlException('whoops');
        response = AB2CCategoryLandingController.getCategoryLandingDetails(context, 'anything');
        System.assert(response.data instanceof Exception);        

    }
}