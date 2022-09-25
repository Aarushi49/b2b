@isTest class AB2CAccountCreateControllerTest {
    static Map<String, Object> getSampleInputs(){
        return new Map<String, Object>{
            'confirmpassword'=> 'pass123!!A',
            'password'=> 'pass123!!A',
            'description'=> 'Description',
            'salutation'=> 'Mr',
            'firstName'=> 'DFirstName',
            'lastName'=> 'DLastName',
            'primaryPhone'=> '4448884444',
            'language'=> 'en_US',
            'currencyCode'=> 'CAD',
            'companyName'=> 'DcompanyName',
            'companyType'=> 'ISP',
            'taxExemptFlag'=> true,
            'customField1'=> '',
            'customField2'=> '',
            'username'=> 'k@k.com',
            'Department'=> 'IT',
            'shippingAddress'=> new Map<String, Object>{
                'address1'=> '2 Peachtree',
                'city'=> 'Atlanta',
                'state'=> 'Georgia',
                'postalCode'=> '30303',
                'country'=> 'United States',
                'countryCode'=> ''
            },
            'billingAddress'=> new Map<String, Object>{
                'country'=> 'United States',
                'countryCode'=> '',
                'address1'=> '2 Peachtree',
                'city'=> 'Atlanta',
                'state'=> 'Georgia',
                'postalCode'=> '30303'
            }
        };
    }

    @isTest static void testSubmitForm(){
        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        AB2CTestData data = new AB2CTestData();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);

        Map<String, Object> form = getSampleInputs();
        String hashString = '10' + String.valueOf(Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS'));
        Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(hashString));
        String hexDigest = EncodingUtil.convertToHex(hash);
        form.put('companyName',  hexDigest );
        form.put('firstName', hexDigest );
        form.put('lastName',  hexDigest );
        form.put('username',  hexDigest +'@a.com.partial');

        // NOTE: need to refactor Controller before MailChimp call works properly
        // mock out MailChimp API call
        // AB2CMailchimpHttpMock mock = new AB2CMailchimpHttpMock();
        // Test.setMock(HttpCalloutMock.class, mock);
        // form.put('signUpforNewsLetter', 'true');
        
        String formString = JSON.serialize(form);

        ccrz.cc_RemoteActionResult result = AB2CAccountCreateController.submitForm(context, formString);

        Account[] accts = [
            SELECT Id,Name
            ,(SELECT Id,FirstName,LastName FROM Contacts)
            ,(SELECT Id,FirstName,LastName FROM Users)
            FROM Account WHERE Name = :hexDigest
        ];
       
        System.assertEquals(1, accts.size());
        System.assertEquals(1, accts[0].Contacts.size());
        System.assertEquals(0, accts[0].Users.size()); // because site.createExternalUser does not work in unit tests

        // provoke exception in main block
        AB2CAccountCreateController.mainException = new DmlException('whoops');
        result = AB2CAccountCreateController.submitForm(context, formString);
        System.assert(!result.success);
        AB2CAccountCreateController.mainException = null;
        System.assert(((Map<String,Object>)result.data).containsKey('Exception'));

        // provoke exception in create user block
        AB2CAccountCreateController.siteException = new DmlException('oops');
        result = AB2CAccountCreateController.submitForm(context, formString);
        System.assert(
            ((Map<String,Object>)result.data).get('createB2CUser') instanceof Exception
        );
        AB2CAccountCreateController.siteException = null;

        // to provoke duplication scenario, use current user's email address
        form.put('username', UserInfo.getUserEmail());
        formString = JSON.serialize(form);
        result = AB2CAccountCreateController.submitForm(context, formString);
        System.assert(!result.success);
        System.assert(((Map<String,Object>)result.data).containsKey('DuplicateEmail'));

        // to provoke invalid input scenario, remove required fields
        form.remove('lastName');
        form.remove('username');
        formString = JSON.serialize(form);
        result = AB2CAccountCreateController.submitForm(context, formString);
        System.assert(!result.success);
        System.assert(((Map<String,Object>)result.data).containsKey('checkValidateInput'));
    }
}