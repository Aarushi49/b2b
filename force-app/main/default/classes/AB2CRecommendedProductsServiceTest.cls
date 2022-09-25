@isTest class AB2CRecommendedProductsServiceTest {
    @isTest static void testGetRecommendedProductsForCart() {
        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        AB2CTestData data = new AB2CTestData();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);

        String prodID = [
            SELECT ccrz__Product__c 
            FROM ccrz__E_CartItem__c
            WHERE Id =: data.cartItems[2].Id
        ].ccrz__Product__c;

        data.cartItems[2].ccrz__Product__c = data.prod1.Id;
        data.cartItems[2].ccrz__Product__r = null;
        update data.cartItems[2];

        ccrz__E_RelatedProduct__c recommendedProduct = new ccrz__E_RelatedProduct__c(
            ccrz__Enabled__c = TRUE,
            ccrz__StartDate__c = Date.today().addDays(-1),
            ccrz__RelatedProductType__c = AB2CRecommendedProductsService.RELATIONSHIP_TYPE,
            ccrz__Product__c = data.cartItems[2].ccrz__Product__c,
            ccrz__RelatedProduct__c = data.prod1.Id
        );

        insert recommendedProduct;

        ccrz.cc_RemoteActionResult response = AB2CRecommendedProductsService.getRecommendedProductsForCart(context, data.carts[0].ccrz__EncryptedId__c);

        //system.assert(response.data != false, 'Related product should be in response');
        system.assert(response.success, 'Success should be true');
        
    }
}