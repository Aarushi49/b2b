global class AB2CProductController extends AB2CCommonController {
    public AB2CProductController() {
        
    }

    @TestVisible private static Exception mockException;

    @RemoteAction
    global static ccrz.cc_RemoteActionResult getProductDetailBySku(ccrz.cc_RemoteActionContext context, String productSKU) {
        return getProductDetailBySkuSizeColour(context, productSKU, null, null);
    }
    
    /**
    * Returns Product Details
    * @param - sku - Product sku
    * @return - cc_RemoteActionResult
    */
    @RemoteAction
    global static ccrz.cc_RemoteActionResult getProductDetailBySkuSizeColour(ccrz.cc_RemoteActionContext context, String productSKU, String colorSKU, String sizeSKU) {
        ccrz.cc_CallContext.initRemoteContext(context);
        ccrz.cc_RemoteActionResult response = new ccrz.cc_RemoteActionResult();
        response.success  = false;
        Set<string> skus = new Set<string>{productSKU};
        if (string.isNotBlank(colorSKU)) { // Dynamic kit skus don't have sizes
            skus.add(productSKU + '-' + colorSKU);
        }
        if (string.isNotBlank(colorSKU) && string.isNotBlank(sizeSKU)) {
            skus.add(productSKU + '-' + colorSKU + '-' + sizeSKU);
            skus.add(productSKU + '-' + colorSKU + '-' + sizeSKU + '-PROTECTION');
        }
        
        try {
            // simulate API exceptions in unit tests
            if (mockException != null) throw mockException;

            Map<String, Object> productRequest = new Map<String, Object> {
                ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                ccrz.ccApiProduct.PRODUCTSKULIST => skus,
                ccrz.ccAPIProduct.PARAM_BY_SEQ => true,
                ccrz.ccAPIProduct.PARAM_BY_ASC => true,
                ccrz.ccApiProduct.PARAM_INCLUDE_PRICING => true,
                ccrz.ccApiProduct.PARAM_INCLUDE_SELLERS => false
            };

            system.debug('productSKU  ===>'+ productSKU);
            system.debug('colorSKU  ===>'+ colorSKU);
            system.debug('sizeSKU  ===>'+sizeSKU);
            system.debug('productRequest  ===>'+ JSON.serialize(productRequest));
            Map<String, Object> productResponse = ccrz.ccApiProduct.fetch(productRequest);
            system.debug('productResponse  ===>'+ JSON.serialize(productResponse));
            if (productResponse.get(ccrz.ccAPIProduct.PRODUCTLIST) != null) {
                List<Map<String, Object>> productList = (List<Map<String, Object>>) productResponse.get(ccrz.ccAPIProduct.PRODUCTLIST);
                // If product is a component, fetch the parent and component product
                if (productList.size() == 1 && (boolean) productList.get(0).get('AB2CIsComponent') == true) {
                    List<Map<String, Object>> specs = (List<Map<String, Object>>) productList.get(0).get('productSpecsS');
                    if (specs != null && specs.size() > 0) {
                        String componentSizeSKU = null;
                        String componentColorSKU = null;
                        for (Map<String, Object> spec : specs) {
                            if ((boolean) spec.get('AB2CIsSize') == true) componentSizeSKU = (String) spec.get('AB2CProductSpecSKU');
                            if ((boolean) spec.get('AB2CPSIsSwatch') == true) componentColorSKU = (String) spec.get('AB2CProductSpecSKU');
                        }
                        if (componentColorSKU != null && componentSizeSKU != null) {
                            String parentSKU = productSKU.replace('-'+componentColorSKU, '').replace('-' + componentSizeSKU, '');
                            return getProductDetailBySkuSizeColour(context, parentSKU, componentColorSKU, componentSizeSKU);
                        }
                    }
                }

                // Wrap, sort and unwrap product list
                List<ProductComparator> productListSorted = new List<ProductComparator>();
                for (Map<String, Object> product : productList) {
                    productListSorted.add(new ProductComparator(product));
                }
                productListSorted.sort();
                productList.clear();
                for (ProductComparator productCompare : productListSorted) {
                    productList.add(productCompare.product);
                }
                system.debug('response.data  ===>'+ productList);
                response.data = productList;
                response.success  = true;     
            }
        } catch(Exception e){
            response.data = e.getMessage();
        } finally {
            ccrz.ccLog.close(response);
        }
        
        return response;
    }
    
    
    /**
    * Returns a list of featured products for the given the category
    * @param - categoryId - The category ID
    * @return - cc_RemoteActionResult - Data model used for featured products
    */
    @RemoteAction
    global static ccrz.cc_RemoteActionResult getProducts(ccrz.cc_RemoteActionContext context, List<String> productIdList) {
        ccrz.cc_CallContext.initRemoteContext(context);
        ccrz.cc_RemoteActionResult response = new ccrz.cc_RemoteActionResult();
        response.success  = false;
        
        if (productIdList != null) {
            try {
                // simulate API exceptions in unit tests
                if (mockException != null) throw mockException;

                Map<String, Object> productRequest = new Map<String, Object>{
                    ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                    ccrz.ccAPIProduct.PRODUCTIDLIST => new Set<String>(productIdList),
                    ccrz.ccApiProduct.PARAM_INCLUDE_PRICING => true,
                    ccrz.ccApiProduct.PARAM_INCLUDE_SELLERS => false
                };
                            
                Map<String, Object> productResponse = ccrz.ccAPIProduct.fetch(productRequest);
                if (productResponse.get(ccrz.ccAPIProduct.PRODUCTLIST) != null) {
                    List<Map<String, Object>> productList = (List<Map<String, Object>>) productResponse.get(ccrz.ccAPIProduct.PRODUCTLIST);
                    response.data = productList;
                }
                
                response.success  = true;
            } catch (Exception e) {
                response.data = e.getMessage();
            }
        }
        
        return response;
    }

    @RemoteAction
    global static ccrz.cc_RemoteActionResult getProductPromosByCategory(ccrz.cc_RemoteActionContext context, String categoryId) {
        ccrz.cc_RemoteActionResult response = new ccrz.cc_RemoteActionResult();
        response.success  = false;
        Map<String, Object> promoResponse = new Map<String, Object>();

        try {
            ccrz.cc_RemoteActionResult promos = AB2CPromotionService.getPromotions(context, 'productList', categoryId);
            if (promos.success) {
                promoResponse.put('promos', promos.data);
            }

            if (categoryId != null) {
                ccrz__E_Category__c category = [SELECT ccrz__ShortDesc__c, ccrz__LongDesc__c FROM ccrz__E_Category__c WHERE Id = :categoryId LIMIT 1];
                if (category != null) {
                    promoResponse.put('seoTitle', category.ccrz__ShortDesc__c);
                    promoResponse.put('seoDescription', category.ccrz__LongDesc__c);
                }
            }

            response.data = promoResponse;
            response.success = true;
        } catch (Exception e) {
            response.data = e.getMessage();
        }

        return response;
    }

    // Class to compare a product list by SKU
    global class ProductComparator implements Comparable {
        public Map<String, Object> product;
        private String sku;
        
        public ProductComparator(Map<String, Object> product) {
            this.product = product;
            sku = (String) product.get('SKU');
            if (sku == null) {
                sku = (String) product.get('sku');
            }
        }
        
        global Integer compareTo(Object compareTo) {
            Map<String, Object> productCompareTo = ((ProductComparator) compareTo).product;
            String skuCompareTo = (String) productCompareTo.get('SKU');
            if (skuCompareTo == null) {
                skuCompareTo = (String) productCompareTo.get('sku');
            }

            if (sku.length() < skuCompareTo.length()) {
                return -1;
            } else if (sku.length() > skuCompareTo.length()) {
                return 1;
            }     
            return 0;       
        }
    }
}