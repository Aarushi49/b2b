@isTest class AB2CLoadProductSpecIndexTest {
    @isTest static void testBatch(){
        
        AB2C_Batch_Configuration__c AB2CConfigurationA = AB2C_Batch_Configuration__c.getInstance();      
        AB2CConfigurationA.AB2C_Transfer_Spec_to_Aggregated__c = 'a2A4P000005AarlUAC;a2A4P000005AarpUAC';
        insert AB2CConfigurationA;
        
        Map<String,Object> retData =
            ccrz.ccApiTestData.setupData(new Map<String,Map<String,Object>>{
                ccrz.ccApiTestData.DATAOPTIONS => new Map<String,Object>{
                ccrz.ccApiTestData.LOADDEFAULTS => true
            }
        });


        // setup method created some sample categories for us, so we will use some of them
        Map<String,Object> catData = (Map<String,Object>)retData.get(ccrz.ccApiTestData.CATEGORY_DATA);
        List<sObject> catList = (List<sObject>)catData.get(ccrz.ccApiTestData.CATEGORY_LIST);
        
        ccrz__E_Category__c cat1 = (ccrz__E_Category__c)catList.get(0);

        ccrz__E_Product__c prod1 = new ccrz__E_Product__c(
            Name = 'foo', ccrz__SKU__c = 'prod1'
        );
        ccrz__E_Product__c prod2 = new ccrz__E_Product__c(
            Name = 'bar', ccrz__SKU__c = 'prod2'
        );

        ccrz__E_Spec__c spec1 = new ccrz__E_Spec__c(
            Name = 'Material', ccrz__FilterType__c = 'Checkbox', ccrz__Locale__c = 'en_US',
            ccrz__SpecID__c = 'spec1'
        );
        ccrz__E_Spec__c spec2 = new ccrz__E_Spec__c(
            Name = 'Width', ccrz__FilterType__c = 'Slider', ccrz__Locale__c = 'en_US',
            ccrz__SpecID__c = 'spec2'
        );
        ccrz__E_Spec__c spec3 = new ccrz__E_Spec__c(
            Name = 'Style', ccrz__FilterType__c = 'Checkbox', ccrz__Locale__c = 'en_US',
            ccrz__SpecID__c = 'spec3'
        );
        ccrz__E_Spec__c spec4 = new ccrz__E_Spec__c(
            Name = 'Price', ccrz__FilterType__c = 'Slider', ccrz__Locale__c = 'en_US',
            ccrz__SpecID__c = 'spec4'
        );

        ccrz__E_ProductSpec__c pSpec1 = new ccrz__E_ProductSpec__c(
            ccrz__Product__r = new ccrz__E_Product__c(ccrz__SKU__c = 'prod1'),
            ccrz__Spec__r = new ccrz__E_Spec__c(ccrz__SpecID__c = 'spec1'),
            ccrz__SpecValue__c = 'Rayon'
        );
        ccrz__E_ProductSpec__c pSpec2 = new ccrz__E_ProductSpec__c(
            ccrz__Product__r = new ccrz__E_Product__c(ccrz__SKU__c = 'prod2'),
            ccrz__Spec__r = new ccrz__E_Spec__c(ccrz__SpecID__c = 'spec2'),
            ccrz__SpecValue__c = '20'
        );

        ccrz__E_CategorySpec__c cSpec1 = new ccrz__E_CategorySpec__c(
            ccrz__Category__c = cat1.Id, ccrz__SpecValue__c = 'Ornate',
            ccrz__Spec__r = new ccrz__E_Spec__c(ccrz__SpecID__c = 'spec3')
        );

        ccrz__E_CategorySpec__c cSpec2 = new ccrz__E_CategorySpec__c(
            ccrz__Category__c = cat1.Id, ccrz__SpecValue__c = '50',
            ccrz__Spec__r = new ccrz__E_Spec__c(ccrz__SpecID__c = 'spec2')
        );

        ccrz__E_CategorySpec__c cSpec3 = new ccrz__E_CategorySpec__c(
            ccrz__Category__c = cat1.Id, ccrz__SpecValue__c = '75',
            ccrz__Spec__r = new ccrz__E_Spec__c(ccrz__SpecID__c = 'spec2')
        );
        

        ccrz__E_ProductCategory__c prodCat1 = new ccrz__E_ProductCategory__c(
            ccrz__Product__r = new ccrz__E_Product__c(ccrz__SKU__c = 'prod1'),
            ccrz__Category__c = cat1.Id
        );

        ccrz__E_CompositeProduct__c comp1 = new ccrz__E_CompositeProduct__c(
            ccrz__Component__r = new ccrz__E_Product__c(ccrz__SKU__c = 'prod2'), // the child product
            ccrz__Composite__r = new ccrz__E_Product__c(ccrz__SKU__c = 'prod1') // the parent product
        );

        // create one existing record so that the delete code is covered
        ccrz__E_ProductSpecIndex__c pSpecIndex1 = new ccrz__E_ProductSpecIndex__c(
            ccrz__Product__r = new ccrz__E_Product__c(ccrz__SKU__c = 'prod1'),
            ccrz__Spec__r = new ccrz__E_Spec__c(ccrz__SpecID__c = 'spec2'),
            ccrz__SpecValue__c = '1', ccrz__ProductSpecIndexId__c = 'unimportant'
        );

        Map<String,Object> plData = (Map<String,Object>)retData.get(ccrz.ccApiTestData.PRICELIST_DATA);
        ccrz__E_Pricelist__c[] priceLists = (List<ccrz__E_Pricelist__c>)plData.get(ccrz.ccApiTestData.PRICELIST_LIST);

        ccrz__E_PriceListItem__c pli1 = new ccrz__E_PriceListItem__c(
            ccrz__Price__c = 1, ccrz__Pricelist__c = priceLists[0].Id,
            ccrz__Product__r = new ccrz__E_Product__c(ccrz__SKU__c = 'prod1'),
            ccrz__StartDate__c = Date.today() - 1,
            ccrz__EndDate__c = Date.today().addYears(10)
        );

        insert new SObject[]{
            prod1, prod2, 
            spec1, spec2, spec3,
            pSpec1, pSpec2,
            cSpec1, cSpec2, cSpec3,spec4,
            prodCat1, 
            comp1,
            pSpecIndex1,
            pli1
        };

        

        AB2C_Batch_Configuration__c customShippingParameter = new AB2C_Batch_Configuration__c(
            AB2C_Spec_Price_ID__c = spec4.id            
        );
        insert customShippingParameter;

        // Also fill in the direct child-parent lookup, which we can't do in the same DML transaction
        prod2.ccrz__ParentProduct__c = prod1.Id;
        update prod2;

        AB2CLoadProductSpecIndex batchInstance = new AB2CLoadProductSpecIndex(
            'SELECT Id, Name, ccrz__ParentProduct__c, ccrz__FilterData__c, ccrz__ProductType__c FROM ccrz__E_Product__c'
        );
        Test.startTest();
        Id batchId = Database.executeBatch(batchInstance);
        Test.stopTest();

        ccrz__E_ProductSpecIndex__c[] indices = [
            SELECT Name, ccrz__Product__c, ccrz__Product__r.Name,
            ccrz__Spec__c, ccrz__Spec__r.Name,
            ccrz__SpecValue__c, ccrz__ProductSpecIndexId__c
            FROM ccrz__E_ProductSpecIndex__c
        ];

        System.debug(JSON.serialize(indices));

        Map<String, ccrz__E_ProductSpecIndex__c> results = new Map<String, ccrz__E_ProductSpecIndex__c>();
        for (ccrz__E_ProductSpecIndex__c index : indices){
            String key = '' + index.ccrz__Product__c + index.ccrz__Spec__c + index.ccrz__SpecValue__c;
            results.put(key, index);
        }

        // prod1 should have spec3 value 'Ornate'
       /* System.assert(results.containsKey('' + prod1.Id + spec3.Id + 'Ornate'));
        // prod1 should have spec2 value '000000000000000075'
        System.assert(results.containsKey('' + prod1.Id + spec2.Id + '000000000000000075'));
        // prod1 should have spec1 value 'Rayon'
        System.assert(results.containsKey('' + prod1.Id + spec1.Id + 'Rayon'));
        // prod1 should have spec2 value '000000000000000020'
        System.assert(results.containsKey('' + prod1.Id + spec2.Id + '000000000000000020'));
        // prod2 should have spec1 value 'Rayon'
        System.assert(results.containsKey('' + prod2.Id + spec1.Id + 'Rayon'));
        // prod2 should have spec2 value '000000000000000020'
        System.assert(results.containsKey('' + prod2.Id + spec2.Id + '000000000000000020'));*/

        // the original ccrz__E_ProductSpecIndex__c we inserted should be deleted
        System.assertEquals(1, ([
            SELECT Id FROM ccrz__E_ProductSpecIndex__c
            WHERE Id = :pSpecIndex1.Id AND isDeleted = TRUE
            ALL ROWS
        ]).size());

        // Also test out empty cases for sub-methods 
        Map<String,List<ccrz__E_ProductSpec__c>> emptyProductSpecs = batchInstance.getProductSpec(null);
        Map<String,List<ccrz__E_CategorySpec__c>> emptyCategorySpecs = AB2CLoadProductSpecIndex.getCategorySpecValues(new Set<String>());
        Boolean test = batchInstance.transferCompositeSpecstoAggregated(new List<string>(), new Map<String,List<ccrz__E_ProductSpec__c>>());
        System.assert(emptyProductSpecs.isEmpty());
        System.assert(emptyCategorySpecs.isEmpty());
    }
}