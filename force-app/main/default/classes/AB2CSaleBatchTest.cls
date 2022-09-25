@isTest class AB2CSaleBatchTest {
    @isTest static void testSaleBatch(){
        Date longAgo = Date.today().addDays(-100);
        Date recent = Date.today().addDays(-2);
        Date soon = Date.today().addDays(2);
        Date farFuture = Date.today().addDays(100);

        ccrz__E_Category__c globalSale = new ccrz__E_Category__c(
            Name = 'Sale', ccrz__CategoryID__c = 'globalSale',
            ccrz__StartDate__c = longAgo, ccrz__EndDate__c = farFuture
        );
        ccrz__E_Category__c areaRugs = new ccrz__E_Category__c(
            Name = 'Area Rugs', ccrz__CategoryID__c = 'areaRugs',
            ccrz__StartDate__c = longAgo, ccrz__EndDate__c = farFuture
        );
        ccrz__E_Category__c cuteAreaRugs = new ccrz__E_Category__c(
            name = 'Cute Area Rugs', ccrz__CategoryID__c = 'cuteAreaRugs',
            ccrz__StartDate__c = longAgo, ccrz__EndDate__c = farFuture
        );
        ccrz__E_Category__c saleAreaRugs = new ccrz__E_Category__c(
            name = 'Sale', ccrz__CategoryID__c = 'saleAreaRugs',
            ccrz__StartDate__c = longAgo, ccrz__EndDate__c = farFuture
        );

        ccrz__E_PriceList__c salePriceList = new ccrz__E_PriceList__c(
            name = 'Sale Price List', ccrz__PricelistId__c = 'salePriceList', 
            AB2C_Sale_Price_List__c = true,
            ccrz__StartDate__c = longAgo, ccrz__EndDate__c = farFuture
        );

        // A Product with ServiceFlag = true that has no sale PLIs and is in both sale categories
        ccrz__E_Product__c productNoLongerOnSale = new ccrz__E_Product__c(
            Name = 'productNoLongerOnSale', ccrz__SKU__c = 'productNoLongerOnSale',
            ccrz__ServiceFlag__c = true, AB2C_Is_Component__c = false
        );
        ccrz__E_ProductCategory__c pcatNoLongerOnSaleRug = new ccrz__E_ProductCategory__c(
            ccrz__Product__r = new ccrz__E_Product__c(ccrz__SKU__c = 'productNoLongerOnSale'),
            ccrz__Category__r = new ccrz__E_Category__c(ccrz__CategoryID__c = 'areaRugs'),
            ccrz__StartDate__c = longAgo, ccrz__EndDate__c = farFuture
        );
        ccrz__E_ProductCategory__c pcatNoLongerOnSaleCuteRug = new ccrz__E_ProductCategory__c(
            ccrz__Product__r = new ccrz__E_Product__c(ccrz__SKU__c = 'productNoLongerOnSale'),
            ccrz__Category__r = new ccrz__E_Category__c(ccrz__CategoryID__c = 'cuteAreaRugs'),
            ccrz__StartDate__c = longAgo, ccrz__EndDate__c = farFuture
        );
        ccrz__E_ProductCategory__c pcatNoLongerOnSaleGlobalSale = new ccrz__E_ProductCategory__c(
            ccrz__Product__r = new ccrz__E_Product__c(ccrz__SKU__c = 'productNoLongerOnSale'),
            ccrz__Category__r = new ccrz__E_Category__c(ccrz__CategoryID__c = 'globalSale'),
            ccrz__StartDate__c = longAgo, ccrz__EndDate__c = farFuture
        );
        ccrz__E_ProductCategory__c pcatNoLongerOnSaleRugSale = new ccrz__E_ProductCategory__c(
            ccrz__Product__r = new ccrz__E_Product__c(ccrz__SKU__c = 'productNoLongerOnSale'),
            ccrz__Category__r = new ccrz__E_Category__c(ccrz__CategoryID__c = 'saleAreaRugs'),
            ccrz__StartDate__c = longAgo, ccrz__EndDate__c = farFuture
        );

        // A Product with ServiceFlag = false that has current sale PLI and no sale categories
        ccrz__E_Product__c productNewlyOnSale = new ccrz__E_Product__c(
            Name = 'productNewlyOnSale', ccrz__SKU__c = 'productNewlyOnSale',
            ccrz__ServiceFlag__c = false, AB2C_Is_Component__c = false
        );
        ccrz__E_ProductCategory__c pcatNewlyOnSaleRug = new ccrz__E_ProductCategory__c(
            ccrz__Product__r = new ccrz__E_Product__c(ccrz__SKU__c = 'productNewlyOnSale'),
            ccrz__Category__r = new ccrz__E_Category__c(ccrz__CategoryID__c = 'areaRugs'),
            ccrz__StartDate__c = longAgo, ccrz__EndDate__c = farFuture
        );
        ccrz__E_ProductCategory__c pcatNewlyOnSaleCuteRug = new ccrz__E_ProductCategory__c(
            ccrz__Product__r = new ccrz__E_Product__c(ccrz__SKU__c = 'productNewlyOnSale'),
            ccrz__Category__r = new ccrz__E_Category__c(ccrz__CategoryID__c = 'cuteAreaRugs'),
            ccrz__StartDate__c = longAgo, ccrz__EndDate__c = farFuture
        );
        ccrz__E_PriceListItem__c pitemNewlyOnSale = new ccrz__E_PriceListItem__c(
            ccrz__Price__c = 1, ccrz__StartDate__c = recent, ccrz__EndDate__c = soon,
            ccrz__Pricelist__r = new ccrz__E_PriceList__c(ccrz__PricelistId__c = 'salePriceList'),
            ccrz__Product__r = new ccrz__E_Product__c(ccrz__SKU__c = 'productNewlyOnSale')
        );

        // A Product with ServiceFlag = true that has current sale PLIs and both sale categories, and the PC->PLI lookups intact, but dates are wrong
        ccrz__E_Product__c productSaleChanged = new ccrz__E_Product__c(
            Name = 'productSaleChanged', ccrz__SKU__c = 'productSaleChanged',
            ccrz__ServiceFlag__c = false, AB2C_Is_Component__c = false
        );
        ccrz__E_PriceListItem__c pitemSaleChanged = new ccrz__E_PriceListItem__c(
            ccrz__Price__c = 1, ccrz__StartDate__c = recent, ccrz__EndDate__c = farFuture,
            ccrz__Pricelist__r = new ccrz__E_PriceList__c(ccrz__PricelistId__c = 'salePriceList'),
            ccrz__Product__r = new ccrz__E_Product__c(ccrz__SKU__c = 'productSaleChanged'),
            ccrz__PricelistItemId__c = 'pitemSaleChanged'
        );
        ccrz__E_ProductCategory__c pcatSaleChangedRug = new ccrz__E_ProductCategory__c(
            ccrz__Product__r = new ccrz__E_Product__c(ccrz__SKU__c = 'productSaleChanged'),
            ccrz__Category__r = new ccrz__E_Category__c(ccrz__CategoryID__c = 'areaRugs'),
            ccrz__StartDate__c = longAgo, ccrz__EndDate__c = farFuture
        );
        ccrz__E_ProductCategory__c pcatSaleChangedCuteRug = new ccrz__E_ProductCategory__c(
            ccrz__Product__r = new ccrz__E_Product__c(ccrz__SKU__c = 'productSaleChanged'),
            ccrz__Category__r = new ccrz__E_Category__c(ccrz__CategoryID__c = 'cuteAreaRugs'),
            ccrz__StartDate__c = longAgo, ccrz__EndDate__c = farFuture
        );
        ccrz__E_ProductCategory__c pcatSaleChangedGlobalSale = new ccrz__E_ProductCategory__c(
            ccrz__Product__r = new ccrz__E_Product__c(ccrz__SKU__c = 'productSaleChanged'),
            ccrz__Category__r = new ccrz__E_Category__c(ccrz__CategoryID__c = 'globalSale'),
            ccrz__StartDate__c = recent, ccrz__EndDate__c = soon,
            AB2C_Price_List_Item__r = new ccrz__E_PriceListItem__c(ccrz__PricelistItemId__c = 'pitemSaleChanged')
        );
        ccrz__E_ProductCategory__c pcatSaleChangedRugSale = new ccrz__E_ProductCategory__c(
            ccrz__Product__r = new ccrz__E_Product__c(ccrz__SKU__c = 'productSaleChanged'),
            ccrz__Category__r = new ccrz__E_Category__c(ccrz__CategoryID__c = 'saleAreaRugs'),
            ccrz__StartDate__c = recent, ccrz__EndDate__c = soon,
            AB2C_Price_List_Item__r = new ccrz__E_PriceListItem__c(ccrz__PricelistItemId__c = 'pitemSaleChanged')
        );        


        insert new SObject[]{
            globalSale, areaRugs, cuteAreaRugs, saleAreaRugs
            ,salePriceList
            ,productNoLongerOnSale, productNewlyOnSale, productSaleChanged
            ,pitemNewlyOnSale, pitemSaleChanged     
            ,pcatNoLongerOnSaleRug, pcatNoLongerOnSaleCuteRug, pcatNoLongerOnSaleGlobalSale,pcatNoLongerOnSaleRugSale
            ,pcatNewlyOnSaleRug, pcatNewlyOnSaleCuteRug
            ,pcatSaleChangedRug, pcatSaleChangedCuteRug, pcatSaleChangedGlobalSale, pcatSaleChangedRugSale
        };

        cuteAreaRugs.ccrz__ParentCategory__c = areaRugs.Id;
        saleAreaRugs.ccrz__ParentCategory__c = areaRugs.Id;

        update new SObject[]{
            cuteAreaRugs, saleAreaRugs
        };

        // AB2CSaleService.processSales(new List<ccrz__E_Product__c>{
        //     productNoLongerOnSale, productNewlyOnSale, productSaleChanged
        // });

        AB2CSaleBatch batch = new AB2CSaleBatch();
        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();

        Map<Id, ccrz__E_Product__c> queryMap = new Map<Id, ccrz__E_Product__c>([
            SELECT Id, ccrz__ServiceFlag__c, 
            (SELECT Id, ccrz__StartDate__c, ccrz__EndDate__c, 
            AB2C_Price_List_Item__c, ccrz__Category__c
            FROM ccrz__Product_Categories__r
            WHERE ccrz__Category__r.Name = 'Sale')
            FROM ccrz__E_Product__c
            WHERE AB2C_Is_Component__c = false
        ]);
        
        // productNoLongerOnSale should have ServiceFlag = false and no Sale categories
        ccrz__E_Product__c qproductNoLongerOnSale = queryMap.get(productNoLongerOnSale.Id);
        System.assert(!qproductNoLongerOnSale.ccrz__ServiceFlag__c);
        System.assert(qproductNoLongerOnSale.ccrz__Product_Categories__r.isEmpty());
        
        // productNewlyOnSale should have ServiceFlag = true and two Sale categories linking back to the PLIs
        ccrz__E_Product__c qproductNewlyOnSale = queryMap.get(productNewlyOnSale.Id);
        System.assert(qproductNewlyOnSale.ccrz__ServiceFlag__c);
        System.assertEquals(2, qproductNewlyOnSale.ccrz__Product_Categories__r.size());
        ccrz__E_ProductCategory__c pCatSale, pCatGlobalSale;
        for (ccrz__E_ProductCategory__c pCat : qproductNewlyOnSale.ccrz__Product_Categories__r){
            if (pCat.ccrz__Category__c == globalSale.Id) pCatGlobalSale = pCat;
            if (pCat.ccrz__Category__c == saleAreaRugs.Id) pCatSale = pCat;
        }
        System.assertNotEquals(null, pCatSale);
        System.assertNotEquals(null, pCatGlobalSale);
        System.assertEquals(pitemNewlyOnSale.Id, pCatSale.AB2C_Price_List_Item__c);
        System.assertEquals(pitemNewlyOnSale.Id, pCatGlobalSale.AB2C_Price_List_Item__c);

        // productSaleChanged should have the same two Sale categories but now dates align to its PLI (matching Start date, End date is 1 less)
        ccrz__E_Product__c qproductSaleChanged = queryMap.get(productSaleChanged.Id);
        System.assertEquals(2, qproductSaleChanged.ccrz__Product_Categories__r.size());
        Map<Id,ccrz__E_ProductCategory__c> pCatMap = new Map<Id,ccrz__E_ProductCategory__c>(
            qproductSaleChanged.ccrz__Product_Categories__r
        );
        pCatSale = pCatMap.get(pcatSaleChangedRugSale.Id);
        System.assertNotEquals(null, pCatSale);
        System.assertEquals(recent, pCatSale.ccrz__StartDate__c);
        System.assertEquals(farFuture-1, pCatSale.ccrz__EndDate__c);
        pCatGlobalSale = pCatMap.get(pcatSaleChangedGlobalSale.Id);
        System.assertNotEquals(null, pCatGlobalSale);
        System.assertEquals(recent, pCatGlobalSale.ccrz__StartDate__c);
        System.assertEquals(farFuture-1, pCatGlobalSale.ccrz__EndDate__c);
        
    }

    @isTest static void testScheduler(){
        AB2CSaleBatch batch = new AB2CSaleBatch();
        Test.startTest();
        System.schedule('test', '0 0 23 * * ?', batch);
        Test.stopTest();

        List<AsyncApexJob> jobsScheduled = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob where JobType = 'ScheduledApex'];
        System.assertEquals(1, jobsScheduled.size(), 'expecting one scheduled job');
        System.assertEquals('AB2CSaleBatch', jobsScheduled[0].ApexClass.Name, 'expecting specific scheduled job');
    }
}