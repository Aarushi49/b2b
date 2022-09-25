@isTest class AB2CProductExportBatchTest {
    
    @isTest static void testScheduler(){

        AB2CProductExportBatch batch = new AB2CProductExportBatch();
        AB2CMailchimpHttpMock mock = new AB2CMailchimpHttpMock();
        Test.setMock(HttpCalloutMock.class, mock);

        String sch = '0 0 23 * * ?';

        Test.startTest();
        Id jobId = System.schedule('AB2C Product Export Batch', sch, batch);       
        CronTrigger cronTrigger1 = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(sch, cronTrigger1.CronExpression);

        Test.stopTest();
    }
    
    @isTest static void testExportBatch(){
        AB2CProductExportBatch batch = new AB2CProductExportBatch();
        AB2CMailchimpHttpMock mock = new AB2CMailchimpHttpMock();
        Test.setMock(HttpCalloutMock.class, mock);
        Date recent = Date.today().addDays(-2);
        Date soon = Date.today().addDays(2);

        ccrz__E_PriceList__c salePriceList = new ccrz__E_PriceList__c(
            name = 'Sale Price List', ccrz__PricelistId__c = 'salePriceList',
            ccrz__StartDate__c = recent, ccrz__EndDate__c = soon,
            AB2C_Sale_Price_List__c = true
        );

        ccrz__E_Product__c compositeProduct = new ccrz__E_Product__c(
            ccrz__SKU__c = '10450-1001',
            Name = 'Cutting-Garden-Oval',
            ccrz__ShortDescRT__c = 'Short desc',
            ccrz__LongDescRT__c = 'Long desc',
            ccrz__SEOId__c = 'ccrz__SEOId__c',
            ccrz__ProductStatus__c = 'Released'
        );

        ccrz__E_Product__c componentProduct = new ccrz__E_Product__c(
            ccrz__SKU__c = '10450-1001-0450-150-Buttercup-11x14-Oval',
            Name = 'Cutting-Garden-Oval-0450-150-Buttercup-11\'4"x14\'4"-Oval',
            AB2C_Show_Square_Footage_Calculator__c = true
        );

        insert new SObject[]{salePriceList, componentProduct, compositeProduct};

        ccrz__E_CompositeProduct__c composite1 = new ccrz__E_CompositeProduct__c(
            ccrz__Component__r = new ccrz__E_Product__c(ccrz__SKU__c = componentProduct.ccrz__SKU__c),
            ccrz__Composite__r = new ccrz__E_Product__c(ccrz__SKU__c = compositeProduct.ccrz__SKU__c)
        );

        ccrz__E_PriceListItem__c priceListItem = new ccrz__E_PriceListItem__c(
            ccrz__Price__c = 1, ccrz__StartDate__c = recent, ccrz__EndDate__c = soon,
            ccrz__Pricelist__r = new ccrz__E_PriceList__c(ccrz__PricelistId__c = 'salePriceList'),
            ccrz__Product__r = new ccrz__E_Product__c(ccrz__SKU__c = componentProduct.ccrz__SKU__c)
        );
        
        insert new SObject[]{composite1, priceListItem};

        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();
    }
}