global class AB2CAutocompleteService {
    private static final Integer AUTOCOMPLETE_SEARCH_LIMIT = 10;
    public AB2CAutocompleteService() {

    }

    @RemoteAction
    global static ccrz.cc_RemoteActionResult getAutocompleteResultsFor(ccrz.cc_RemoteActionContext context, String searchTerm) {
        ccrz.cc_CallContext.initRemoteContext(context);
        ccrz.cc_RemoteActionResult response = new ccrz.cc_RemoteActionResult();
        response.success  = false;

        if (searchTerm != null) {
            try {
                String formattedSearchTerm = '%' + searchTerm + '%';

                List<AggregateResult> prodInds = [
                    SELECT ccrz__ProductName__c
                    FROM ccrz__E_ProductIndex__c
                    WHERE ccrz__ProductName__c LIKE :formattedSearchTerm
                        AND  ccrz__Storefront__c INCLUDES('AlexanianStore')
                        AND ccrz__Product__r.AB2C_Is_Component__c = false
                    GROUP BY ccrz__ProductName__c
                    LIMIT :AUTOCOMPLETE_SEARCH_LIMIT
                ];

                Set<String> names = new Set<String>();
                for (AggregateResult prodIndex : prodInds) {
                    names.add((String)prodIndex.get('ccrz__ProductName__c'));
                }

                response.data = names;
                response.success  = true;
            } catch (Exception e) {
                response.data = e.getMessage();
            }
        }

        return response;
    }
}