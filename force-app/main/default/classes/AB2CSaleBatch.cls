public without sharing class AB2CSaleBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
    public AB2CSaleBatch() {

    }
    public Boolean doDML = true;

    public Database.QueryLocator start(Database.BatchableContext BC){
        // only get child categories related to sales
        // and child PLIs related to sales
        return Database.getQueryLocator([
            SELECT Id, ccrz__ServiceFlag__c,
            (SELECT Id
            FROM ccrz__Product_Categories__r
            WHERE ccrz__Category__r.Name = 'Sale'),
            (SELECT Id
            FROM ccrz__E_PriceListItems__r
            WHERE AB2C_Is_Sale__c = true)
            FROM ccrz__E_Product__c
            ORDER BY Name
        ]);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope){
        List<ccrz__E_Product__c> scopeProducts = (List<ccrz__E_Product__c>)scope;
        List<ccrz__E_Product__c> saleProducts = new List<ccrz__E_Product__c>();

        // filter the scope down to only Products that are on sale
        // or were, and need cleanup
        for (ccrz__E_Product__c product : scopeProducts){
            if (product.ccrz__ServiceFlag__c 
            || !product.ccrz__Product_Categories__r.isEmpty() 
            || !product.ccrz__E_PriceListItems__r.isEmpty()){
                saleProducts.add(product);
            }
        }
        AB2CSaleService.doDML = doDML;
        AB2CSaleService.processSales(saleProducts);
    }

    public void finish(Database.BatchableContext BC){

    }

    public void execute(SchedulableContext SC){
        Database.executeBatch(this);
    }

}