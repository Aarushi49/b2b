global with sharing class AB2CRecommendedProductsService {
    @TestVisible private static final String RELATIONSHIP_TYPE = 'CrossSell';

    public AB2CRecommendedProductsService() {

    }

    /**
    * Returns a list of recommended products for the given set of products in the cart
    * @param - categoryId - The category ID
    * @return - cc_RemoteActionResult - Data model used for featured products
    */
    @RemoteAction
    global static ccrz.cc_RemoteActionResult getRecommendedProductsForCart(ccrz.cc_RemoteActionContext context, String cartId) {
        ccrz.cc_CallContext.initRemoteContext(context);
        ccrz.cc_RemoteActionResult response = new ccrz.cc_RemoteActionResult();
        response.success  = false;

        if (cartId != null) {
            try {
                List<ccrz__E_CartItem__c> cartItems = [
                    SELECT ccrz__Product__c
                    FROM ccrz__E_CartItem__c
                    WHERE ccrz__Cart__r.ccrz__EncryptedId__c =:cartID
                ];
                List<String> cartProductIds = new List<String>();
                for (ccrz__E_CartItem__c item : cartItems) {
                    cartProductIds.add(item.ccrz__Product__c);
                }

                List<ccrz__E_CompositeProduct__c> aggregateProducts = [
                    SELECT ccrz__Composite__r.Id // Parent product ID
                    FROM ccrz__E_CompositeProduct__c 
                    WHERE ccrz__Component__r.Id IN :cartProductIds
                ];
                List<String> aggregateProductIds = new List<String>();
                for (ccrz__E_CompositeProduct__c item : aggregateProducts) {
                    aggregateProductIds.add(item.ccrz__Composite__r.Id);
                }

                if (!aggregateProductIds.isEmpty()) {
                    List<ccrz__E_RelatedProduct__c> recommendedProducts = [
                        SELECT ccrz__RelatedProduct__c
                        FROM ccrz__E_RelatedProduct__c
                        WHERE ccrz__Product__c =:aggregateProductIds
                            AND ccrz__RelatedProductType__c = :RELATIONSHIP_TYPE
                            AND ccrz__StartDate__c <= TODAY 
                            AND ccrz__EndDate__c > TODAY
                            AND IsDeleted = FALSE
                            AND ccrz__Enabled__c = TRUE 
                    ];

                    List<String> recommendedProductIds = new List<String>();
                    for (ccrz__E_RelatedProduct__c product : recommendedProducts) {
                        recommendedProductIds.add(product.ccrz__RelatedProduct__c);
                    }

                    ccrz.cc_RemoteActionResult productResponse = AB2CProductController.getProducts(context, recommendedProductIds);
                    if (productResponse.success) {
                        response.data = productResponse.data;
                    }
                }

                response.success  = true;
            } catch (Exception e) {
                response.data = e.getMessage();
            }
        }
        return response;
    }
}