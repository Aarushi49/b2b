@isTest class AB2CLogicCartAddToTest {
    @isTest static void testProcessInputData() {
        AB2CLogicCartAddTo logicService = new AB2CLogicCartAddTo();

        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        AB2CTestData data = new AB2CTestData();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);

        Map<String, Object> line = new Map<String, Object>{
            'sku' => 'TEST-SAMPLE'
        };
        List<Object> lineDataList = new List<Object>{
            line
        };
        Map<String, Object> lineData = new Map<String, Object>{
            ccrz.ccApiCart.LINE_DATA => lineDataList,
            ccrz.ccApiCart.CART_ENCID => data.carts[0].ccrz__EncryptedId__c
        };

        data.prod1.ccrz__SKU__c = 'TEST-SAMPLE';
        update data.prod1;
        data.cartItems[2].ccrz__Product__c = data.prod1.Id;
        data.cartItems[2].ccrz__Product__r = null;
        update data.cartItems[2];

        Map<String,Object> response = logicService.processInputData(lineData);

        List<Object> lineDataAfterProcessing = (List<Object>)response.get(ccrz.ccApiCart.LINE_DATA);

        system.assert(lineDataAfterProcessing.size() == 0, 'Sample item line data should have been removed');
    }
}