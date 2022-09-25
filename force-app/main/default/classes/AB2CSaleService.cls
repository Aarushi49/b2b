public without sharing class AB2CSaleService {
    @TestVisible static String rootCategoryName = 'AlexanianRoot';

    public static Map<Id, Id> saleCategoryMap {get {
        if (saleCategoryMap == null){
            List<ccrz__E_Category__c> saleCategories = [
                SELECT Id, ccrz__ParentCategory__c, ccrz__ParentCategory__r.Name
                FROM ccrz__E_Category__c
                WHERE Name = 'Sale'
            ];
            saleCategoryMap = new Map<Id, Id>();
            for (ccrz__E_Category__c category : saleCategories){
                saleCategoryMap.put(category.ccrz__ParentCategory__c, category.Id);
                // if parent category is root category, also index it under "null" as the global sale category
                if (category.ccrz__ParentCategory__r != null && category.ccrz__ParentCategory__r.Name == rootCategoryName) saleCategoryMap.put(null, category.Id);
            }
        }
        return saleCategoryMap;
    } set;}
    public static Boolean doDML = true;
    
    public static void processSales(List<ccrz__E_Product__c> products){
        if (products == null || products.isEmpty()) return;
        List<Id> productIds = new List<Id>(new Map<Id, ccrz__E_Product__c>(products).keySet());
        processSales(productIds);
    }

    public static void processSales(List<Id> productIds){
        if (productIds == null || productIds.isEmpty()) return;

        Id globalSaleCategoryId = saleCategoryMap.get(null);

        List<ccrz__E_Product__c> productsQueried = [
            SELECT Id, ccrz__ServiceFlag__c, AB2C_Is_Component__c,
            (SELECT Id, ccrz__Category__c, AB2C_Price_List_Item__c,
            ccrz__StartDate__c, ccrz__EndDate__c,
            ccrz__Category__r.ccrz__ParentCategory__c, ccrz__Category__r.Name,
            ccrz__Category__r.ccrz__ParentCategory__r.Name
            FROM ccrz__Product_Categories__r),
            (SELECT Id, ccrz__StartDate__c, ccrz__EndDate__c, AB2C_Is_Sale__c
            FROM ccrz__E_PriceListItems__r WHERE AB2C_Is_Sale__c = true)
            FROM ccrz__E_Product__c
            WHERE Id IN :productIds
        ];

        ccrz__E_ProductCategory__c[] pcToInsert = new ccrz__E_ProductCategory__c[]{};
        ccrz__E_ProductCategory__c[] pcToUpdate = new ccrz__E_ProductCategory__c[]{};
        ccrz__E_ProductCategory__c[] pcToDelete = new ccrz__E_ProductCategory__c[]{};
        ccrz__E_Product__c[] pToUpdate = new ccrz__E_Product__c[]{};

        for (ccrz__E_Product__c product : productsQueried){
            // this will later be set to true if we find a Sale PLI that is valid today
            Boolean isSale = false;
            // rearrange PLIs in map format
            Map<Id, ccrz__E_PriceListItem__c> pliMap = new Map<Id, ccrz__E_PriceListItem__c>(product.ccrz__E_PriceListItems__r);
            // PLI IDs that we find on existing Product Category records of the global Sale category
            Set<Id> plisSaleGlobal = new Set<Id>();
            // PLI IDs that we find on existing Product Category records of Sale subcategories
            Set<Id> plisSaleSub = new Set<Id>();
            // Parent category IDs we find for this Product (we only expect 1)
            Set<Id> categoryIds = new Set<Id>();

            for (ccrz__E_ProductCategory__c pcat : product.ccrz__Product_Categories__r){
                // ignore component Products - we will not touch their Categories
                if (pcat.ccrz__Category__r == null || product.AB2C_Is_Component__c) continue;
                if (pcat.ccrz__Category__r.Name.equalsIgnoreCase('Sale')){
                    if (pcat.AB2C_Price_List_Item__c != null){
                        ccrz__E_PriceListItem__c pli = pliMap.get(pcat.AB2C_Price_List_Item__c);
                        if (pli == null) continue;

                        // make note of whether this was found in the Global Sale category or another one
                        if (pcat.ccrz__Category__c == globalSaleCategoryId)
                            plisSaleGlobal.add(pli.Id);
                        else 
                            plisSaleSub.add(pli.Id);
                        // if we found a link from Product Category to a sale Price List Item
                        // ensure the dates are synced
                        if (pli.ccrz__StartDate__c != pcat.ccrz__StartDate__c || pli.ccrz__EndDate__c - 1 != pcat.ccrz__EndDate__c){
                            pcat.ccrz__StartDate__c = pli.ccrz__StartDate__c;
                            pcat.ccrz__EndDate__c = pli.ccrz__EndDate__c - 1;
                            pcToUpdate.add(pcat);
                        }
                    }
                    else {
                        // we found no link from a sale Product Category to a sale Price List Item
                        // so this Product Category shouldn't exist anymore
                        pcToDelete.add(pcat);
                    }
                } // end of "if it's a sale category" block
                else {
                    // this Product Category is not related to a Sale
                    // use it to gather category info
                    if (pcat.ccrz__Category__r.ccrz__ParentCategory__c == null || pcat.ccrz__Category__r.ccrz__ParentCategory__r.Name == rootCategoryName) categoryIds.add(pcat.ccrz__Category__c);
                    else categoryIds.add(pcat.ccrz__Category__r.ccrz__ParentCategory__c);
                }
            }// end loop over Product Category

            for (ccrz__E_PriceListItem__c pli : product.ccrz__E_PriceListItems__r){
                // does the date period include today?
                Boolean includesToday = (Date.today() >= pli.ccrz__StartDate__c && Date.today() < pli.ccrz__EndDate__c);
                // if so, ensure this Product is marked as on sale
                if (includesToday) isSale = true;
                // skip next section if it's a Component product: we will not touch the PLIs
                if (product.AB2C_Is_Component__c) continue;

                // if this sale is current or future, and not reflected in the Sale subcategory
                if (!plisSaleSub.contains(pli.Id) && Date.today() < pli.ccrz__EndDate__c){
                    for (Id categoryId : categoryIds){
                        Id saleCategoryId = saleCategoryMap.get(categoryId);
                        if (saleCategoryId == null) continue;
                        
                        ccrz__E_ProductCategory__c pcat = new ccrz__E_ProductCategory__c(
                            ccrz__Product__c = product.Id,
                            ccrz__StartDate__c = pli.ccrz__StartDate__c,
                            ccrz__EndDate__c = pli.ccrz__EndDate__c - 1,
                            ccrz__Category__c = saleCategoryId,
                            ccrz__Sequence__c = pcToInsert.size(),
                            AB2C_Price_List_Item__c = pli.Id
                        );
                        pcToInsert.add(pcat);
                    }
                }
                // if this sale is current or future, and not reflected in the global Sale category
                if (!plisSaleGlobal.contains(pli.Id) && Date.today() < pli.ccrz__EndDate__c){
                    ccrz__E_ProductCategory__c pcat = new ccrz__E_ProductCategory__c(
                        ccrz__Product__c = product.Id,
                        ccrz__StartDate__c = pli.ccrz__StartDate__c,
                        ccrz__EndDate__c = pli.ccrz__EndDate__c - 1,
                        ccrz__Category__c = globalSaleCategoryId,
                        ccrz__Sequence__c = pcToInsert.size(),
                        AB2C_Price_List_Item__c = pli.Id
                    );
                    pcToInsert.add(pcat);
                }
            }// end loop over Price List Items

            // update Service flag if needed
            // for a Component product this is the only type of DML we'll do
            if (isSale != product.ccrz__ServiceFlag__c){
                pToUpdate.add(new ccrz__E_Product__c(
                    Id = product.Id,
                    ccrz__ServiceFlag__c = isSale
                ));
            }
        }// end loop over productsQueried

        System.debug('product categories to insert:');
        System.debug(JSON.serialize(pcToInsert));
        System.debug('product categories to update:');
        System.debug(JSON.serialize(pcToUpdate));
        System.debug('product categories to delete:');
        System.debug(JSON.serialize(pcToDelete));
        System.debug('products to update:');
        System.debug(JSON.serialize(pToUpdate));

        if (!doDML) return;

        SObject[] toUpdate = new List<SObject>();
        toUpdate.addAll(pcToUpdate);
        toUpdate.addAll(pToUpdate);
        insert pcToInsert;
        update toUpdate;
        delete pcToDelete;
    }
}