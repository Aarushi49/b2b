global with sharing class AB2CUrlRewriter implements Site.UrlRewriter {
    private final String CLASSNAME = 'AB2CUrlRewriter';
    private ccrz.cc_FriendlyUrlRewriter ccRewriter;
    @TestVisible private static final Map<String, String> URL_MAP = new Map<String, String>{
        'signin' => 'ccrz__CCSiteLogin',
        'register' => 'ccrz__CCSiteRegister',
        'stores' => 'ccrz__SellerListPage',
        'stores/detail' => 'ccrz__SellerDetail',
        'area-rugs/overview' => 'ccrz__CCPage?pagekey=category&id=area-rugs',
        'flooring/overview' => 'ccrz__CCPage?pagekey=category&id=flooring',
        'window-coverings/overview' => 'ccrz__CCPage?pagekey=category&id=window-coverings',
        'carpet/overview' => 'ccrz__CCPage?pagekey=category&id=carpet',
        'not-found' => 'ccrz__CCFileNotFound',
        'cart' => 'ccrz__Cart', 
        'cart/checkout' => 'ccrz__CheckoutNew',
        'cart/checkout/order-detail' => 'ccrz__OrderView',
        'cart/checkout/order-confirmation' => 'ccrz__OrderConfirmation',
        'compare' => 'ccrz__ProductCompare',
        'my-account' => 'ccrz__MyAccount',
        'my-account/cards' => 'ccrz__StoredPaymentDetail',
        'my-account/forgot' => 'ccrz__CCForgotPassword'
    };

    global AB2CUrlRewriter() {
        ccRewriter = new ccrz.cc_FriendlyUrlRewriter();
    }
  
    global System.PageReference mapRequestUrl(System.PageReference friendlyUrl) {
        system.debug('in friendlyUrl--'+friendlyUrl);
        System.PageReference mappedUrl = ccRewriter.mapRequestUrl(friendlyUrl);
        if (mappedUrl == null) {
            String url = friendlyUrl.getUrl().substring(1);
            String path = url;
            if (url.contains('?')) {
                path = url.substring(0, url.indexOf('?'));
            }
            if (path.contains('&')) {
                path = path.substring(0, path.indexOf('&'));
            }

            if (URL_MAP.containsKey(path)) {
                String refUrl = url.replace(path, URL_MAP.get(path));
                return new PageReference(refUrl);
            }
            
            // Static page
            integer richContentCount = [SELECT COUNT() FROM ccrz__E_RichContent__c WHERE ccrz__ContentKey__c = :path];
            if (richContentCount > 0) {
                return new PageReference('ccrz__CCPage?pagekey=static&content=' + path);
            }

            // Redirect to file not found
            if (url.contains('ccrz__CCSiteLogin')) {
                String startUrl = friendlyUrl.getParameters().get('startUrl');
                if (startUrl != null && !startUrl.contains('ccrz__')) {
                    mappedUrl = new PageReference('not-found');
                    mappedUrl.setRedirect(true);
                    mappedUrl.setRedirectCode(302);
                }
            }
        }
        
        return mappedUrl;
    }

    global List<System.PageReference> generateUrlFor(List<System.PageReference> CCUrls) {
        return ccRewriter.generateUrlFor(CCUrls);
    }
}