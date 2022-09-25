@isTest  class AB2CTaxServiceTest {
    
    @isTest static void testcalculateTax(){

        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        AB2CTestData data = new AB2CTestData();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);

        ccrz__E_Cart__c cart = data.carts[0];

        ccrz.cc_bean_MockContactAddress addr = new ccrz.cc_bean_MockContactAddress();
        addr.countryCode = 'CA';
        addr.stateCode = 'ON';
        
        
        string jsonShipping = JSON.serialize(addr);
        ccrz.cc_RemoteActionResult res2 = AB2CTaxService.calculateTax(context,cart.id,jsonShipping);
        System.assert(res2.success == true, 'Success should return true');        
        Decimal calculateTax2 = (Decimal)res2.data;
        System.assert(calculateTax2 == 0, 'Success should be the same');  

    }
}