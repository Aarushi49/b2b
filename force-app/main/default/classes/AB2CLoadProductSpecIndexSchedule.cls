global class AB2CLoadProductSpecIndexSchedule implements Schedulable {
    /**
     * Schedule loading the product spec indexes 
     */
    global void execute(SchedulableContext ctx) {
        AB2C_Batch_Configuration__c AB2CConfiguration = AB2C_Batch_Configuration__c.getInstance();      

        AB2CLoadProductSpecIndex lpsi = new AB2CLoadProductSpecIndex('Select Id, Name,ccrz__ParentProduct__c, ccrz__FilterData__c,ccrz__ProductType__c from ccrz__E_Product__c where id =\'a1i8G000000SBLU\'');
        Database.executebatch(lpsi,(Integer)AB2CConfiguration.AB2C_Batch_Size__c);
    }
}