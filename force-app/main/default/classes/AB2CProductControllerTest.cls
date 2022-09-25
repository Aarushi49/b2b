@isTest public class AB2CProductControllerTest {

    @isTest static void testGetProductDetailBySku(){
        AB2CProductController ctlr = new AB2CProductController();

        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        AB2CTestData data = new AB2CTestData();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);
        
        ccrz__E_Product__c prod = data.prod1;

        ccrz.cc_RemoteActionResult rar = AB2CProductController.getProductDetailBySku(
            context, prod.ccrz__SKU__c
        );

        System.Assert(rar.success == true, 'Success should return true');
        List<Map<String, Object>> productList = (List<Map<String, Object>>)rar.data;
        Map<String, Object> oneProduct = productList[0];
        System.assertEquals(data.priceListItems[0].ccrz__Price__c, (Decimal)oneProduct.get('price'));

        rar = AB2CProductController.getProductDetailBySkuSizeColour(
            context, prod.ccrz__SKU__c, 'green', 'huge'
        );                

        System.assert(rar.success == true, 'Success should return true');
        productList = (List<Map<String, Object>>)rar.data;
        oneProduct = productList[0];
        System.assertEquals(data.priceListItems[0].ccrz__Price__c, (Decimal)oneProduct.get('price'));

        AB2CProductController.mockException = new DmlException('whoops');
        rar = AB2CProductController.getProductDetailBySku(
            context, prod.ccrz__SKU__c
        );
        System.assert(!rar.success);
    }

    @isTest static void testGetProducts(){
        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        AB2CTestData data = new AB2CTestData();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);
        
        ccrz__E_Product__c prod = data.prod1;

        ccrz.cc_RemoteActionResult rar = AB2CProductController.getProducts(
            context, new List<String>{prod.Id}
        );

        System.assert(rar.success == true, 'Success should return true');
        List<Map<String, Object>> productList = (List<Map<String, Object>>)rar.data;
        Map<String, Object> oneProduct = productList[0];
        System.assertEquals(data.priceListItems[0].ccrz__Price__c, (Decimal)oneProduct.get('price'));     
        
        AB2CProductController.mockException = new DmlException('whoops');
        rar = AB2CProductController.getProducts(
            context, new List<String>{prod.Id}
        );
        System.assert(!rar.success);
    }

    @isTest static void testGetProductPromosByCategory(){
        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        AB2CTestData data = new AB2CTestData();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);
        // override store in Promotion Service for unit test
        AB2CPromotionService.storeName = 'DefaultStore';

        ccrz__E_Category__c category = data.categories[0];
        ccrz.cc_RemoteActionResult res = AB2CProductController.getProductPromosByCategory(context, category.Id);

        System.assert(res.success == true, 'Success should return true');
        Map<String, Object> response = (Map<String, Object>) res.data;    
        ccrz__E_Promo__c[] promos = (ccrz__E_Promo__c[]) response.get('promos');
        System.assertEquals(category.Id, promos[0].ccrz__Category__c);

    }
}