global with sharing class AB2CLogicCartAddTo extends ccrz.ccLogicCartAddTo  {
    private final Integer MAX_SAMPLES_PER_CART = 4;
    private final String className = 'AB2CLogicCartAddTo';

    /**
     * processInputData override method ensures that a max of 4 SAMPLE products are added to a cart,
     * and ensures only one unique sample is added per cart.
     */
    global virtual override Map<String,Object> processInputData(Map<String,Object> inputData) {
        Boolean removeItem = false;
        String errorMessage = null;
        List<Object> incomingLineData = (List<Object>)inputData.get(ccrz.ccApiCart.LINE_DATA);
        Set<String> sampleProductSkuSet = new Set<String>();
        String encCartId = (String)inputData.get(ccrz.ccApiCart.CART_ENCID);

        try {
            // Parse incoming line data from add to cart request
            for (Object lineData : incomingLineData) {
                ccrz.ccApiCart.LineData castLineData;
                Map<String, Object> castLineData2;
                try {
                    castLineData = (ccrz.ccApiCart.LineData) lineData;
                } catch (Exception e) {
                    try {
                        castLineData2 = (Map<String, Object>) lineData;
                    } catch (Exception ex) {}
                }

                String productSku = castLineData != null ? (String)castLineData.sku : (String)castLineData2.get('sku');
                Decimal productQuantity = castLineData != null ? (Decimal)castLineData.quantity : (Decimal)castLineData2.get('quantity');

                if (!String.isEmpty(productSku) && productSku.contains('SAMPLE')) {
                    sampleProductSkuSet.add(productSku);
                }

                Boolean notInStock = !isInStock(productSku, productQuantity);
                if (notInStock) {
                    removeItem = true;
                    errorMessage = 'Unable to add product to cart, the item is not in stock.';
                }
            }
            
            if (!removeItem && !sampleProductSkuSet.isEmpty()) {
                removeItem = !canAddSample(encCartId, sampleProductSkuSet);
                errorMessage = 'Unable to order a sample. A maximum of 4 samples can be added to the cart.';
            }

            if (removeItem) {
                inputData.put(ccrz.ccApiCart.LINE_DATA, new List<Map<String,Object>>());
            }

            Map<String, Object> output = super.processInputData(inputData);
            if (removeItem && errorMessage != null) {
                output.put('hasLineData', false);
                Map<String, Object> responseData = (Map<String, Object>) output.get('responseData');
                if (responseData != null) {
                    responseData.put('incErr', errorMessage);
                    output.put('responseData', responseData);
                }
            }

            return output;
        } catch (Exception e) {
            ccrz.ccLog.log(LoggingLevel.ERROR, className, e.getMessage());
            return null;
        }
    }

    /**
     * Return true if sample items are eligible to be added to cart
     */
    private boolean canAddSample(String encCartId, Set<String> sampleProductSkuSet) {
        if (!String.isEmpty(encCartId)) {
            // Gather existing SAMPLE cart items
            List<ccrz__E_CartItem__c> sampleCartItems = [
                SELECT ccrz__Product__r.ccrz__SKU__c
                FROM ccrz__E_CartItem__c
                WHERE ccrz__Cart__r.ccrz__EncryptedId__c = :encCartId
                    AND ccrz__Product__r.ccrz__SKU__c LIKE :'%SAMPLE%'
            ];

            if (!sampleCartItems.isEmpty()) {
                if (sampleCartItems.size() < MAX_SAMPLES_PER_CART) {
                    // Check if sample product already exists in cart
                    for (ccrz__E_CartItem__c cartItem : sampleCartItems) {
                        for (String addToCartSku : sampleProductSkuSet) {
                            if (addToCartSku.equals(cartItem.ccrz__Product__r.ccrz__SKU__c)) {
                                ccrz.ccLog.log(LoggingLevel.DEBUG, className, 'Sample ' + addToCartSku + ' is already added to cart.');
                                return false;
                            }
                        }
                    }
                } else {
                    // Max 4 samples allowed per cart
                    ccrz.ccLog.log(LoggingLevel.DEBUG, className, 'Max number of samples added.');
                    return false;
                }
            }
        }

        return true;
    }

    /**
     * Returns true if productInventoryItem is not defined for the given SKU
     * or if there's more quantity in stock than the requested amount
     */
    private boolean isInStock(String sku, Decimal quantityRequested) {
        List<ccrz__E_ProductInventoryItem__c> inventory = [SELECT ccrz__QtyAvailable__c 
            FROM ccrz__E_ProductInventoryItem__c 
            WHERE ccrz__ProductItem__r.ccrz__SKU__c = :sku];
        if (inventory == null || inventory.size() == 0) {
            ccrz.ccLog.log(LoggingLevel.DEBUG, className, 'No inventory quantity found for ' + sku);
            return true;
        } else {
            Decimal quantityInStock = inventory.get(0).ccrz__QtyAvailable__c;
            ccrz.ccLog.log(LoggingLevel.DEBUG, className, 'Quantity of ' + sku + ' in stock ' + quantityInStock);
            return quantityInStock >= quantityRequested;
        }
    }
}