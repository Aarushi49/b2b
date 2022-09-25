@isTest class AB2CStaticContentControllerTest {
    @isTest static void testGetStaticContent(){
        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        AB2CTestData data = new AB2CTestData();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);

        ccrz__E_RichContent__c rich = new ccrz__E_RichContent__c(
            Name = 'rich', MenuId__c = 'richMenu',
            ccrz__ContentKey__c = 'richKey',
            ccrz__EffectiveStart__c = Datetime.now().addDays(-1),
            ccrz__EffectiveEnd__c = Datetime.now().addYears(1),
            ccrz__Status__c = 'Published',
            ccrz__Content__c = 'If I were a rich text',
            ccrz__Storefront__c = 'DefaultStore'
        );
        insert rich;

        ccrz.cc_RemoteActionResult response = AB2CStaticContentController.getStaticContent(context, 'richKey');
        Map<String, Object> rData = (Map<String, Object>)response.data;
        String menuId = (String)rData.get('menuId');
        List<Map<String, Object>> contentList = (List<Map<String, Object>>)rData.get('contentList');

        System.assertEquals(rich.MenuId__c, menuId);
        System.assertEquals(1, contentList.size());
        System.assertEquals(rich.ccrz__Content__c, (String)contentList[0].get('content'));
        AB2CStaticContentController.mockException = new DmlException('whoops');
        response = AB2CStaticContentController.getStaticContent(context, 'richKey');
        System.assert(!response.success);
        System.assert(response.data instanceof String);   
    }

    @isTest static void testSubmitForm(){
        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        AB2CTestData data = new AB2CTestData();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);
        
        insert new ccrz__E_Configuration__c(
            Name = 'AlexanianStore.all.mailchimp.email.form.submission',
            ccrz__TextValue__c = 'test@example.com'
        );

        // happy path: We find what we need and can send the email
        ccrz.cc_RemoteActionResult response = AB2CStaticContentController.submitForm(
            context, 'formName', 'foo=bar&boo=far&key=value'
        );
        System.assert(response.success);

        // unhappy path: Bad data shouldn't throw exception but be handled gracefully
        response = AB2CStaticContentController.submitForm(
            context, 'formName', 'foo&boo&key'
        );
        System.assert(response.success);
    }

    @isTest static void testSubmitFormNoEmail(){
        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        AB2CTestData data = new AB2CTestData();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);
        
        // omit inserting config so that it finds null email receipient

        // unhappy path: send email fails
        ccrz.cc_RemoteActionResult response = AB2CStaticContentController.submitForm(
            context, 'formName', 'foo=bar&boo=far&key=value'
        );
        System.debug(JSON.serialize(response));
        System.assert(!response.success);
        System.assert(response.data instanceof String);  
    }    
}