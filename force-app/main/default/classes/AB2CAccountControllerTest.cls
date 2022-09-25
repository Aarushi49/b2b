@isTest class AB2CAccountControllerTest {
    @isTest static void testGetMailchimpSubscriptionStatus(){
        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);
        
        // happy path: response has code 200 and status = 'mock'
        AB2CMailchimpHttpMock mock = new AB2CMailchimpHttpMock();
        Test.setMock(HttpCalloutMock.class, mock);

        ccrz.cc_RemoteActionResult response = AB2CAccountController.getMailchimpSubscriptionStatus(context, 'foo@bar.com');
        Object responseData = response.data;
        Map<String, Object> responseMap = (Map<String, Object>)response.data;
        String status = (String)responseMap.get('status');
        System.assertEquals('mock', status);
        System.assert(response.success);

        // unhappy path: malformed JSON, doesn't deserialize, try falls through to catch
        mock.rawResponse = '["bad JSON';
        response = AB2CAccountController.getMailchimpSubscriptionStatus(context, 'foo@bar.com');
        System.assert(!response.success);
    }

    @isTest static void testSetMailchimpSubscriptionStatus(){
        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);
        
        // happy path 1: response has code 200 and status = 'mock'
        // 200 means MailChimp found the email
        AB2CMailchimpHttpMock mock = new AB2CMailchimpHttpMock();
        Test.setMock(HttpCalloutMock.class, mock);

        ccrz.cc_RemoteActionResult response = AB2CAccountController.setMailchimpSubscriptionStatus(context, 'foo@bar.com', true);
        Object responseData = response.data;
        Map<String, Object> responseMap = (Map<String, Object>)response.data;
        String status = (String)responseMap.get('status');        
        System.assertEquals('mock', status);
        System.assert(response.success);

        // happy path 2: response to PATCH call has code 404 and status = 'mock'
        // 404 means MailChimp didn't find the email
        // but then the next call is a POST which should return a 200 unless API problems
        mock.statusCode = 404;
        mock.nextCode = 200;
        response = AB2CAccountController.setMailchimpSubscriptionStatus(context, 'foo@bar.com', true);
        responseData = response.data;
        responseMap = (Map<String, Object>)response.data;
        status = (String)responseMap.get('status');
        System.assertEquals('mock', status);
        System.assert(response.success);
        
        // unhappy path: API returns bad data and we return success false
        mock.rawResponse = '["bad JSON';
        response = AB2CAccountController.setMailchimpSubscriptionStatus(context, 'foo@bar.com', true);
        System.assert(!response.success);
        
    }

    @isTest static void testGetStoredPayments() {
        AB2CTestData data = new AB2CTestData();
        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        context.storefront = 'AlexanianStore';
        context.userIsoCode = 'USD';
        context.effAccountId = data.accounts[0].Id;
        ccrz.cc_CallContext.initRemoteContext(context);

        ccrz__E_StoredPayment__c testPayment = new ccrz__E_StoredPayment__c (
            ccrz__Account__c = ccrz.cc_CallContext.effAccountId,
            ccrz__Storefront__c = 'AlexanianStore'
        );

        insert testPayment;

        ccrz.cc_RemoteActionResult result = AB2CAccountController.getStoredPayments(context);

        system.assert(result.data != false, 'stored payment should be found');
    }

    @isTest static void testSetDefaultStoredPayment() {
        AB2CTestData data = new AB2CTestData();
        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        context.storefront = 'AlexanianStore';
        context.userIsoCode = 'USD';
        context.effAccountId = data.accounts[0].Id;
        ccrz.cc_CallContext.initRemoteContext(context);

        String testAccountNum = '123';
        ccrz__E_StoredPayment__c testPayment = new ccrz__E_StoredPayment__c (
            ccrz__Account__c = ccrz.cc_CallContext.effAccountId,
            ccrz__Storefront__c = 'AlexanianStore',
            ccrz__AccountNumber__c = testAccountNum
        );
        ccrz__E_StoredPayment__c testPayment2 = new ccrz__E_StoredPayment__c (
            ccrz__Account__c = ccrz.cc_CallContext.effAccountId,
            ccrz__Storefront__c = 'AlexanianStore',
            ccrz__AccountNumber__c = '555'
        );

        insert new SObject[]{testPayment, testPayment2};
        
        ccrz.cc_RemoteActionResult result = AB2CAccountController.setDefaultStoredPayment(context, testAccountNum, true);

        system.assert(result.success, 'success should be true');
        ccrz__E_StoredPayment__c resultPayment = [
            SELECT Id, ccrz__Default__c 
            FROM ccrz__E_StoredPayment__c 
            WHERE Id =: testPayment.Id
        ];
        system.assert(resultPayment.ccrz__Default__c, 'default should be set to true');
    }
}