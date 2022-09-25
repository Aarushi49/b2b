@isTest class AB2CUserInterfaceTest {
    @isTest static void testUI(){
        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        AB2CTestData data = new AB2CTestData();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);
        
        AB2CUserInterface ui = new AB2CUserInterface();
        
        PageReference pr = new PageReference('/ccrz__ProductList');
        Test.setCurrentPage(pr);
        String std = ui.standardIncludes();

        pr = new PageReference('/ccrz__MyAccount?pagekey=static');
        Test.setCurrentPage(pr);
        std = ui.standardIncludes();

        pr = new PageReference('/ccrz__MyAccount');
        Test.setCurrentPage(pr);
        std = ui.standardIncludes();

        pr = new PageReference('/ccrz__SellerListPage');
        Test.setCurrentPage(pr);
        std = ui.standardIncludes();

        pr = new PageReference('/ccrz__CCSiteRegister');
        Test.setCurrentPage(pr);
        std = ui.standardIncludes();   

        pr = new PageReference('/ccrz__CheckoutNew');
        Test.setCurrentPage(pr);
        std = ui.standardIncludes();   

        pr = new PageReference('/ccrz__Cart');
        Test.setCurrentPage(pr);
        std = ui.standardIncludes();                        

        Map<String, Object> endMap = ui.endContent(new Map<String, Object>());
        Map<String, Object> headMap = ui.headContent(new Map<String, Object>());

        // not very meaningful to assert here as we're getting markup back
        // this is a quirk of CloudCraze's design, asking us to write code that returns markup

        String endString = (String)endMap.get(ccrz.cc_hk_UserInterface.EOB_CONTENT);
        String headString = (String)headMap.get(ccrz.cc_hk_UserInterface.HEAD_CONTENT);

        
        System.assertNotEquals(null, endString);
        System.assertNotEquals(null, headString);
        
    }
}