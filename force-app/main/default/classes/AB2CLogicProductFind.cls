global with sharing class AB2CLogicProductFind extends ccrz.ccLogicProductFind {
    global virtual override Map<String,Object> performProductFind(Map<String,Object> inputData) {
        Map<String,Object> retData = super.performProductFind(inputData);
        debug('performProductFind', inputData, retData);
        return retData;
    }

    /**
     * Called by pagination logic and while indexing all products.
     */
    global virtual override Map<String,Object> priceProducts(Map<String,Object> inputData) {
        Map<String,Object> retData = super.priceProducts(inputData);
        
        // Filter out any products that are "components" (ie: not aggregate or simple products)
        if (inputData.containsKey('productList')) {
            List<Map<String, Object>> productList = (List<Map<String, Object>>) inputData.get('productList');
            for (Integer i = productList.size() - 1; i > 0; --i) {
                Map<String, Object> product = (Map<String, Object>) productList.get(i);
                if ((boolean) product.get('AB2CIsComponent') == true) {
					productList.remove(i);
                }
            }
        }
        
        debug('priceProducts', inputData, retData);
        return retData;
    }

    global virtual override Map<String,Object> processProducts(Map<String,Object> inputData) {
        Map<String,Object> retData = super.processProducts(inputData);
        debug('processProducts', inputData, retData);
        return retData;
    }

    private void debug(String functionName, Map<String,Object> inputMap, Map<String,Object> outputMap) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'AB2CLogicProductFind:' + functionName + ':input', JSON.serialize(inputMap));
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'AB2CLogicProductFind:' + functionName + ':output', JSON.serialize(outputMap));
    }
}