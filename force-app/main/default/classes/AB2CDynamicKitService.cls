global class AB2CDynamicKitService {
    @TestVisible private static final List<String> SHAPE_SKUS = new List<String>{
        'RECTANGLE',
        'SQUARE',
        'CIRCLE',
        'OVAL',
        'OCTAGON'
    };
    // allow unit tests to override this
    @TestVisible private static Exception mockException;

    public AB2CDynamicKitService() {

    }

    @RemoteAction
    global static ccrz.cc_RemoteActionResult getPriceForConfig(ccrz.cc_RemoteActionContext context, String SKU, String shape, 
                Decimal lenIn, Decimal widIn, List<String> compSKUs) {
        ccrz.cc_CallContext.initRemoteContext(context);
        ccrz.cc_RemoteActionResult response = new ccrz.cc_RemoteActionResult();
        response.success  = false;

        if (SKU != null && shape != null && lenIn != null) {
            try {
                // simulate API exceptions in unit tests
                if (mockException != null) throw mockException;

                //parse selections
                DynamicKitSelections sels = new DynamicKitSelections(SKU, shape, lenIn, widIn, compSKUs, context);

                Decimal totalPrice = sels.calcPrice();
                
                response.data = totalPrice;
                response.success  = true;
            } catch (Exception e) {
                response.data = e.getMessage(); 
            }
        }
        return response;
    }

    @RemoteAction
    global static ccrz.cc_RemoteActionResult setDynamicKitPricingOnCart(ccrz.cc_RemoteActionContext context, String cartID, String label) {
        ccrz.cc_CallContext.initRemoteContext(context);
        ccrz.cc_RemoteActionResult response = new ccrz.cc_RemoteActionResult();
        response.success  = false;

        if (cartID != null && label != null) {
            try {
                // simulate API exceptions in unit tests
                if (mockException != null) throw mockException;
                
                List<ccrz__E_CartItem__c> cartItems = [
                    SELECT Id, ccrz__Product__c, ccrz__Price__c, ccrz__SubAmount__c
                        , ccrz__PricingType__c, ccrz__ParentCartItem__r.ccrz__Product__c
                        , ccrz__ParentCartItem__r.ccrz__Product__r.Id
                        , ccrz__ParentCartItem__r.ccrz__Product__r.ccrz__SKU__c
                    FROM ccrz__E_CartItem__c
                    WHERE ccrz__Cart__r.ccrz__EncryptedId__c =:cartID
                        AND ccrz__ParentCartItem__r.ccrz__ItemLabel__c =:label
                        AND ccrz__Product__r.ccrz__SKU__c =:SHAPE_SKUS
                ];

                for (ccrz__E_CartItem__c cartItem : cartItems) {
                    ccrz__E_Product__c prod = cartItem.ccrz__ParentCartItem__r.ccrz__Product__r;
                    if (prod != null) {
                        DynamicKitSelections sels = new DynamicKitSelections(prod.ccrz__SKU__c, label, context);
                        Decimal totalPrice = sels.calcShapePrice();
                        cartItem.ccrz__Price__c = totalPrice;
                        cartItem.ccrz__SubAmount__c = totalPrice;
                        cartItem.ccrz__PricingType__c = 'external';
                    }
                }

                update cartItems;

                response.success = true;
            
            } catch (Exception e) {
                response.data = e.getMessage();
            }
        }

        return response;
    }

    @TestVisible private class DynamicKitSelections {
        @TestVisible private final String SHAPE_RECTANGLE = 'RECT';
        @TestVisible private final String SHAPE_SQUARE = 'SQUA';
        @TestVisible private final String SHAPE_CIRCLE = 'CIRC';
        @TestVisible private final String SHAPE_OVAL = 'OVAL';
        @TestVisible private final String SHAPE_OCTAGON = 'OCTA';

        public String baseSKU;
        public String shape;
        public Double lenIn;
        public Double widIn;
        public List<String> compSKUs;

        public ccrz.cc_RemoteActionContext context;

        // expecting selectedConfig in the format:
        // selectedConfig = 'RECT-0025x0030-SKU1-SKU2-SKU3'
        public DynamicKitSelections(String baseSKU, String selectedConfig, ccrz.cc_RemoteActionContext context) {
            this.context = context;

            this.baseSKU = baseSKU;
            this.shape = selectedConfig.substring(0,4);
            this.lenIn = Integer.valueOf(selectedConfig.substring(5,9));
            this.widIn = Integer.valueOf(selectedConfig.substring(10,14));

            this.compSKUs = new List<String>();
            String compProdStr = '';
            if (selectedConfig.length() > 15) {
                compProdStr = selectedConfig.substring(15);
            }
            if (compProdStr.length() > 0) {
                this.compSKUs = compProdStr.split('-', -1);
            }
        }

        public DynamicKitSelections(String baseSKU, String shape, Decimal lenIn, Decimal widIn, List<String> compSKUs, ccrz.cc_RemoteActionContext context) {
            this.context = context;
            this.baseSKU = baseSKU;
            this.shape = shape;
            this.lenIn = lenIn;
            this.widIn = widIn;
            this.compSKUs = compSKUs;
        }

        public Decimal getSqrFt() {
            if (this.shape.equalsIgnoreCase(this.SHAPE_RECTANGLE)) {
                return (this.lenIn * this.widIn) / 144;
            } else if (this.shape.equalsIgnoreCase(this.SHAPE_SQUARE)) {
                return (this.lenIn * this.lenIn) / 144;
            } else if (this.shape.equalsIgnoreCase(this.SHAPE_CIRCLE)) {
                Double radius = (Double)this.lenIn/2;
                return (Math.PI * Math.pow(radius, 2)) / 144;
            } else if (this.shape.equalsIgnoreCase(this.SHAPE_OVAL)) {
                Double lenRadius = (Double)this.lenIn/2;
                Double widRadius = (Double)this.widIn/2;
                return (Math.PI * lenRadius * widRadius) / 144;
            } else if (this.shape.endsWithIgnoreCase(this.SHAPE_OCTAGON)) {
                //as per existing formula: area of square
                return (this.lenIn * this.lenIn) / 144;
            }
            return 0;
        }

        public Decimal calcPrice() {
            Decimal calcPrice = this.calcShapePrice();
    
            //add price from composite products selected
            ccrz.cc_RemoteActionResult compProdResponse;
            if (this.compSKUs.size() > 0) {
                for (String compSKU : this.compSKUs) {
                    compProdResponse = AB2CProductController.getProductDetailBySku(this.context, compSKU);
                    if (compProdResponse.success) {
                        List<Map<String, Object>> compProdList = (List<Map<String, Object>>)compProdResponse.data;
                        for (Map<String, Object> compProd : compProdList) {
                            Decimal compProdPrice = (Decimal)compProd.get('price');
                            calcPrice += compProdPrice;
                        }
                    }
                }
            }
            return calcPrice;
        }

        public Decimal calcShapePrice() {
            ccrz.cc_RemoteActionResult productResponse = AB2CProductController.getProductDetailBySku(this.context, this.baseSKU);
            List<Map<String, Object>> productList = (List<Map<String, Object>>) productResponse.data;
            Decimal pricePerSqrFt = (Decimal)productList[0].get('price');
    
            Decimal sqrFt = this.getSqrFt();
            Decimal calcPrice = pricePerSqrFt * sqrFt;

            return calcPrice;
        }
    }
}