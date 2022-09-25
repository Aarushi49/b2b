global class AB2CSellerController extends AB2CCommonController {
    public AB2CSellerController() {

    }
    @TestVisible static Exception mockException;
    /**
    * Build the data model object to populate the seller content
    * @return - cc_RemoteActionResult - Data model used for seller locator page
    */
    @RemoteAction
    global static ccrz.cc_RemoteActionResult searchSellersByRadius(ccrz.cc_RemoteActionContext context, Decimal latitude, Decimal longitude, Decimal radius) {
        ccrz.cc_CallContext.initRemoteContext(context);
        ccrz.cc_RemoteActionResult response = new ccrz.cc_RemoteActionResult();
        response.success  = false;
        if (radius < 1) radius = 6400;
        if (latitude == 0) latitude = 43.7184038;
        if (longitude == 0) longitude = -79.5181407;

        try {
            if (mockException != null) throw mockException;
            List<ccrz__E_Seller__c> sellers = [SELECT Id, AB2C_City__c from ccrz__E_Seller__c];
            Set<String> sellerIdList = new Set<String>();
            Set<String> sellerCityList = new Set<String>();
            for (ccrz__E_Seller__c seller : sellers) {
                sellerIdList.add((String) seller.get('Id'));
                sellerCityList.add((String) seller.get('AB2C_City__c'));
            }    
            Map<String, Object> sellerRequest = new Map<String, Object>{
                ccrz.ccAPI.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                    ccrz.ccAPISeller.SELLERIDLIST => sellerIdList,
                    ccrz.ccAPISeller.PARAM_ORIGIN_LAT => latitude,
                    ccrz.ccAPISeller.PARAM_ORIGIN_LNG => longitude,
                    ccrz.ccAPISeller.PARAM_SEARCH_DIST => radius,
                    ccrz.ccAPISeller.PARAM_SEARCH_UNIT => 'km'
            };
            
            // Build response data object
            Map<String, Object> allSellerResponse = new Map<String, Object>();
            allSellerResponse.put('cities', sellerCityList);
            Map<String, Object> sellerResponse = ccrz.ccAPISeller.fetch(sellerRequest);
            if (sellerResponse.get(ccrz.ccAPISeller.SELLERLIST) != null) {
                allSellerResponse.put(ccrz.ccAPISeller.SELLERLIST, sellerResponse.get(ccrz.ccAPISeller.SELLERLIST));
            }

            response.data = allSellerResponse;
            response.success  = true;
        } catch (Exception e) {
            response.data = e.getMessage();
        }

        return response;
    }
}