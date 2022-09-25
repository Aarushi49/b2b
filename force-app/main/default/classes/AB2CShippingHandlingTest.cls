@isTest public class AB2CShippingHandlingTest {

    @isTest static void testgetShippingOptions() {
        ccrz__E_ShippingRate__c shipOption = new ccrz__E_ShippingRate__c();
        shipOption.ccrz__Shipper__c = 'Alexanian Store';
        shipOption.ccrz__Storefront__c = 'Alexanian Store';
        shipOption.ccrz__ShippingRate__c = 10;
        shipOption.ccrz__MinWeight__c = 10;
        shipOption.ccrz__MaxWeight__c = 100;
        shipOption.name = 'Shipping';

        insert shipOption;

        AB2CShippingHandling shippingHandling = new AB2CShippingHandling();
        List<ccrz.cc_ctrl_hlpr_ShippingOption> lstOption = shippingHandling.getShippingOptions('','','',null,'Alexanian Store');

        System.Assert(lstOption.size() > 0, 'Should return shipping options');
        
    }
}