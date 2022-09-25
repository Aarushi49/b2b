global class AB2CAccountController extends AB2CCommonController {
    private static String mailchimpApiKey = getConfigValue('AlexanianStore.all.mailchimp.mailchimp.api.key');
    private static String mailchimpUserListId = getConfigValue('AlexanianStore.all.mailchimp.mailchimp.list.id');
    private static final String MAILCHIMP_ENDPOINT = 'https://us4.api.mailchimp.com/3.0/lists/';

    /**
    * Return the Mailchimp subscription status of the given user email
    */
    @RemoteAction
    global static ccrz.cc_RemoteActionResult getMailchimpSubscriptionStatus(ccrz.cc_RemoteActionContext context, String userEmail) {
        ccrz.cc_CallContext.initRemoteContext(context);
        ccrz.cc_RemoteActionResult response = new ccrz.cc_RemoteActionResult();
        Map<String, Object> mailchimpResponse = new Map<String, Object>();
        response.success  = false;

        try {
            // Get user subscription status
            String endpoint = MAILCHIMP_ENDPOINT + mailchimpUserListId +'/members/' + md5(userEmail);
            HTTPResponse subscriptionResponse = sendRequest('GET', endpoint, null);
            MailChimpResponse parsedResponse = (MailChimpResponse) Json.deserialize(subscriptionResponse.getBody(), MailChimpResponse.class);
            mailchimpResponse.put('status', parsedResponse.status);
            response.data = mailchimpResponse;
            response.success  = true;
        } catch (Exception e) {
            response.data = e.getMessage();
        }

        return response;
    }

    /**
    * Set the Mailchimp subscription status of the given user email
    * If user doesn't exist in Mailchimp, creates a contact in MC and subscribes them
    */
    @RemoteAction
    global static ccrz.cc_RemoteActionResult setMailchimpSubscriptionStatus(ccrz.cc_RemoteActionContext context, String userEmail, Boolean isSubscribed) {
        ccrz.cc_CallContext.initRemoteContext(context);
        ccrz.cc_RemoteActionResult response = new ccrz.cc_RemoteActionResult();
        Map<String, Object> mailchimpResponse = new Map<String, Object>();
        response.success = false;

        try {
            // Get user subscription status
            String endpoint = MAILCHIMP_ENDPOINT + mailchimpUserListId +'/members/' + md5(userEmail);
            String statusJson = '{ "status" : "' + (isSubscribed ? 'subscribed' : 'unsubscribed') + '" }';
            HTTPResponse subscriptionResponse = sendRequest('PATCH', endpoint, statusJson);
            if (subscriptionResponse.getStatusCode() == 200) {
                MailChimpResponse parsedResponse = (MailChimpResponse) Json.deserialize(subscriptionResponse.getBody(), MailChimpResponse.class);
                mailchimpResponse.put('status', parsedResponse.status);
            } else if (isSubscribed && subscriptionResponse.getStatusCode() == 404) {
                // User doesn't exist in Mailchimp, create a user and subscribe them
                endpoint = MAILCHIMP_ENDPOINT + mailchimpUserListId +'/members/';
                String userJson = '{ "email_address": "' + userEmail + '", "status" : "subscribed" }';
                subscriptionResponse = sendRequest('POST', endpoint, userJson);
                if (subscriptionResponse.getStatusCode() == 200) {
                    MailChimpResponse parsedResponse = (MailChimpResponse) Json.deserialize(subscriptionResponse.getBody(), MailChimpResponse.class);
                    mailchimpResponse.put('status', parsedResponse.status);
                }
            }

            response.data = mailchimpResponse;
            response.success = true;
        } catch (Exception e) {
            response.data = e;
        }

        return response;
    }

    /**
     * Send HTTP request to Mailchimp
     */
    private static HttpResponse sendRequest(String method, String endpoint, String jsonBody) {
        Http http = new Http();
        HTTPRequest request = new HTTPRequest();
        request.setEndpoint(endpoint);
        Blob headerValue = Blob.valueOf('Alexanian:' + mailchimpApiKey);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        request.setHeader('Authorization', authorizationHeader);
        if (jsonBody != null) {
            request.setHeader('Content-Type', 'application/json');
            request.setBody(jsonBody);
        }
        if (method.equals('PATCH')) {
            request.setMethod('POST');
            request.setHeader('X-HTTP-Method-Override', 'PATCH');
        } else {
            request.setMethod(method);
        }
        return http.send(request);
    }

    /**
    * Return the stored payments for current user
    */
    @RemoteAction
    global static ccrz.cc_RemoteActionResult getStoredPayments(ccrz.cc_RemoteActionContext context) {
        ccrz.cc_CallContext.initRemoteContext(context);
        ccrz.cc_RemoteActionResult response = new ccrz.cc_RemoteActionResult();
        response.success  = false;

        try {
            List<ccrz__E_StoredPayment__c> storedPayments = [
                SELECT Id, ccrz__AccountType__c, ccrz__PaymentType__c, ccrz__AccountNumber__c, ccrz__Default__c, ccrz__ExpMonth__c, ccrz__ExpYear__c, 
                    ccpgcs__Address__r.ccrz__AddressFirstline__c, ccpgcs__Address__r.ccrz__AddressSecondline__c, ccpgcs__Address__r.ccrz__City__c, 
                    ccpgcs__Address__r.ccrz__CompanyName__c, ccpgcs__Address__r.ccrz__Country__c, ccpgcs__Address__r.ccrz__CountryISOCode__c,
                    ccpgcs__Address__r.ccrz__FirstName__c, ccpgcs__Address__r.ccrz__LastName__c, ccpgcs__Address__r.ccrz__PostalCode__c, 
                    ccpgcs__Address__r.ccrz__State__c, ccpgcs__Address__r.ccrz__StateISOCode__c
                FROM ccrz__E_StoredPayment__c 
                WHERE ccrz__Account__c = :ccrz.cc_CallContext.effAccountId
                    AND ccrz__Storefront__c = 'AlexanianStore'];
            response.data = storedPayments;
            response.success  = true;
        } catch (Exception e) {
            response.data = e.getMessage();
        }

        return response;
    }

    /**
    * Set stored payment as default for current user
    */
    @RemoteAction
    global static ccrz.cc_RemoteActionResult setDefaultStoredPayment(ccrz.cc_RemoteActionContext context, String accountNumber, boolean isDefault) {
        ccrz.cc_CallContext.initRemoteContext(context);
        ccrz.cc_RemoteActionResult response = new ccrz.cc_RemoteActionResult();
        response.success  = false;

        try {
            ccrz.ccLog.log(LoggingLevel.DEBUG,'AB2CAccountController: ' + 'accountNumber:' + accountNumber);
            List<ccrz__E_StoredPayment__c> storedPayments = [
                SELECT Id, ccrz__Default__c, ccrz__AccountNumber__c
                FROM ccrz__E_StoredPayment__c 
                WHERE ccrz__Account__c = :ccrz.cc_CallContext.effAccountId
                    AND ccrz__Storefront__c = 'AlexanianStore'];
            for (ccrz__E_StoredPayment__c storedPayment : storedPayments) {
                if (((String) storedPayment.get('ccrz__AccountNumber__c')).equals(accountNumber)) {
                    storedPayment.put('ccrz__Default__c',  isDefault);
                } else {
                    if (isDefault) {
                        storedPayment.put('ccrz__Default__c',  false);
                    }
                }
            }
            update storedPayments;
            ccrz.ccLog.log(LoggingLevel.DEBUG,'AB2CAccountController: ' + 'storedPayments:' + storedPayments);

            response.success  = true;
        } catch (Exception e) {
            response.data = e.getMessage();
        } finally {
            ccrz.ccLog.close(response);
        }

        return response;
    }

    /**
    * Create a default wishlist
    */
    @RemoteAction
    global static ccrz.cc_RemoteActionResult createDefaultWishlist(ccrz.cc_RemoteActionContext context) {
        ccrz.cc_CallContext.initRemoteContext(context);
        ccrz.cc_RemoteActionResult response = new ccrz.cc_RemoteActionResult();
        response.success  = false;

        Map<String, Object> inputData = new Map<String, Object>{
            ccrz.ccAPI.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
            ccrz.ccAPIWishList.WISHLIST => new Map<String, Object>{
                'name' => 'My Favourites',
                'storefront' => 'AlexanianStore',
                'currencyISOCode' => 'CAD',
                'activeCart' => TRUE
            }
        };
        
        try {
            Map<String, Object> outputData = ccrz.ccAPIWishList.create(inputData);
            if (outputData.get(ccrz.ccAPIWishList.WISHLIST) != null) {
                Map<String, Object> wishListMap = (Map<String, Object>) outputData.get(ccrz.ccAPIWishList.WISHLIST);
                response.data = wishListMap;
            }
        } catch (Exception e) {
            response.data = e.getMessage();
        } finally {
            ccrz.ccLog.close(response);
        }

        return response;
    }

    /**
     * Get MD5 hash from a plaintext string
     */
    private static String md5(String plainText) {
        Blob requestBlob = Blob.valueOf(plainText);
        Blob hash = Crypto.generateDigest('MD5', requestBlob);
        return EncodingUtil.convertToHex(hash);
    }

    /**
     * Mailchimp API response class
     */
    class MailChimpResponse {
        String status;
    }
}