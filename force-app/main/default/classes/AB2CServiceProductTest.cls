@isTest class AB2CServiceProductTest {
    @isTest static void testGetFieldsMap(){
        Map<String, Object> productSizing = new Map<String, Object>{
            ccrz.ccAPI.SZ_REL => new List<String>(),
            ccrz.ccAPI.SZ_DATA => ccrz.ccAPI.SZ_M
        };
        
        Map<String, Object> inputData = new Map<String, Object>{
            ccrz.ccAPI.SIZING => new Map<String, Object>{
                ccrz.ccAPIProduct.ENTITYNAME => productSizing
            }
        };

        //String fieldSize = getFieldSize(inputData, ccrz.ccAPIProduct.ENTITYNAME);

        AB2CServiceProduct service = new AB2CServiceProduct();

        Map<String, Object> result = service.getFieldsMap(inputData);
        String fields = (String)result.get(ccrz.ccService.OBJECTFIELDS);
        System.assert(fields.contains('ccrz__ServiceFlag__c'));
        System.assert(fields.contains('AB2C_Is_Component__c'));

        // change sizing setting for different outcome
        productSizing.put(ccrz.ccApi.SZ_DATA, ccrz.ccAPI.SZ_L);
        result = service.getFieldsMap(inputData);
        fields = (String)result.get(ccrz.ccService.OBJECTFIELDS);
        System.assert(fields.contains('AB2C_Show_Square_Footage_Calculator__c'));
        System.assert(fields.contains('AB2C_Is_Component__c'));
        System.assert(fields.contains('AB2C_In_Store_Only__c'));

        // test empty input to getFieldSize
        String s = service.getFieldSize(new Map<String, Object>(), 'foo');
        System.assertEquals('', s);

    }

    @isTest static void testGetSubQueryMap(){
        Map<String, Object> productSizing = new Map<String, Object>{
            ccrz.ccAPI.SZ_REL => new List<String>{'Product_Specs__r', 'CompositeProducts__r'},
            ccrz.ccAPI.SZ_DATA => ccrz.ccAPI.SZ_XL
        };
        
        Map<String, Object> inputData = new Map<String, Object>{
            ccrz.ccAPI.SIZING => new Map<String, Object>{
                ccrz.ccAPIProduct.ENTITYNAME => productSizing
            }
        };
        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        AB2CTestData data = new AB2CTestData();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);        

        AB2CServiceProduct service = new AB2CServiceProduct();
        service.mockSuperSubQueryMap = new Map<String, Object>{
            'Product_Specs__r' => '(SELECT Id, Name FROM Product_Specs__r)',
            'CompositeProducts__r' => '(SELECT Id, Name FROM CompositeProducts__r)'
        };
        Map<String, Object> result = service.getSubQueryMap(inputData);

        System.assert(((String)result.get('Product_Specs__r')).contains('AB2C_Product_Spec_SKU__c'));
        System.assert(((String)result.get('CompositeProducts__r')).contains('AB2C_Component_Requires_Calculator__c'));
        System.assert(((String)result.get('E_RelatedProducts__r')).contains('RelatedProductType__c'));
    }
}