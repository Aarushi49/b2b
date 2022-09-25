@isTest public class  AB2CCheckoutControllerTest {


    @isTest static void calculateShippingOntarioTest(){

        AB2CTestData data = new AB2CTestData();
        String province = 'Ontario';
        String storeName = 'AlexanianStore';
        String distance = '0.5';
        
        ccrz__E_Cart__c cart = data.carts[0];

        ccrz.cc_RemoteActionResult rar = AB2CCheckoutController.calculateShipping(cart.id,storeName,distance,province);
        System.Assert(rar.success == true, 'Success should return true');

    }

    @isTest static void calculateShippingRestOfCanadaTest(){

        AB2CTestData data = new AB2CTestData();
        String province = 'Quebec';
        String storeName = 'AlexanianStore';
        String distance = '100';
        
        ccrz__E_Cart__c cart = data.carts[0];

        ccrz.cc_RemoteActionResult rar = AB2CCheckoutController.calculateShipping(cart.id,storeName,distance,province);
       

        
        System.Assert(rar.success == true, 'Success should return true');

    }

    @istest static void updateCartImagesTest(){
        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        //global static ccrz.cc_RemoteActionResult updateCartImages(ccrz.cc_RemoteActionContext context, List<Map<String, Object>> cartItemList) {
        AB2CTestData data = new AB2CTestData();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);


        List<Map<String, Object>> cartItemList = new List<Map<String, Object>>{
            new Map<String, Object>{},
            new Map<String, Object>{
                'productImageUrl' => 'productImageUrl'
            },
            new Map<String, Object>{
                'itemId' => 'itemId'
            }
        };
        ccrz.cc_RemoteActionResult response = AB2CCheckoutController.updateCartImages(context,cartItemList);

        System.Assert(response.success == true, 'Success should return true');

        
    }

    
    @istest static void updateProductInventoryTest(){
        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        AB2CTestData data = new AB2CTestData();
        ccrz__E_Cart__c cart = data.carts[0];
        ccrz.cc_RemoteActionResult response = AB2CCheckoutController.updateProductInventory(context,cart.id);
        System.Assert(response.success == true, 'Success should return true');

    }
    
     @istest static void getCartPromosTest(){ 
        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        ccrz.cc_RemoteActionResult response = AB2CCheckoutController.getCartPromos(context);
        System.Assert(response.success == true, 'Success should return true');
    }


}