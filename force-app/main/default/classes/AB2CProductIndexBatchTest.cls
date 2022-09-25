@isTest class AB2CProductIndexBatchTest {
    
    @isTest static void testBatch(){

        AB2CProductIndexBatch ab2cPIB = new AB2CProductIndexBatch();
        //ab2cPIB.execute(null);
        
         String sch = '0 0 23 * * ?';

        Test.startTest();
        Id jobId = System.schedule('AB2C Product Index Batch', sch, ab2cPIB);       
        CronTrigger cronTrigger1 = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(sch, cronTrigger1.CronExpression);

        Test.stopTest();
    }

}