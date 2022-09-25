global class AB2CHomeController extends AB2CCommonController {
    public AB2CHomeController() {

    }
    @TestVisible static Exception mockException;
    /**
    * Build the data model object to populate the home content
    * @return - cc_RemoteActionResult - Data model used for home page
    */
    @RemoteAction
    global static ccrz.cc_RemoteActionResult getHomeDetails(ccrz.cc_RemoteActionContext context) {
        ccrz.cc_CallContext.initRemoteContext(context);
        ccrz.cc_RemoteActionResult response = new ccrz.cc_RemoteActionResult();
        response.success  = false;

        try {
            if (mockException != null) throw mockException;
            // Build response data object
            Map<String, Object> homeResponse = new Map<String, Object>();
            ccrz.cc_RemoteActionResult promotionsResponse = AB2CPromotionService.getPromotions(context, 'home', null);
            if (promotionsResponse.success) {
                homeResponse.put('promotions', promotionsResponse.data);
            }

            response.data = homeResponse;
            response.success  = true;
        } catch (Exception e) {
            response.data = e;
        }

        return response;
    }
}