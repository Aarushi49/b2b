global class AB2CPromotionService {
    // allow unit tests to override this
    @TestVisible private static String storeName = 'AlexanianStore';
    @TestVisible private static Exception mockException;

    public AB2CPromotionService() {

    }

    /**
    * Returns a list of promotional content for the given category ID
    * @param - pageName - The page location ID defined in the Page Location multiselect in CC 
    * @param - categoryId - The category ID where the promotion should appear (optional, only for Category Landing and PLP pages)
    * @return - cc_RemoteActionResult - Data model used for promotional content
    */
    @RemoteAction
    global static ccrz.cc_RemoteActionResult getPromotions(ccrz.cc_RemoteActionContext context, String pageName, String categoryId) {
        ccrz.cc_CallContext.initRemoteContext(context);
        ccrz.cc_RemoteActionResult response = new ccrz.cc_RemoteActionResult();
        response.success  = false;

        if (pageName != null) {
            try {
                // simulate API exceptions in unit tests
                if (mockException != null) throw mockException;

                List<ccrz__E_Promo__c> promotions;
                if (categoryId == null) {
                    promotions = [
                        SELECT Id, Name, ccrz__Category__c, ccrz__ExternalLink__c, AB2C_Text_Overlay__c, ccrz__LinkType__c, ccrz__LocationType__c, ccrz__PageLocation__c, ccrz__ProductRelated__c, ccrz__Product__c, ccrz__PromoId__c, ccrz__Sequence__c, ccrz__SplashRotate__c, Promotion_Group_ID__c
                        FROM ccrz__E_Promo__c 
                        WHERE ccrz__PageLocation__c = :pageName
                            AND IsDeleted = false 
                            AND ccrz__Enabled__c = TRUE 
                            AND ccrz__StartDate__c <= TODAY 
                            AND ccrz__EndDate__c > TODAY
                            AND ccrz__StorefrontMS__c = :storeName
                        ORDER BY Promotion_Group_ID__c, ccrz__Sequence__c
                    ];
                } else {
                    promotions = [
                        SELECT Id, Name, ccrz__Category__c, ccrz__ExternalLink__c, AB2C_Text_Overlay__c, ccrz__LinkType__c, ccrz__LocationType__c, ccrz__PageLocation__c, ccrz__ProductRelated__c, ccrz__Product__c, ccrz__PromoId__c, ccrz__Sequence__c, ccrz__SplashRotate__c, Promotion_Group_ID__c
                        FROM ccrz__E_Promo__c 
                        WHERE AB2C_Category__c = :categoryId
                            AND ccrz__PageLocation__c = :pageName
                            AND IsDeleted = false 
                            AND ccrz__Enabled__c = TRUE 
                            AND ccrz__StartDate__c <= TODAY 
                            AND ccrz__EndDate__c > TODAY
                            AND ccrz__StorefrontMS__c = :storeName
                        ORDER BY Promotion_Group_ID__c, ccrz__Sequence__c
                    ];
                }

                if (!promotions.isEmpty()) {
                    for (ccrz__E_Promo__c promo : promotions) { // Set category link
                        if ('Category'.equals(promo.get('ccrz__LinkType__c'))) {
                            promo.put('ccrz__ExternalLink__c', 'ccrz__ProductList?categoryId=' + promo.get('ccrz__Category__c'));
                        }
                    }
                }

                response.data = promotions;
                response.success  = true;
            } catch (Exception e) {
                response.data = e.getMessage();
            }
        }

        return response;
    }
}