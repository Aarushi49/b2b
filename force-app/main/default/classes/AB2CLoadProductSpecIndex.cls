/*
* ED July 10th 2019:
* Code taken from OOTB cc_job_LoadProductSpecIndex (on v4.10) and amended
* to allow muliiple spec values for a same spec/product pair.
* Debug log information added as well.
* Changes to the OOTB code are tagged with EDEC
*/

public with sharing class AB2CLoadProductSpecIndex implements Database.Batchable<sObject>{
    public final String query;
    
    //==================================================
    // CONSTRUCTOR
    //==================================================
    public AB2CLoadProductSpecIndex(String q){
        query=q;
    }

    public AB2CLoadProductSpecIndex(){

    }

    //==================================================
    // DERIVED METHODS
    //==================================================
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        System.debug(LoggingLevel.INFO, 'AB2CLoadProductSpecIndex.execute - START');
        // EDEC: the BATCH_INDEX_TRIGGER_ENABLED_FLAG variable is not visible. Which means when the product trigger fires the product will be marked as out of sync with the index
        // EDEC: downside being that incremental product index build will reprocess all products if this product spec index job has run
        // EDEC: we cannot modify the trigger to check for a different variable
        // Set To FALSE --> This Will Disable Product Trigger And Prevent It From Firing (Setting Product Index Status To "Not Current" Un-necessarily)... 
        //ccrz.ccProductIndexBuilder.BATCH_INDEX_TRIGGER_ENABLED_FLAG = FALSE;
        
        List<ccrz__E_Product__c> prods = (List<ccrz__E_Product__c>) scope;
        List<String> prodIdList = new List<String>();
        List<String> fullProdIdList = new List<String>();
        List<String> lstAggregatedProd = new List<String>();
        for (ccrz__E_Product__c prod: prods) {
            prodIdList.add(prod.Id);
            fullProdIdList.add(prod.Id);
            if (prod.ccrz__ParentProduct__c != null)
                fullProdIdList.add(prod.ccrz__ParentProduct__c);
            if(prod.ccrz__ProductType__c == 'Aggregated')
                lstAggregatedProd.add(prod.Id);
        }
        List<ccrz__E_ProductCategory__c> prodCats = [Select e.ccrz__Product__c, e.ccrz__ProductCategoryID__c, e.Id, e.ccrz__Category__c From ccrz__E_ProductCategory__c e Where e.ccrz__Product__c in :prodIdList];
        Map<String, List<String>> prodCategoryMap = new Map<String, List<String>>();
        for (ccrz__E_ProductCategory__c prodCat: prodCats) {
            if (!prodCategoryMap.containsKey(prodCat.ccrz__Product__c))
                prodCategoryMap.put(prodCat.ccrz__Product__c, new List<String>());
            prodCategoryMap.get(prodCat.ccrz__Product__c).add(prodCat.ccrz__Category__c);
        }
        
        List<ccrz__E_Category__c> categories = [SELECT Id, Name, ccrz__ParentCategory__c FROM ccrz__E_Category__c]; 
        Map<String, ccrz__E_Category__c> categoryMap = new Map<String, ccrz__E_Category__c>();
        for (ccrz__E_Category__c cat: categories) {
            categoryMap.put(cat.Id, cat);
        }
        
        Set<String> categoriesForSpecs = new Set<String>();
        Map<String, List<cc_bean_SpecBuilder>> prodHierarchyMap = new Map<String, List<cc_bean_SpecBuilder>>();
        for (ccrz__E_Product__c prod: prods) {
            List<cc_bean_SpecBuilder> prodHierarchy = new List<cc_bean_SpecBuilder>();
            prodHierarchy.add(new cc_bean_SpecBuilder(null, prod.Id));
            if (prod.ccrz__ParentProduct__c != null)
                prodHierarchy.add(new cc_bean_SpecBuilder(null, prod.ccrz__ParentProduct__c));
            List<String> prodCategories = prodCategoryMap.get(prod.Id);
            if (prodCategories != null && !prodCategories.isEmpty()) {
                for (String prodCatId: prodCategories) {
                    prodHierarchy.add(new cc_bean_SpecBuilder(prodCatId, null));
                    categoriesForSpecs.add(prodCatId);
                }
            }
            prodHierarchyMap.put(prod.Id, prodHierarchy);
        }
        
        Map<String,List<ccrz__E_ProductSpec__c>> specsByProduct = getProductSpec(fullProdIdList);
        if(lstAggregatedProd.size() > 0 && specsByProduct.size() > 0){
             transferCompositeSpecstoAggregated(lstAggregatedProd,specsByProduct);
        }
        
        Map<String,List<ccrz__E_CategorySpec__c>> specsByCategory = getCategorySpecValues(categoriesForSpecs);
        List<ccrz__E_ProductSpecIndex__c> specIndices = new List<ccrz__E_ProductSpecIndex__c>();
        for (ccrz__E_Product__c prod: prods) {
            List<cc_bean_SpecBuilder> prodHierarchy = prodHierarchyMap.get(prod.Id);
            Map<String, String> prodSpecMap = new Map<String, String>();
            for (Integer i = prodHierarchy.size()-1; i >= 0; i--) {
                cc_bean_SpecBuilder builder = prodHierarchy.get(i);
                if (builder.catId != null) {
                    List<ccrz__E_CategorySpec__c> catSpecs = specsByCategory.get(builder.catId);
                    if (catSpecs != null) {
                        for (ccrz__E_CategorySpec__c catSpec: catSpecs) {
                            String sv = catSpec.ccrz__SpecValue__c;
                            if(catSpec.ccrz__Spec__r.ccrz__FilterType__c == 'Slider'){
                                sv = catSpec.ccrz__SpecValue__c.replaceAll('[^0-9.]', '').leftPad(18, '0');
                            }
                            prodSpecMap.put(catSpec.ccrz__Spec__c + '|' + catSpec.ccrz__Spec__r.Name, sv);
                        }
                    }
                }
                else {
                    List<ccrz__E_ProductSpec__c> pSpecs = specsByProduct.get(builder.prodId);
                    if (pSpecs != null) {
                        for (ccrz__E_ProductSpec__c pSpec: pSpecs) {
                            String sv = pSpec.ccrz__SpecValue__c;
                            if(pSpec.ccrz__Spec__r.ccrz__FilterType__c == 'Slider'){
                                sv = pSpec.ccrz__SpecValue__c.replaceAll('[^0-9.]', '').leftPad(18, '0');
                            }
                            // EDEC: modify the key so that it allows different values for a same spec
                            //prodSpecMap.put(pSpec.ccrz__Spec__c + '|' +pSpec.ccrz__Spec__r.Name, sv);
                            String specKey = pSpec.ccrz__Spec__c + '|' + pSpec.ccrz__Spec__r.Name + '|' + pSpec.ccrz__SpecValue__c;
                            prodSpecMap.put(specKey, sv);
                        }
                    }
                }
            }
            
            Set<String> keys = prodSpecMap.keySet();
            String filterData = '';
            // EDEC: OOTB code to populate the FilterData of the product; this field is indexed and used during search in order to include spec values in search scope.
            // EDEC: add counter to append and make ccrz__ProductSpecIndexId__c unique
            Integer counter = 0;
            for (String key: keys) {
                // EDEC : increment 
                counter += 1;
                ccrz__E_ProductSpecIndex__c psi = new ccrz__E_ProductSpecIndex__c();
                psi.ccrz__Product__c = prod.Id;
                psi.ccrz__Spec__c = key.substring(0,key.indexOf('|'));
                // EDEC: add counter to make Id unique
                //psi.ccrz__ProductSpecIndexId__c = String.valueOf(psi.ccrz__Product__c) + String.valueOf(psi.ccrz__Spec__c);
                psi.ccrz__ProductSpecIndexId__c = String.valueOf(psi.ccrz__Product__c) + String.valueOf(psi.ccrz__Spec__c) + '_' + String.valueOf(counter);
                psi.ccrz__SpecValue__c = prodSpecMap.get(key);
                specIndices.add(psi);
                System.debug(LoggingLevel.DEBUG,'AB2CLoadProductSpecIndex.execute: pSpecs psi:'+psi);
                filterData += key.substring(key.indexOf('|')+1) + '=' +prodSpecMap.get(key) + '|';
            }
            prod.ccrz__FilterData__c = filterData;
        }
        update prods;
        

        List<ccrz__E_ProductSpecIndex__c> psiListDel = [Select Id from ccrz__E_ProductSpecIndex__c Where ccrz__Product__c in :prodIdList];
        if(ccrz.ccUtil.isNotEmpty(psiListDel)){
            delete psiListDel;
            DataBase.emptyRecycleBin(psiListDel);
        }
        
        insert specIndices;
        System.debug(LoggingLevel.INFO,'AB2CLoadProductSpecIndex.execute - END');
    }
    
    public void finish(Database.BatchableContext BC){
        
    }


    public Boolean transferPriceToSpecs(List<string> productIds){
        AB2C_Batch_Configuration__c AB2CConfiguration = AB2C_Batch_Configuration__c.getInstance();      

        List<ccrz__E_CompositeProduct__c> lstProducts = [SELECT ccrz__Component__c, ccrz__Composite__r.AB2C_Show_Square_Footage_Calculator__c, ccrz__Component__r.ccrz__SKU__c
            FROM ccrz__E_CompositeProduct__c 
            WHERE ccrz__Component__c IN :productIds
                AND ccrz__Composite__r.ccrz__ProductType__c IN ('Product','Aggregated')];
        
        // Update price specs for products
        Map<string, Boolean> lstFilterProduct = new Map<string, Boolean>();
        for(ccrz__E_CompositeProduct__c cp : lstProducts){
            lstFilterProduct.put(cp.ccrz__Component__c, cp.ccrz__Composite__r.AB2C_Show_Square_Footage_Calculator__c);
        }
    
        List<AggregateResult> productPrices = [SELECT MIN(ccrz__Price__c), MIN(AB2C_Unit_Price__c), ccrz__Product__c
            FROM ccrz__E_PriceListItem__c 
            WHERE ccrz__Product__c != '' AND ccrz__Price__c > 0 
                AND ccrz__Product__c = : lstFilterProduct.keySet() AND CCRZ__ENDDATE__C >= TODAY
                AND ccrz__Product__r.ccrz__ProductType__c IN ('Product')
            GROUP BY ccrz__Product__c];

        List<ccrz__E_ProductSpec__c> lstPS = new List<ccrz__E_ProductSpec__c>();

        for (AggregateResult ar : productPrices)  {
            String price = string.valueOf(ar.get('expr0'));
            String unitPrice = string.valueOf(ar.get('expr1'));
            unitPrice = String.isBlank(unitPrice) ? price : unitPrice;
            String productSpec =  (string)ar.get('ccrz__Product__c');
            boolean isFlooring = lstFilterProduct.get(productSpec);

            lstPS.add(new ccrz__E_ProductSpec__c(
                AB2C_Product_Spec_SKU__c = isFlooring ? unitPrice : price,
                ccrz__SpecValue__c = isFlooring ? unitPrice : price,
                ccrz__Product__c = productSpec,
                ccrz__Spec__c = AB2CConfiguration.AB2C_Spec_Price_ID__c,
                AB2C_Product_Spec_ID__c = productSpec + '-' + AB2CConfiguration.AB2C_Spec_Price_ID__c
            ));
        }

        // Update price specs for products with protection plans
        Map<string, string> protectionSkuMap = new Map<string, string>();
        for(ccrz__E_CompositeProduct__c cp : lstProducts){
            protectionSkuMap.put(cp.ccrz__Component__r.ccrz__SKU__c + '-PROTECTION', cp.ccrz__Component__r.Id);
        }

        List<AggregateResult> protectionPrices = [SELECT MIN(ccrz__Price__c), ccrz__Product__c, ccrz__Product__r.ccrz__SKU__c, ccrz__Product__r.Name
            FROM ccrz__E_PriceListItem__c 
            WHERE ccrz__Product__c != '' AND ccrz__Price__c > 0 
                AND ccrz__Product__r.ccrz__SKU__c in :protectionSkuMap.keySet() AND CCRZ__ENDDATE__C >= TODAY
                AND ccrz__Product__r.ccrz__ProductType__c IN ('Product')
            GROUP BY ccrz__Product__c, ccrz__Product__r.ccrz__SKU__c, ccrz__Product__r.Name];

        for (AggregateResult ar : protectionPrices)  {
            String price = string.valueOf(ar.get('expr0'));
            String productSku = (string)ar.get('ccrz__SKU__c');
            String productName = (string)ar.get('Name');

            if (protectionSkuMap.get(productSku) != null) {
                lstPS.add(new ccrz__E_ProductSpec__c(
                    AB2C_Product_Spec_SKU__c = productSku,
                    ccrz__SpecValue__c = productName + ' - $' + price,
                    ccrz__Product__c = protectionSkuMap.get(productSku),
                    ccrz__Spec__c = AB2CConfiguration.AB2C_Spec_Protection_ID__c,
                    AB2C_Product_Spec_ID__c = productSku + '-' + AB2CConfiguration.AB2C_Spec_Protection_ID__c
                ));
            }
        }
        
        upsert lstPS AB2C_Product_Spec_ID__c;

        return true;
    }

    public class cc_bean_SpecBuilder {
        public String catId { get; set; }
        public String prodId { get; set; }
        public cc_bean_SpecBuilder(String catId, String prodId) {
            this.catId = catId;
            this.prodId = prodId;
        }
    }
    
    /*
    * EDEC: OOTB code to get the specs of the product - modified to include specs from composite products
    * EDEC: additional logic to get specs should be put here, for example if the specs of composite products need to be brought up to the aggregated level
    */
    public Map<String,List<ccrz__E_ProductSpec__c>> getProductSpec(List<String> productIds){
        Map<String,List<ccrz__E_ProductSpec__c>> productSpecMap = new Map<String,List<ccrz__E_ProductSpec__c>>();
        if(productIds == null){
            return productSpecMap;
        }
        
        // AC: Add composite products to product list to bring up composite product specs to aggregate level
        Map<String, String> compositeToParentMap = new Map<String, String>();
        for (ccrz__E_CompositeProduct__c compositeProduct : [SELECT ccrz__Component__c, ccrz__Composite__c FROM ccrz__E_CompositeProduct__c WHERE ccrz__Composite__c in :productIds AND ccrz__Component__r.ccrz__ProductStatus__c IN ('Released', 'Not Orderable')]) {
    		compositeToParentMap.put(compositeProduct.ccrz__Component__c, compositeProduct.ccrz__Composite__c);
        }
        
        List<String> productsIdsCombine = new List<string>();
        productsIdsCombine.addAll(productIds);
        productsIdsCombine.addAll(compositeToParentMap.keySet());
        transferPriceToSpecs(productsIdsCombine);
        
        
        for (ccrz__E_ProductSpec__c prdSpec: [Select e.AB2C_Spec_ID__c,e.AB2C_Spec_Name__c,e.ccrz__SpecValue__c, e.ccrz__ProductID__c, e.Name, 
                                                e.Id, e.ccrz__Spec__c, e.ccrz__Spec__r.Name, e.ccrz__Spec__r.ccrz__Locale__c, 
                                                e.ccrz__Spec__r.ccrz__FilterType__c, e.ccrz__Product__c,e.CCRZ__PRODUCT__R.NAME,
                                                AB2C_Colour_Family__c,AB2C_Product_Spec_SKU__c
                                             From ccrz__E_ProductSpec__c e 
                                             Where (e.ccrz__Product__c in :productsIdsCombine)
                                             Order by e.ccrz__Product__c, e.ccrz__Spec__c]){
            String parentProductId = prdSpec.ccrz__Product__c;
            
            if (compositeToParentMap.containsKey(parentProductId)) {
            	parentProductId = compositeToParentMap.get(parentProductId);
            }
            if(!productSpecMap.containsKey(parentProductId)){
                productSpecMap.put(parentProductId, new List<ccrz__E_ProductSpec__c>{prdSpec});
            } else {
                List<ccrz__E_ProductSpec__c> specList = productSpecMap.get(parentProductId);
                specList.add(prdSpec);
                productSpecMap.put(parentProductId, specList);
            }
        }



        return productSpecMap;
    }

    public Boolean transferCompositeSpecstoAggregated(List<string> productIds,Map<String,List<ccrz__E_ProductSpec__c>> mapProductSpec){
        AB2C_Batch_Configuration__c AB2CConfiguration = AB2C_Batch_Configuration__c.getInstance();      
        
        String spectoTransfer = AB2CConfiguration.AB2C_Transfer_Spec_to_Aggregated__c;
        List<String> lstCheckSpec = spectoTransfer.split(';');
        List<string> externalIds = new List<string>();
        List<ccrz__E_ProductSpec__c> deleteSpecs = new List<ccrz__E_ProductSpec__c>();
        
        
        List<ccrz__E_ProductSpec__c> lstPSAdd = new List<ccrz__E_ProductSpec__c>();
        for(String productID : productIds){
             if(mapProductSpec.ContainsKey(productID)){
                for(ccrz__E_ProductSpec__c ps : mapProductSpec.get(productID)){
                    if(lstCheckSpec.contains(ps.ccrz__Spec__c)){
                        string externalId = productID + '_' + ps.AB2C_SPEC_ID__C + '_' + ps.AB2C_Product_Spec_SKU__c;
                        if(!externalIds.contains(externalId) && ps.ccrz__Product__c != productID){
                            lstPSAdd.add(new ccrz__E_ProductSpec__c(
                                AB2C_Product_Spec_ID__c = externalId, 
                                ccrz__Product__c = productID,
                                ccrz__Spec__c = ps.CCRZ__SPEC__C,
                                ccrz__SpecValue__c = ps.CCRZ__SPECVALUE__C,
                                AB2C_Product_Spec_SKU__c = ps.AB2C_Product_Spec_SKU__c,
                                AB2C_Colour_Family__c = ps.AB2C_Colour_Family__c));
                            externalIds.add(externalId);
                        }
                    }
                }
            }
        }

        if(lstPSAdd.size() > 0){
            system.debug('TEST debug--'+lstPSAdd);
            Database.upsert(lstPSAdd, ccrz__E_ProductSpec__c.AB2C_Product_Spec_ID__c, false);
            
            //Added on 02/08/2022 to remove any extra size and colour specs present on the aggreagted product. Majorly this will include any blocked product specs.
            for(ccrz__E_ProductSpec__c ss: [Select id,ccrz__SpecValue__c,AB2C_Colour_Family__c,AB2C_Product_Spec_SKU__c from ccrz__E_ProductSpec__c where ccrz__Spec__c IN:lstCheckSpec AND ccrz__Product__c IN:productIds and lastmodifieddate != today ]){
                deleteSpecs.add(ss);
            }
            system.debug('delete specs --'+ deleteSpecs);
            if(deleteSpecs.size() > 0){
                delete deleteSpecs;
            }
        
        }        
        return true;
    }
    
    public static Map<String,List<ccrz__E_CategorySpec__c>> getCategorySpecValues(Set<String> categoryIds){
        Map<String,List<ccrz__E_CategorySpec__c>> categorySpecMap = new Map<String,List<ccrz__E_CategorySpec__c>>();
        if(categoryIds==null || categoryIds.size()==0){
            return categorySpecMap;
        }
        
        for(ccrz__E_CategorySpec__c csi : [Select e.ccrz__SpecValue__c, e.Name, e.Id, e.ccrz__Spec__c, e.ccrz__Spec__r.Name, e.ccrz__Spec__r.ccrz__FilterType__c, e.ccrz__Category__c From ccrz__E_CategorySpec__c e Where e.ccrz__Category__c in :categoryIds]){
            if(!categorySpecMap.containsKey(csi.ccrz__Category__c)){
                categorySpecMap.put(csi.ccrz__Category__c,new List<ccrz__E_CategorySpec__c>{csi});
            } else {
                List<ccrz__E_CategorySpec__c> indexList =categorySpecMap.get(csi.ccrz__Category__c);
                indexList.add(csi);
                categorySpecMap.put(csi.ccrz__Category__c,indexList);
            }
        }
        return categorySpecMap;
    }
}