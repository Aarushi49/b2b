global with sharing class AB2CLogicCartPrice extends ccrz.ccLogicCartPrice {
    /**
     * priceItem override to set price to 0 for SAMPLE products in the cart
     */
    global virtual override Map<String,Object> priceItem(Map<String,Object> inputData) {
        Boolean sampleProd = false;
        ccrz__E_CartItem__c cartItem = (ccrz__E_CartItem__c)inputData.get('cartItem');

        if (cartItem != null && cartItem.ccrz__Product__r != null) {
            String prodSKU = cartItem.ccrz__Product__r.ccrz__SKU__c;
            if (prodSKU != null && prodSKU.contains('SAMPLE')) {
                sampleProd = true;
            }
        }

        Map<String, Object> pricingData = (Map<String, Object>)inputData.get(ccrz.ccApiProduct.PRODUCTPRICINGDATA);
        Map<String, Object> prodPriceData = (Map<String, Object>)pricingData.get(cartItem.ccrz__Product__c);
        Map<String, Object> price = (Map<String, Object>)prodPriceData.get('productPrice');


        if (sampleProd) {
            price.put('price', 0);
        }

        return super.priceItem(inputData);
    }

}