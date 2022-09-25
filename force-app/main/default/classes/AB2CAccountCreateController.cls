global class AB2CAccountCreateController extends AB2CCommonController {
    @TestVisible static Exception mainException;
    @TestVisible static Exception siteException;
    //Method for submitForm
    //string form = '{"confirmpassword":"pass123!!A","password":"pass123!!A", "description":"Description","salutation": "Mr",	"firstName": "DFirstName",	"lastName": "DLastName",	"primaryPhone": "4448884444",	"language": "en_US",	"currencyCode": "CAD",	"companyName": "DcompanyName",	"companyType": "ISP",	"taxExemptFlag": true,	"customField1": "",	"customField2":"",	"username": "k@k.com",	"Department" : "IT",	"shippingAddress": {		"address1": "2 Peachtree",		"city":"Atlanta",		"   ": "Georgia",		"postalCode": "30303",		"country": "United States",		"countryCode": ""	},	"billingAddress": {		"country": "United States",		"countryCode": "",		"address1": "2 Peachtree",		"city": "Atlanta",		"state": "Georgia",		"postalCode": "30303"}}';
    @RemoteAction
    global static ccrz.cc_RemoteActionResult submitForm(ccrz.cc_RemoteActionContext ctx,String form){
        Boolean wasSuccessful = false;
        ccrz.cc_RemoteActionResult res = ccrz.cc_CallContext.init(ctx);
        
        ccrz.ccLog.log(LoggingLevel.DEBUG,'AB2CAccountCreateController','in submit form');
        
        //Prepare return to the frontend
        Map<String, Object> dataMap = new Map<String, Object>();            
        
        try{
            if (mainException != null) throw mainException; // for unit testing catch block

            res.success = false;
            res.inputContext = ctx;
            
            //replace email to username
            form = form.replace('"email":','"username":' );
            
            //Convert to String/Object to CC Input Data
            Map<String,Object> newAccountMap = (Map<String,Object>)JSON.deserializeUntyped(form);            
            
            //Format data to ccApiAccount
            Map<String,Object> ccInputData = cloudCrazeInputData(newAccountMap);
            ccrz.ccLog.log(LoggingLevel.DEBUG,'AB2CAccountCreateController','cloudCrazeInputData - Done');
                      
            if(checkEmailDuplication((String)newAccountMap.get('username'))){
                dataMap.put('DuplicateEmail', 'Duplicate Email');
                res.success = false;                
            }else if(!isInputValid(ccInputData,res)){
                dataMap.put('checkValidateInput', 'Check Validate Input');                
                res.success = false;                
            }else{                
                //Creating Account in SFDC, using ccApiAccount
                Map<String,Object> outputData = ccrz.ccApiAccount.createAccount(ccInputData);
                ccrz.ccLog.log(LoggingLevel.DEBUG,'AB2CAccountCreateController','ccrz.ccApiAccount.createAccount - Done');
                
                
                //Fetch new Account into the account object
                Account newAccount = (Account)outputData.get(ccrz.ccApiAccount.ACCOUNT_NEW);
                if(outputData.get(ccrz.ccApiAccount.ACCOUNTS) != null){
                    List<Map<String,Object>> accounts = (List<Map<String,Object>>) outputData.get(ccrz.ccApiAccount.ACCOUNTS);
                    ccrz.ccLog.log(LoggingLevel.DEBUG,'AB2CAccountCreateController','outputData Account' + accounts);                    
                }
                
                //Create contact in SFDC
                contact contact = createContact(newAccountMap,newAccount);
                ccrz.ccLog.log(LoggingLevel.DEBUG,'AB2CAccountCreateController','createContact - Done');
                
                //Create Alexanian User
                string userid = createB2CUser(contact,newAccount,(String)newAccountMap.get('password'),dataMap);
                ccrz.ccLog.log(LoggingLevel.DEBUG,'AB2CAccountCreateController','createB2CUser - Done');

                //Create CloudCraze Address
                res.success = createContactAddr(contact,newAccount,userid);
               
            }
        } catch(Exception e){
            res.success = false;
            ccrz.ccLog.log(LoggingLevel.DEBUG,'AB2CAccountCreateController','Exception: ' + e.getMessage());
            ccrz.ccLog.log(LoggingLevel.DEBUG,'AB2CAccountCreateController','submitForm Exception => ' + e.getStackTraceString());
            dataMap.put('Exception', e.getMessage());
            System.debug('Exception => ' + e + '; Stack Trace: ' + e.getStackTraceString());            
        }finally {
            res.data = dataMap;
            ccrz.ccLog.close(res);
        }
        return res;
    }

    @RemoteAction
    global static ccrz.cc_RemoteActionResult setMailchimpShubscriptionStatus(ccrz.cc_RemoteActionContext ctx, String userEmail){
        return AB2CAccountController.setMailchimpSubscriptionStatus(ctx,userEmail, true);    
    }
    
    private static Boolean checkEmailDuplication(String email){
        List<User> u = [SELECT email FROM USER WHERE email =: email];
        return u.size() > 0 ? true: false;
    }
    
    //The validateNew method is a convenience method that allows for validation of new User & Account data
    private static Boolean isInputValid(Map<String,Object> inputData, ccrz.cc_RemoteActionResult res){
        Boolean isValid = true;
        List<ccrz.cc_bean_Message> errorMessages = (List<ccrz.cc_bean_Message>)ccrz.ccAPIAccount.validateNew(inputData).get(ccrz.ccAPIAccount.MESSAGES);
        // Assume there are errors.
        ccrz.ccLog.log(LoggingLevel.DEBUG,'AB2CAccountCreateController','checkValidateInput Check for Errors');
        for (ccrz.cc_bean_Message msg : errorMessages) {
            isValid = false;
            if(res != null){
                ccrz.ccLog.log(LoggingLevel.DEBUG,'AB2CAccountCreateController','checkValidateInput =' + msg);
            }            
        }
        return isValid;
    }
    
    //CloudCraze CreateAccount
    private static Map<String,Object> cloudCrazeInputData(Map<String,Object> newAccountMap){
        Map<String,Object> inputData = new Map<String,Object>{
            ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                ccrz.ccApiAccount.ACCOUNT_NEW => newAccountMap,
                ccrz.ccApi.SIZING => new Map<String, Object>{
                    ccrz.ccApiAccount.ENTITYNAME => new Map<String, Object>{
                        ccrz.ccApi.SZ_REFETCH => TRUE
                            }
                }
        };
        return inputData;
    }
    
    
    private static contact createContact(Map<String,Object> userDataMap, account newAccount){
        String firstName = (String)userDataMap.get('firstName');
        String lastName = (String)userDataMap.get('lastName');
        
        String email = (String)userDataMap.get('username');
        String phone = (String)userDataMap.get('primaryPhone');
        String mailingCity = newAccount.ShippingCity;
        String mailingCountry = newAccount.ShippingCountry;
        String mailingPostalCode = newAccount.ShippingPostalCode;
        String mailingState = newAccount.ShippingState;
        String mailingStreet = newAccount.ShippingStreet;
        
        Contact contact = new Contact();
        contact.FirstName = firstName;
        contact.Lastname = lastName;
        contact.email = email;
        contact.Phone = phone;
        contact.MailingCity = mailingCity;
        contact.MailingState = mailingState;
        contact.MailingCountry = mailingCountry;
        contact.MailingPostalCode = mailingPostalCode;
        contact.MailingStreet = mailingStreet;
        contact.AccountId = newAccount.Id;
        contact.ccrz__SelfRegistered__c = true;
        
        insert contact;
        return contact;
    }
    
    private static string createB2CUser(Contact contact, account newAccount,string password, Map<String, Object> dataMap){
        Profile profile =  [SELECT id,name from Profile where name = 'B2B Storefront Registered Users' LIMIT 1];
        
        User u = new user();
        u.firstname = contact.FirstName;
        u.Lastname = contact.Lastname;
        u.Username = contact.email;
        u.Email = contact.email;
        u.profileId = profile.id;
        u.Alias = (contact.email).left(8) ; 
        u.CommunityNickname = (contact.email).left(40);
        u.ContactId = contact.Id;
        u.EmailEncodingKey = 'UTF-8';
        u.IsActive = true;
        u.Phone = contact.Phone;
        //Todo need to add currency mode, can't see any product if Currency code is enable
        //u.ccrz__CC_CurrencyCode__c = contact.MailingCountry == 'CA' ? 'CAD' :'USD';
        u.ccrz__CC_CurrencyCode__c = 'CAD';
        String userId;  
        try{
            if (siteException != null) throw siteException; // for unit testing catch block
            userid = site.createExternalUser(u, newAccount.id,password);
            if(userId != null){ dataMap.put('createB2CUser','Successful'); }
        }catch(Exception ex){
            dataMap.put('createB2CUser',ex);
            system.debug('External ' + ex);
        }
        return userId;
    }

    private static Boolean createContactAddr(Contact contact, account newAccount,string userid){
        ccrz__E_ContactAddr__c ca = new ccrz__E_ContactAddr__c();
        ca.ccrz__FirstName__c = contact.FirstName;
        ca.ccrz__LastName__c = contact.Lastname;
        ca.ccrz__Email__c = contact.email;
        ca.ccrz__AddressFirstline__c = newAccount.ShippingStreet;
        ca.ccrz__City__c = newAccount.ShippingCity;
        ca.ccrz__CountryISOCode__c = newAccount.ShippingCountry;
        ca.ccrz__PostalCode__c = newAccount.ShippingPostalCode;
        ca.ccrz__StateISOCode__c = newAccount.ShippingState;
        ca.ccrz__AddrReadOnly__c = false;
        ca.OwnerId = userid;
        insert ca;


        ccrz__E_AccountAddressBook__c aaB = new ccrz__E_AccountAddressBook__c();
        aaB.ccrz__AccountId__c = newAccount.id;
        aaB.ccrz__AddressType__c = 'Billing';
        aaB.ccrz__E_ContactAddress__c = ca.id;
        aaB.ccrz__TypeReadOnly__c = false;
        aaB.ccrz__Default__c = true;
        aaB.OwnerId = userid;
        insert aaB;

        ccrz__E_AccountAddressBook__c aaC = new ccrz__E_AccountAddressBook__c();
        aaC.ccrz__AccountId__c = newAccount.id;
        aaC.ccrz__AddressType__c = 'Shipping';
        aaC.ccrz__E_ContactAddress__c = ca.id;
        aaC.ccrz__TypeReadOnly__c = false;
        aaC.ccrz__Default__c = true;
        aaC.OwnerId = userid;
        insert aaC;

        return true;
    }

    

}
/* Keep for testing
public static void TestSubmitForm(){
string form = '{"confirmpassword":"pass123!!A","password":"pass123!!A", "description":"Description","salutation": "Mr",	"firstName": "DFirstName",	"lastName": "DLastName",	"primaryPhone": "4448884444",	"language": "en_US",	"currencyCode": "CAD",	"companyName": "DcompanyName",	"companyType": "ISP",	"taxExemptFlag": true,	"customField1": "",	"customField2":"",	"username": "k@k.com",	"Department" : "IT",	"shippingAddress": {		"address1": "2 Peachtree",		"city":"Atlanta",		"state": "Georgia",		"postalCode": "30303",		"country": "United States",		"countryCode": ""	},	"billingAddress": {		"country": "United States",		"countryCode": "",		"address1": "2 Peachtree",		"city": "Atlanta",		"state": "Georgia",		"postalCode": "30303"}}';
String hashString = '10' + String.valueOf(Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS'));
Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(hashString));
String hexDigest = EncodingUtil.convertToHex(hash);
system.debug('##########' + hexDigest );

form = form.replace('DcompanyName',  hexDigest );
form = form.replace('DFirstName', hexDigest );
form = form.replace('DLastName',  hexDigest );
form = form.replace('k@k.com',  hexDigest +'@a.com.partial');


ccrz.ccLog.log(LoggingLevel.DEBUG,'SAGE','submitForm input data ' + form);

Map<String,Object> newAccountMap = (Map<String,Object>)JSON.deserializeUntyped(form);
Map<String,Object> inputData = cloudCrazeInputData(newAccountMap);
system.debug('description = ' + (String)newAccountMap.get('description'));
system.debug('description inputData = ' + (String)inputData.get('description'));


system.debug('inputData ' + inputData);
checkValidateInput(inputData,null);




Map<String,Object> outputData = ccrz.ccApiAccount.createAccount(inputData);
Account newAccount = (Account)outputData.get(ccrz.ccApiAccount.ACCOUNT_NEW);
system.debug('outputData createAccount' + outputData);
system.debug('newAccount ' + newAccount);

if(outputData.get(ccrz.ccApiAccount.ACCOUNTS) != null){
List<Map<String,Object>> accounts = (List<Map<String,Object>>) outputData.get(ccrz.ccApiAccount.ACCOUNTS);
system.debug('accounts ' + accounts);            
}

contact contact = createContact(newAccountMap,newAccount);
createB2CUser(contact,newAccount,(String)newAccountMap.get('password'));

}*/