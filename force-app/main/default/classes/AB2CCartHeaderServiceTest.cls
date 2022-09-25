@isTest public with sharing class AB2CCartHeaderServiceTest {
    @isTest static void testGetCartNum() {
        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        AB2CTestData data = new AB2CTestData();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);

        ccrz.cc_RemoteActionResult response = AB2CCartHeaderService.getCartNum(context, data.carts[0].ccrz__EncryptedId__c);

        // cart data set up with 2 unique products, with one product having quantity of 10.
        // we are expecting to see only the two unique products being reflected in the response.
        AB2CCartHeaderService.cartInfo cartInfo =  (AB2CCartHeaderService.cartInfo)response.data;
        System.assert(response != null);
        System.assertEquals(cartInfo.cartSize, 2);
    }
}