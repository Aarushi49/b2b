global class AB2CCategoryLandingController extends AB2CCommonController {
    public AB2CCategoryLandingController() {

    }
    @TestVisible static Exception mockException;
    /**
    * Build the data model object to populate the category landing page
    * @param - seoId - Category SeoID belonging to this landing page
    * @return - cc_RemoteActionResult - Data model used for category landing page
    */
    @RemoteAction
    global static ccrz.cc_RemoteActionResult getCategoryLandingDetails(ccrz.cc_RemoteActionContext context, String seoId) {
        ccrz.cc_CallContext.initRemoteContext(context);
        ccrz.cc_RemoteActionResult response = new ccrz.cc_RemoteActionResult();
        Map<String, Object> categoryDetailsResponse = new Map<String, Object>();
        response.success  = false;

        if (seoId != null) {
            try {
                if (mockException != null) throw mockException;                
                List<ccrz__E_Category__c> parentCategory = [SELECT Name, ccrz__CategoryID__c, ccrz__ShortDescRT__c, ccrz__LongDescRT__c 
                FROM ccrz__E_Category__c 
                WHERE ccrz__SEOId__c = :seoId];
                ccrz.ccLog.log(LoggingLevel.ERROR,'AB2CCategoryLandingController','Category SEO id: ' + seoId);
                ccrz.ccLog.log(LoggingLevel.ERROR,'AB2CCategoryLandingController','Parent category: ' + parentCategory);

                if (parentCategory.size() > 0) {
                    String categoryId = (String) parentCategory.get(0).get('Id');
                    categoryDetailsResponse.put('categoryId', categoryId);
                    categoryDetailsResponse.put('categoryName', (String) parentCategory.get(0).get('Name'));
                    categoryDetailsResponse.put('shortDesc', (String) parentCategory.get(0).get('ccrz__ShortDescRT__c'));
                    categoryDetailsResponse.put('longDesc', (String) parentCategory.get(0).get('ccrz__LongDescRT__c'));

                    String parentCategoryId = (String) parentCategory.get(0).get('ccrz__CategoryID__c');

                    ccrz.cc_RemoteActionResult promotionsResponse = AB2CPromotionService.getPromotions(context, 'category', categoryId);
                    if (promotionsResponse.success) {
                        categoryDetailsResponse.put('promotions', promotionsResponse.data);
                    }
                }
                response.data = categoryDetailsResponse;
                response.success  = true;
            } catch (Exception e) {
                response.data = e;
                ccrz.ccLog.log(LoggingLevel.ERROR,'AB2CCategoryLandingController','Exception: ' + e.getMessage());
            } finally {
                ccrz.ccLog.close(response);
            }
        }

        return response;
    }
}