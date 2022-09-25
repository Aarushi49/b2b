global class AB2CFeaturedProductService {
    public AB2CFeaturedProductService() {

    }
    // allow unit tests to override this
    @TestVisible private static String storeName = 'AlexanianStore';
    @TestVisible private static Exception mockException;

    /**
    * Returns a list of featured products for the given the category
    * @param - categoryId - The category ID
    * @return - cc_RemoteActionResult - Data model used for featured products
    */
    @RemoteAction
    global static ccrz.cc_RemoteActionResult getFeaturedProductsForCategory(ccrz.cc_RemoteActionContext context, String categoryId) {
        ccrz.cc_CallContext.initRemoteContext(context);
        ccrz.cc_RemoteActionResult response = new ccrz.cc_RemoteActionResult();
        response.success  = false;

        if (categoryId != null) {
            try {
                if (mockException != null) throw mockException;
                List<ccrz__E_FeaturedProduct__c> featuredProducts = [
                    SELECT ccrz__Product__c 
                    FROM ccrz__E_FeaturedProduct__c 
                    WHERE Category__c = :categoryId
                        AND IsDeleted = false 
                        AND ccrz__Enabled__c = TRUE 
                        AND ccrz__Storefront__c = :storeName
                ];
                if (!featuredProducts.isEmpty()) {
                    List<String> productIds = new List<String>();
                    for (ccrz__E_FeaturedProduct__c product : featuredProducts) {
                        productIds.add(product.ccrz__Product__c);
                    }                        
                    ccrz.cc_RemoteActionResult productResponse = AB2CProductController.getProducts(context, productIds);
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