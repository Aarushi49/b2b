global with sharing class AB2CServiceProduct extends ccrz.ccServiceProduct {
    global virtual override Map<String,Object> getFieldsMap(Map<String,Object> inputData) {
        // Add product specs to field map
        Map<String, Object> sizing = (Map<String, Object>) inputData.get(ccrz.ccAPI.SIZING);
        if (sizing != null) {
            Map<String, Object> entityName = (Map<String, Object>) sizing.get(ccrz.ccAPIProduct.ENTITYNAME);
            if (entityName != null) {
                List<String> szRel = (List<String>) entityName.get(ccrz.ccAPI.SZ_REL);
                if (szRel != null) {
                    szRel.add('Product_Specs__r');
                }
            }
        }

        // Add new fields to Product 
        Map<String,Object> retData = super.getFieldsMap(inputData);
        String existingFields = (String) retData.get(ccrz.ccService.OBJECTFIELDS);
        String fieldSize = getFieldSize(inputData, ccrz.ccAPIProduct.ENTITYNAME);
        String newFields = '';
        if (!existingFields.contains('ServiceFlag__c')) { // indicates if a product is on sale
            newFields += ',ccrz__ServiceFlag__c';
        }
        if (fieldSize.equals(ccrz.ccAPI.SZ_M)) { // PLP uses medium fields
            newFields += ',AB2C_Is_Component__c,AB2C_Show_Square_Footage_Calculator__c,AB2C_Show_Per_Linear_Foot__c,ccrz__Quantityperunit__c,AB2C_In_Store_Only__c';
        } else {
            newFields += ',AB2C_Show_Square_Footage_Calculator__c,AB2C_Show_Per_Linear_Foot__c,AB2C_Is_Component__c,AB2C_In_Store_Only__c';
        }
        retData.put(ccrz.ccService.OBJECTFIELDS, existingFields + newFields);
        debug('getFieldsMap', inputData, retData);
        return retData;
    }

    // allow dependency on superclass method to be stubbed out
    @TestVisible Map<String, Object> mockSuperSubQueryMap;
    
    global virtual override Map<String, Object> getSubQueryMap(Map<String, Object> inputData) {
        Map<String, Object> retData = super.getSubQueryMap(inputData);
        // use the mock if a unit test injected it
        if (mockSuperSubQueryMap != null) retData = mockSuperSubQueryMap;
        
        String productSpecQuery = String.valueOf(retData.get('Product_Specs__r'));
        if (productSpecQuery != null){
            String newField = ', AB2C_Product_Spec_SKU__c, AB2C_PS_Is_Swatch__c, AB2C_Is_Size__c, AB2C_Spec_Value_RT__c, AB2C_Colour_Family__c, AB2C_Features_Attributes_Section__c, AB2C_Spec_Name__c';
            productSpecQuery = productSpecQuery.replace('FROM', newField + ' FROM');
            retData.put('Product_Specs__r', productSpecQuery);
        }

        String compositeProductsQuery = String.valueOf(retData.get('CompositeProducts__r'));
        if (compositeProductsQuery != null){
            String newField = ', AB2C_Component_Quantity__c, AB2C_Component_Requires_Calculator__c';
            compositeProductsQuery = compositeProductsQuery.replace('FROM', newField + ' FROM');
            retData.put('CompositeProducts__r', compositeProductsQuery);
        }

        // Add related products sub query
        if (!retData.containsKey('E_RelatedProducts__r')) {
            retData.put('E_RelatedProducts__r', '(SELECT RelatedProductType__c, RelatedProduct__c, Sequence__c, ShortDesc__c FROM ccrz__E_RelatedProducts__r)');
        }

        debug('getSubQueryMap', inputData, retData);
        return retData;
    }

    @TestVisible private String getFieldSize(Map<String,Object> inputData, String fieldName) {
        Map<String, Object> sizing = (Map<String, Object>) inputData.get(ccrz.ccAPI.SIZING);
        if (sizing != null) {
            Map<String, Object> entityName = (Map<String, Object>) sizing.get(fieldName);
            if (entityName != null) {
                return (String) entityName.get(ccrz.ccAPI.SZ_DATA);
            }
        }
        return '';
    }

    private void debug(String functionName, Map<String,Object> inputMap, Map<String,Object> outputMap) {
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'AB2CServiceProduct:' + functionName + ':input', JSON.serialize(inputMap));
        ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'AB2CServiceProduct:' + functionName + ':output', JSON.serialize(outputMap));
    }
}