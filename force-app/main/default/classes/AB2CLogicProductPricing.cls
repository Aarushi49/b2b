global with sharing class AB2CLogicProductPricing extends ccrz.ccLogicProductPricing {

    /**
     * This method determines the prices for aggregate products
     * We use it to override the minPrice to NOT include prices from the Protection Plan compontents
     */
    global virtual override Map<String,Object> evaluateAggregatePricing(Map<String,Object> inputData) {
        Map<String,Object> retData = super.evaluateAggregatePricing(inputData);

        try {
            List<String> nonProtectionSKUs = new List<String>();
            if (retData.containsKey('product') && retData.containsKey('productPricingData')) {
                // 1) Build a list of SKUs for protection plans for this aggregate
                Map<String, Object> product = (Map<String, Object>) retData.get('product');
                if (product != null) {
                    List<Object> compositeProductsS = (List<Object>) product.get('compositeProductsS');
                    for (Object compositeProductObj : compositeProductsS) {
                        Map<String, Object> compositeProduct = (Map<String, Object>) compositeProductObj;
                        string compositeProductId = (string) compositeProduct.get('compositeProductId');
                        if (!compositeProductId.toUpperCase().contains('-PROTECTION')) {
                            nonProtectionSKUs.add((string) compositeProduct.get('component'));
                        }
                    }
                }

                // 2) Iterate through pricing data for this aggregate, and determine minPrice (not including protection plans)
                Decimal minPriceNew = 1000000;
                Map<String, Object> productPricingData = (Map<String, Object>) retData.get('productPricingData');
                for (Id productId : productPricingData.keySet()) {
                    if (nonProtectionSKUs.contains(productId)) {
                        Map<String, Object> productPricing = (Map<String, Object>) productPricingData.get(productId);
                        if (productPricing != null) {
                            Map<String, Object> productPrice = (Map<String, Object>) productPricing.get('productPrice');
                            if (productPrice != null) {
                                Decimal price = (Decimal) productPrice.get('price');
                                ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'AB2CLogicProductPricing:evaluateAggregatePricing' + ' productId:' + productId + ' price:'+price);
                                if (price > 0 && price < minPriceNew) minPriceNew = price;
                            }
                        }
                    }
                }

                // Set the minPrice of the aggregate
                if (product.containsKey('minPrice')) {
                    Decimal minPrice = (Decimal) product.get('minPrice');
                    Decimal maxPrice = (Decimal) product.get('maxPrice');
                    if (minPrice > 0 && minPriceNew <= maxPrice) {
                        product.put('minPrice', minPriceNew);
                        retData.put('product', product);
                    }
                }
            }
        } catch (Exception e) {
            system.debug('in exception '+e.getMessage());
            ccrz.ccLog.log(System.LoggingLevel.ERROR, 'AB2CLogicProductPricing:evaluateAggregatePricing' + e.getMessage());
        }

        return retData;
    }

    private void debug(String functionName, Map<String,Object> inputMap) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'AB2CLogicProductPricing:' + functionName, JSON.serialize(inputMap));
    }
}