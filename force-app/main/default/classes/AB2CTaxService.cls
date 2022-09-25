global with sharing class AB2CTaxService extends ccrz.cc_hk_TaxCalculation {

    /**
     * The getTaxAmount method will only be executed if skipTaxCalculation method evaluates to false.
     * The skipTaxCalculation method returns the value of cc_api_User.getCurrentUser.Contact.Account.TaxExemptAccount__c.
     */
    global override Decimal getTaxAmount(Map<String, Object> inputData) {
        Decimal taxOnCartItems = super.getTaxAmount(inputData);

        try {
            // Calculate tax on shipping amount as well
            Id cartId = (Id) inputData.get(ccrz.cc_hk_TaxCalculation.PARAM_CARTID);
            ccrz.cc_bean_MockContactAddress shipping = (ccrz.cc_bean_MockContactAddress) inputData.get(ccrz.cc_hk_TaxCalculation.PARAM_SHIPADDR);
            ccrz__E_TaxRate__c taxRate = [SELECT ccrz__TaxRate__c 
                                            FROM ccrz__E_TaxRate__c 
                                            WHERE ccrz__CountryCode__c =: shipping.countryCode 
                                                AND ccrz__StateCode__c =: shipping.stateCode];
            ccrz__E_Cart__c cart = [SELECT ccrz__ShipAmount__c FROM ccrz__E_Cart__c WHERE Id =: cartId];

            if (taxRate != null && taxRate.ccrz__TaxRate__c > 0 && cart.ccrz__ShipAmount__c > 0) {
                Decimal taxOnShippingAmount = taxRate.ccrz__TaxRate__c * cart.ccrz__ShipAmount__c / 100;
                return taxOnCartItems + taxOnShippingAmount;
            }
            System.debug(LoggingLevel.ERROR, 'Unable to find tax rate for country:' + shipping.countryCode + ' and state:' + shipping.stateCode);
            return taxOnCartItems;
        }
        catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Exception calculating tax: ' + ex.getMessage());
            return taxOnCartItems;
        }
    }
 
 
    /** Not used */
    @RemoteAction
    global static ccrz.cc_RemoteActionResult calculateTax(ccrz.cc_RemoteActionContext ctx, String cartId, string jsonShipping) {
        ccrz.cc_bean_MockContactAddress shipping = (ccrz.cc_bean_MockContactAddress) JSON.deserialize(jsonShipping, ccrz.cc_bean_MockContactAddress.class);
        ccrz.cc_RemoteActionResult result = ccrz.cc_CallContext.init(ctx);        
        ccrz.cc_hk_TaxCalculation taxes = new ccrz.cc_hk_TaxCalculation();
        System.debug(LoggingLevel.ERROR,'shipping: ' + shipping);

        try {
            Decimal response = taxes.getTaxAmount(new Map<String,Object>{
                    ccrz.cc_hk_TaxCalculation.PARAM_CARTID => cartId,
                    ccrz.cc_hk_TaxCalculation.PARAM_SHIPADDR => shipping
            });
            
			ccrz__E_Cart__c c = new ccrz__E_Cart__c();
            c.id = cartId;
            c.ccrz__TaxAmount__c = response;
            update c;
            
            result.data = response;
            result.success = true;
        } catch (Exception e) {
            result.success = false;
            System.debug(LoggingLevel.ERROR,'ERR:Error calculating tax: ' + e.getCause() + ' at line ' + e.getLineNumber());
        }
        
        return result;
    }
}