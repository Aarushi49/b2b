global with sharing class AB2CShippingHandling extends ccrz.cc_api_ShippingAndHandling{

    

    global virtual override List<ccrz.cc_ctrl_hlpr_ShippingOption> getShippingOptions(String zipCode, String stateCode, String countryCode, Id cartId, String storeName) {

        List <ccrz__E_ShippingRate__c> shippingRecords;
        shippingRecords = [
            SELECT Id, ccrz__Shipper__c, Name, ccrz__ShippingRate__c, ccrz__MinWeight__c, 
            ccrz__MaxWeight__c, ccrz__Storefront__c, 
            AB2C_Ontario__c, AB2C_GTA__c, AB2C_Rest_of_Canada__c FROM ccrz__E_ShippingRate__c
            WHERE ccrz__Storefront__c = : storeName
            
        ];

        List<ccrz.cc_ctrl_hlpr_ShippingOption> shippingOptions = new List<ccrz.cc_ctrl_hlpr_ShippingOption>();

        for (ccrz__E_ShippingRate__c record : shippingRecords) {
            String provider = record.ccrz__Shipper__c;
            String service = record.name;
            Decimal price = record.ccrz__ShippingRate__c;
            Decimal minWeight = record.ccrz__MinWeight__c;
            Decimal maxWeight = record.ccrz__MaxWeight__c;
            ccrz.cc_ctrl_hlpr_ShippingOption shippingOption;
            shippingOption = new ccrz.cc_ctrl_hlpr_ShippingOption(provider, service, price);
            shippingOptions.add(shippingOption);
        }
       
     
        return shippingOptions;
    }

}