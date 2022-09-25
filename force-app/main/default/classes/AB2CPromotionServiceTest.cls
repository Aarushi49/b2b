@isTest class AB2CPromotionServiceTest {
    @isTest static void testGetPromotions(){
        AB2CPromotionService service = new AB2CPromotionService();
        
        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        AB2CTestData data = new AB2CTestData();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);
        // override store in Promotion Service for unit test
        AB2CPromotionService.storeName = 'DefaultStore';

        ccrz__E_Category__c category = data.categories[0];

        // cover category ID scenario
        ccrz.cc_RemoteActionResult res = AB2CPromotionService.getPromotions(context, 'productList', category.Id);
        System.assert(res.success == true, 'Success should return true');        
        ccrz__E_Promo__c[] promos = (ccrz__E_Promo__c[])res.data;
        System.assertEquals(category.Id, promos[0].ccrz__Category__c);
        
        // cover no category ID scenario
        res = AB2CPromotionService.getPromotions(context, 'productList', null);
        System.assert(res.success == true, 'Success should return true');        
        promos = (ccrz__E_Promo__c[])res.data;
        System.assertEquals(category.Id, promos[0].ccrz__Category__c);        

        AB2CPromotionService.mockException = new DmlException('whoops');
        res = AB2CPromotionService.getPromotions(context, 'productList', null);
        System.assert(!res.success);

    }
}