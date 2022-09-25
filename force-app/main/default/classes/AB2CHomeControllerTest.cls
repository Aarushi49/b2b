@isTest class AB2CHomeControllerTest {
    @isTest static void testGetHomeDetails(){
        AB2CHomeController ctlr = new AB2CHomeController();

        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        AB2CTestData data = new AB2CTestData();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);
        // override store in Promotion Service for unit test
        AB2CPromotionService.storeName = 'DefaultStore';

        ccrz.cc_RemoteActionResult response = AB2CHomeController.getHomeDetails(context);
        System.assert(response.success);
        Map<String, Object> rData = (Map<String, Object>)response.data;
        ccrz__E_Promo__c[] promos = (ccrz__E_Promo__c[])rData.get('promotions');
        System.assertEquals(data.promos[1].Id, promos[0].Id);

        AB2CHomeController.mockException = new DmlException('whoops');
        response = AB2CHomeController.getHomeDetails(context);
        System.assert(!response.success);
        
    }
}