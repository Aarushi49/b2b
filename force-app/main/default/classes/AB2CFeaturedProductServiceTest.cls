@isTest class AB2CFeaturedProductServiceTest {
    @isTest static void testGetFeaturedProductsForCategory(){
        AB2CFeaturedProductService service = new AB2CFeaturedProductService();

        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        AB2CTestData data = new AB2CTestData();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);
        
        ccrz__E_Product__c prod = data.prod1;
        ccrz__E_Category__c cat = data.categories[0];

        ccrz__E_FeaturedProduct__c fp = new ccrz__E_FeaturedProduct__c(
            Category__c = cat.Id,
            ccrz__Enabled__c = TRUE,
            ccrz__Storefront__c = context.storefront,
            ccrz__Product__c = prod.Id
        );
        insert fp;

        AB2CFeaturedProductService.storeName = context.storefront;

        ccrz.cc_RemoteActionResult response = AB2CFeaturedProductService.getFeaturedProductsForCategory(context, cat.Id);
        System.assert(response.success);
        List<Map<String,Object>> pData = (List<Map<String,Object>>)response.data;
        Id pid = (Id) pData[0].get('sfid');
        System.assertEquals(prod.Id, pid);

        // now try the exception path
        AB2CFeaturedProductService.mockException = new DmlException('whoops');
        response = AB2CFeaturedProductService.getFeaturedProductsForCategory(context, cat.Id);
        System.assert(!response.success);

    }
}