@isTest class AB2CLogicCartPriceTest {
    @isTest static void testPriceItem() {
        AB2CLogicCartPrice service = new AB2CLogicCartPrice();

        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        AB2CTestData data = new AB2CTestData();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);

        data.prod1.ccrz__SKU__c = 'TEST-SAMPLE';
        update data.prod1;
        data.cartItems[2].ccrz__Product__c = data.prod1.Id;
        data.cartItems[2].ccrz__Product__r = data.prod1;
        update data.cartItems[2];

        Map<String, Object> price = new Map<String, Object> {
            'productPrice' => new Map<String, Object> {
                'price' => 2.0
            }
        };
        Map<String, Object> prodPriceData = new Map<String, Object>{
            data.cartItems[2].ccrz__Product__c => price
        };

        Map<String, Object> inputData = new Map<String, Object>{
            'cartItem' => data.cartItems[2],
            ccrz.ccApiProduct.PRODUCTPRICINGDATA => prodPriceData
        };

        Map<String,Object> response = service.priceItem(inputData);
        
        system.debug(response);

        Map<String, Object> responsePriceData = (Map<String, Object>)response.get('productPricingData');
        Map<String, Object> responseProductPriceData = (Map<String, Object>)responsePriceData.get(data.cartItems[2].ccrz__Product__c);
        Map<String, Object> responseProductPrice = (Map<String, Object>)responseProductPriceData.get('productPrice');

        system.assert((Integer)responseProductPrice.get('price') == 0, 'price should be zero');
    }
}