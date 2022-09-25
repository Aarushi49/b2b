global with sharing class AB2CCartHeaderService {
    private static final String CART_ITEM_TYPE = 'Major';

    @RemoteAction
    global static ccrz.cc_RemoteActionResult getCartNum(ccrz.cc_RemoteActionContext context, String cartId) {
        ccrz.cc_CallContext.initRemoteContext(context);
        ccrz.cc_RemoteActionResult response = new ccrz.cc_RemoteActionResult();
        response.success  = false;
        cartInfo ci = new cartInfo();
        ci.cartSize = 0;
        response.data = ci;

        if (cartId != null) {
            try {                    
                List<ccrz__E_CartItem__c> cartItems = [
                    SELECT Id, ccrz__Product__r.name, ccrz__Product__r.ccrz__SKU__c 
                    FROM ccrz__E_CartItem__c
                    WHERE ccrz__Cart__r.ccrz__EncryptedId__c = :cartId
                        AND ccrz__Cart__r.ccrz__CartStatus__c = 'Open'
                        AND ccrz__cartItemType__c = :CART_ITEM_TYPE
                ];
                ci.cartSize = cartItems.size();
                ci.cartItems = cartItems;
                response.data = ci;
                response.success = true;
            } catch (Exception e) {
                response.data = e.getMessage();
            }
        }
        return response;
    }

    public class cartInfo{
        public integer cartSize;
        public List<ccrz__E_CartItem__c> cartItems;
    }
}