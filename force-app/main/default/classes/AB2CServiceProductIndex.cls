global with sharing class AB2CServiceProductIndex extends ccrz.ccServiceProductIndex {
    global override virtual Map<String,Object> getReturnClauseMap(Map<String,Object> inputData) {
        Map<String,Object> retData = super.getReturnClauseMap(inputData);

        String productIndex = (String) retData.get('ProductIndex');
        if (productIndex != null) {
            // Add to SELECT clause: 
            // - ProductCategorySequence__c - needed when searching and then sorting by Bestsellers
            // - FilterData__c - needed to distinguish between products that are non-components (ie: aggregate or simple products). Only non-component products have filter data.
            productIndex = productIndex.replace('ShortDescription__c', 'ShortDescription__c, {0}ProductCategorySequence__c, {0}FilterData__c');
            retData.put('ProductIndex', productIndex);
        }

        String searchString = (String) inputData.get('rankSearchString');
        if (searchString != null && searchString.length() > 0) {
            // Add to WHERE clause: 
            // - ccrz__Product__r.AB2C_Is_Component__c = false - needed when searching to filter out component products
            productIndex = productIndex.replace('AND Storefront__c', 'AND {0}Product__r.AB2C_Is_Component__c = false AND Storefront__c');
            retData.put('ProductIndex', productIndex);
        }

        debug('getReturnClauseMap', inputData, retData);
        return retData;
    }
    
    /**
     * Called when searching. Number of productIndicies in the output will be the number of search results in the UI.
     * Also called by pagination logic. Make sure pagincation logic doesn't filter out anything that this list returns. 
     */
    global override virtual Map<String,Object> search(Map<String,Object> inputData) {      
        // Extract search string and search Algolia for matching SKUs
        Map<String,Object> originalInputData = (Map<String,Object>) inputData.get('originalInputData');
        String searchString = '';
        if (originalInputData != null) {
            searchString = (String) originalInputData.get('searchString');
        }

        Set<String> skusFromAlgolia = getSkusFromAlgolia(searchString);
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'SKUs from Algolia: ', JSON.serialize(skusFromAlgolia));

        List<ccrz__E_ProductIndex__c> productIndices = [SELECT Id, ccrz__Product__c, ccrz__ProductName__c, ccrz__IndexPrice__c, ccrz__SKU__c, ccrz__ShortDescription__c, ccrz__ProductCategorySequence__c, ccrz__FilterData__c, ccrz__ProductStartDate__c 
            FROM ccrz__E_ProductIndex__c 
            WHERE ccrz__Product__r.AB2C_Is_Component__c = false
                AND (ccrz__ProductStatus__c = 'Released' OR ccrz__ProductStatus__c = 'Not Orderable')
                AND ccrz__ProductStartDate__c <= TODAY AND ccrz__ProductEndDate__c >= TODAY 
                AND ccrz__Locale__c = 'en_CA' AND ccrz__Active__c = true 
                AND ccrz__Storefront__c INCLUDES ('AlexanianStore')
                AND ccrz__Product__r.ccrz__SKU__c in :skusFromAlgolia];
        
        // Filter out only unique product Ids. There will be multiple product indexes for the same product 
        // that belong to multiple categories, which increases the number of search results.
        Set<String> productIds = new Set<String>();
        for (Integer i = (productIndices.size()-1); i >= 0; i--){
            String productId = (String) productIndices[i].get('ccrz__Product__c');
            if(productIds.contains(productId)){
                productIndices.remove(i);
            } else {
                productIds.add(productId);
            }
        }

        inputData.put('productIndices', productIndices);
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'AB2CServiceProductIndex:search:input', JSON.serialize(inputData));
        
        // We avoid calling super.search() here because we are building the product index list ourselves from Algolia
        //Map<String,Object> retData = super.search(inputData);

        return inputData;
    }

    private Set<String> getSkusFromAlgolia(String searchText) {
        Set<String> skus = new Set<String>();

        try {
            HttpRequest req = new HttpRequest();
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json; charset=UTF-8'); 
            req.setHeader('X-Algolia-Application-Id', '{!$Credential.Username}');
            req.setHeader('X-Algolia-API-Key', '{!$Credential.Password}');
            req.setEndpoint('callout:algolia_product_query/?attributesToRetrieve=sku&attributesToHighlight=null&query=' + EncodingUtil.urlEncode(searchText,'UTF-8'));

            HttpResponse res = new Http().send(req);
            Map<String, Object> fieldMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> hits = (List<Object>) fieldMap.get('hits');
            if (hits != null) {
                for (Object hit : hits) {
                    skus.add((String) ((Map<String, Object>) hit).get('sku'));
                }
            }

        } catch (Exception e) {
            ccrz.ccLog.log(System.LoggingLevel.ERROR, 'Error fetching SKUs from Algolia: ', e.getMessage());
        }

        return skus;
    }

    private void debug(String functionName, Map<String,Object> inputMap, Map<String,Object> outputMap) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'AB2CServiceProductIndex:' + functionName + ':input', JSON.serialize(inputMap));
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'AB2CServiceProductIndex:' + functionName + ':output', JSON.serialize(outputMap));
    }
}