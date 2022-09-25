global class AB2CStaticContentController extends AB2CCommonController {
    private static final String className = 'AB2CStaticContentController';
    private static String FORM_SUBMIT_EMAIL = getConfigValue('AlexanianStore.all.mailchimp.email.form.submission');
    @TestVisible static Exception mockException; // to unit-test catch block
    /**
    * Returns a list of rich text elements to render on a static page
    * @param - contentId - The content key of the rich text to render on this page
    * @return - cc_RemoteActionResult - Data model used for static content page
    */
    @RemoteAction
    global static ccrz.cc_RemoteActionResult getStaticContent(ccrz.cc_RemoteActionContext context, String contentId) {
        ccrz.cc_CallContext.initRemoteContext(context);
        ccrz.cc_RemoteActionResult response = new ccrz.cc_RemoteActionResult();
        response.success  = false;

        if (contentId != null) {
            Map<String, Object> richContentRequest = new Map<String, Object> {
                ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                ccrz.ccApiRichContent.STATUS => 'Published',
                ccrz.ccApiRichContent.KEYS => new Set<String>{contentId}
            };

            try {
                if (mockException != null) throw mockException;
                Map<String, Object> richContentResponse = ccrz.ccApiRichContent.fetch(richContentRequest);
                // Build response data object
                Map<String, Object> richContentDataResponse = new Map<String, Object>{
                    'contentId' => contentId
                };
                if (richContentResponse.get(ccrz.ccAPIRichContent.RICH_CONTENT_LIST) != null) {
                    List<Map<String, Object>> contentList = (List<Map<String, Object>>) richContentResponse.get(ccrz.ccAPIRichContent.RICH_CONTENT_LIST);
                    richContentDataResponse.put('contentList', contentList);

                    // Find Menu ID if one exists in any of the CC Rich Content Items
                    for (Map<String, Object> content : contentList){
                        String menuId = (String) content.get('menuId');
                        if (!String.isBlank(menuId)) {
                            richContentDataResponse.put('menuId', content.get('menuId'));
                            break;
                        }
                    }
                }

                response.data = richContentDataResponse;
                response.success  = true;
            } catch (Exception e) {
                response.data = e.getMessage();
                ccrz.ccLog.log(LoggingLevel.ERROR, className, e.getMessage());
            } finally {
                ccrz.ccLog.close(response);
            }
        }

        return response;
    }

    /**
    * Sends form data to an email
    * @param - formData - Sent as the body of the email
    */
    @RemoteAction
    global static ccrz.cc_RemoteActionResult submitForm(ccrz.cc_RemoteActionContext context, String formName, String serializedData) {
        ccrz.cc_CallContext.initRemoteContext(context);
        ccrz.cc_RemoteActionResult response = new ccrz.cc_RemoteActionResult();
        response.success = false;

        if (serializedData != null) {
            try {
                String[] fields = serializedData.split('&');
                String emailBody = formName + '\n\n';
                String formSubmitEmail = FORM_SUBMIT_EMAIL;
                Map<String, String> keyValMap = new Map<String, String>();
                for (String field : fields) {
                    String[] fieldSplit = field.split('=');
                    String key = EncodingUtil.urlDecode(fieldSplit[0], 'UTF-8');
                    String value = fieldSplit.size() > 1 ? EncodingUtil.urlDecode(fieldSplit[1], 'UTF-8') : '';
                    if (key.equals('email-recipient')) {
                        formSubmitEmail = value;
                    } else {
                        if (keyValMap.containsKey(key)) {
                            String existing = keyValMap.get(key);
                            // checkboxes can have multiple values per key
                            keyValMap.put(key, existing + ', '  + value); 
                        } else {
                            keyValMap.put(key, value);
                        }
                    }
                }

                for (String key : keyValMap.keySet()) {
                    emailBody += key + ': ' + keyValMap.get(key) + '\n';
                }
                emailBody += '\n';

                Messaging.SendEmailResult[] results = sendEmail(formSubmitEmail, formName, emailBody);
                if (results[0].success) {
                    response.success = true;
                    
                    // Create RLM case
                    if (!Test.isRunningTest()){
                        RLMCase rlmCase = new RLMCase(formName, keyValMap);
                        createCase(JSON.serialize(rlmCase));
                        ccrz.ccLog.log(LoggingLevel.INFO, className, JSON.serialize(rlmCase));
                    }
                } else { 
                    response.data = results[0].errors[0].message;
                }
            } catch (Exception e) {
                response.data = e.getMessage();
                ccrz.ccLog.log(LoggingLevel.ERROR, className, e.getLineNumber() + ': ' + e.getMessage());
            } finally {
                ccrz.ccLog.close(response);
            }
        }
        return response;
    }

    private static Messaging.SendEmailResult[] sendEmail(String to, String subject, String body) {
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new String[] { to };
        message.subject = subject;
        message.plainTextBody = body;
        Messaging.SingleEmailMessage[] messages =  new List<Messaging.SingleEmailMessage> {message};
        return Messaging.sendEmail(messages);
    }

    @future(callout = true)
    private static void createCase(String rlmCaseStr) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://app.retailleadmanagement.com/api/2eeb04a74a4ffff298959df565c49be3/leads');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(rlmCaseStr);

        HttpResponse response = new Http().send(request);
    }

    class RLMCase {
        String location_name;
        String division_name;
        String source_name;
        String first_name;
        String last_name;
        String email;
        String address1;
        String phone;
        String zip;
        String note;
        String[] products_interested_in;

        public RLMCase(String formName, Map<String, String> keyValMap) {
            this.location_name = '99-SH';
            this.division_name = 'Shop at Home';
            this.source_name = 'Website - ' + formName;

            if (keyValMap.containsKey('firstname')) {
                this.first_name = keyValMap.get('firstname');
                this.last_name = keyValMap.get('lastname');
            } else if (keyValMap.containsKey('name')) {
                String[] names = keyValMap.get('name').split(' ');
                this.first_name = names[0];
                if (names.size() > 1) {
                    this.last_name = names[1];
                }
            }

            this.email = keyValMap.get('email');
            this.address1 = keyValMap.get('address');
            this.phone = keyValMap.get('phoneNumber');
            this.zip = keyValMap.get('postalCode');
            this.note = keyValMap.get('additionalInformation');

            if (keyValMap.containsKey('productsOfInterest')) {
                this.products_interested_in = keyValMap.get('productsOfInterest').split(', ');
            }
        }
    }
}