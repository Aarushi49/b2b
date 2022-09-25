@isTest class AB2CLogicProductFindTest {
    @isTest static void testPriceProducts(){
        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        AB2CTestData data = new AB2CTestData();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);
        
        ccrz__E_Product__c prod = data.componentProduct;

        List<Map<String, Object>> productList = new List<Map<String, Object>>{
            new Map<String, Object>{},
            new Map<String, Object>{
                'AB2CIsComponent' => true
            }
        };
        Map<String, Object> inputData = new Map<String, Object>{
            'productList' => productList
        };

        AB2CLogicProductFind logic = new AB2CLogicProductFind();
        Map<String, Object> response = logic.priceProducts(inputData);
        
        // we are testing only for the intended side effect
        // the "is component" product gets removed from the list
        System.assertEquals(1, inputData.size());

    }
    @isTest static void testPassthru(){
        // these methods just pass the 'super' through with debugging
        // we have no logic of our own to assert here

        AB2CLogicProductFind logic = new AB2CLogicProductFind();
        Map<String, Object> inputData = new Map<String, Object>();
        Map<String, Object> performResponse = logic.performProductFind(inputData);
        Map<String, Object> processResponse = logic.processProducts(inputData);
    }
    
}