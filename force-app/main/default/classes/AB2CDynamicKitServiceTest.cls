@isTest class AB2CDynamicKitServiceTest {
    @isTest static void testGetPriceForConfig(){
        AB2CDynamicKitService service = new AB2CDynamicKitService();

        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        AB2CTestData data = new AB2CTestData();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);

        ccrz__E_Product__c prod = data.prod1;
        ccrz__E_PriceListItem__c price = data.priceListItems[0];
        
        ccrz.cc_RemoteActionResult res = AB2CDynamicKitService.getPriceForConfig(
            context, prod.ccrz__SKU__c, 'RECT', 10, 50, new String[]{}
        );
        // for a rectangle we expect: 10 * 50 / 144 * price
        assertEqualEnough(price.ccrz__Price__c * 10*50/144, (Decimal)res.data);

        // simulate error to catch
        AB2CDynamicKitService.mockException = new DmlException('whoops');
        res = AB2CDynamicKitService.getPriceForConfig(
            context, prod.ccrz__SKU__c, 'RECT', 10, 50, new String[]{}
        );
        System.assert(!res.success);
    }

    @isTest static void testDynamicKitSelections(){
        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        AB2CTestData data = new AB2CTestData();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);

        ccrz__E_Product__c prod = data.products[0];
        ccrz__E_PriceListItem__c price = data.priceListItems[0];

        AB2CDynamicKitService.DynamicKitSelections dks = new AB2CDynamicKitService.DynamicKitSelections(prod.ccrz__SKU__c, 'RECT-0025x0030-SKU1-SKU2-SKU3', context);
        System.assertEquals(dks.SHAPE_RECTANGLE, dks.shape);
        System.assertEquals(25, dks.lenIn);
        System.assertEquals(30, dks.widIn);
        System.assertEquals(3, dks.compSKUs.size());

        Decimal sqft = dks.getSqrFt();
        // for a rectangle we expect: 25 * 30 / 144
        assertEqualEnough(25.0*30/144, sqft);

        dks.shape = dks.SHAPE_SQUARE;
        sqft = dks.getSqrFt();
        // for a square we expect: 25 * 25 / 144
        assertEqualEnough(25.0*25/144, sqft);

        dks.shape = dks.SHAPE_CIRCLE;
        sqft = dks.getSqrFt();
        // for a circle we expect: πr²/144 where r = 25/2
        assertEqualEnough(Math.PI * 12.5 * 12.5 / 144, sqft);

        dks.shape = 'whoops';
        sqft = dks.getSqrFt();
        System.assertEquals(0, sqft);
    }

    @isTest static void testCalcPrice(){
        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        AB2CTestData data = new AB2CTestData();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);

        ccrz__E_Product__c prod = data.prod1;
        ccrz__E_PriceListItem__c price = data.priceListItems[0];
        
        AB2CDynamicKitService.DynamicKitSelections dks = new AB2CDynamicKitService.DynamicKitSelections(prod.ccrz__SKU__c, 'RECT', 10, 50, new String[]{prod.ccrz__SKU__c}, context);
        // for a rectangle we expect: (10 * 50 / 144 * price) + price again b/c composite
        Decimal calcResult = dks.calcPrice();
        assertEqualEnough(price.ccrz__Price__c *(1.0 + 10.0*50/144), calcResult);        
    }

    @isTest static void testSetDynamicKitPricingOnCart(){
        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        AB2CTestData data = new AB2CTestData();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);

        ccrz__E_Product__c prod = data.products[0];
        ccrz__E_PriceListItem__c price = data.priceListItems[0];
        ccrz__E_Cart__c cart = data.carts[0];
        ccrz__E_CartItem__c cartItem = data.cartItems[1];
        ccrz__E_CartItem__c parentCartItem = data.cartItems[0];
        
        // label = RECT-0025x0030
        ccrz.cc_RemoteActionResult res = AB2CDynamicKitService.setDynamicKitPricingOnCart(
            context, cart.ccrz__EncryptedId__c, parentCartItem.ccrz__ItemLabel__c
        );
        
        System.assert(res.success);
        ccrz__E_CartItem__c newCartItem = [
            SELECT Id, ccrz__Product__c, ccrz__Price__c, ccrz__ItemLabel__c
            FROM ccrz__E_CartItem__c WHERE Id = :cartItem.Id
        ];
        // for a rectangle we expect: 25 * 30 / 144 * price
        assertEqualEnough(price.ccrz__Price__c*25*30/144, newCartItem.ccrz__Price__c); 
        
        AB2CDynamicKitService.mockException = new DmlException('whoops');
        res = AB2CDynamicKitService.setDynamicKitPricingOnCart(
            context, cart.ccrz__EncryptedId__c, cartItem.ccrz__ItemLabel__c
        );
        System.assert(!res.success);
        
    }

    private static Boolean equalEnough(Decimal expected, Decimal actual){
        return (expected != null && actual != null && Math.abs(expected-actual)<0.01);
    }
    private static void assertEqualEnough(Decimal expected, Decimal actual){
        System.assert(equalEnough(expected, actual), 'Should be: ' + expected + ', got: ' + actual);
    }
}