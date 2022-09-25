@isTest class AB2CSellerControllerTest {
    @isTest static void testSearch(){
        AB2CSellerController ctlr = new AB2CSellerController();

        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        AB2CTestData data = new AB2CTestData();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);

        ccrz__E_Seller__c seller = new ccrz__E_Seller__c(
            Name = 'Toronto Central',
            AB2C_City__c = 'Toronto',
            ccrz__EffectiveStart__c = DateTime.now().addDays(-10),
            ccrz__EffectiveEnd__c = DateTime.now().addYears(5),
            ccrz__Enabled__c = true,
            ccrz__Location__Latitude__s = 43.7184038,
            ccrz__Location__Longitude__s = -79.5181407,
            ccrz__Storefront__c = 'DefaultStore',
            AB2C_Address__c = '123 Millwood',
            AB2C_Phone__c = '416-555-1212',
            AB2C_Postal_Code__c = 'N0N 0N0'
        );
        insert seller;
        
        ccrz.cc_RemoteActionResult response = AB2CSellerController.searchSellersByRadius(context, seller.ccrz__Location__Latitude__s, seller.ccrz__Location__Longitude__s, 6400);

        Map<String, Object> rData = (Map<String, Object>)response.data;
        Set<String> cities = (Set<String>)rData.get('cities');
        System.assert(cities.contains(seller.AB2C_City__c));
        
        List<Map<String, Object>> sellerList = (List<Map<String, Object>>) rData.get(ccrz.ccAPISeller.SELLERLIST);
        String name = (String)sellerList[0].get('sfdcName');
        System.assertEquals(seller.Name, name);     

        AB2CSellerController.mockException = new DmlException('whoops');
        response = AB2CSellerController.searchSellersByRadius(context, seller.ccrz__Location__Latitude__s, seller.ccrz__Location__Longitude__s, 6400);
        System.assert(!response.success);

    }
}