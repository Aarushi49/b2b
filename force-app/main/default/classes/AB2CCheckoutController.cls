global class AB2CCheckoutController {
    private static final String CLASSNAME = 'AB2CCheckoutController';
    
    public class CartInformation{
        public List<string> lstProductId;
        Decimal cartWeight;
        Boolean isOversizeRug;
        Boolean hasOtherProduct;       
        Boolean hasOnlyRug;
        Boolean hasRug;
        Boolean hasOnlySampleProduct;
        Boolean hasSampleProduct;
        Map<string,string> mapComponentToComposite;
        
        public CartInformation(){
            cartWeight = 0;
            isOversizeRug = false;
            hasOnlySampleProduct = false;
            hasOnlyRug = false;
            hasSampleProduct = false;
            hasOtherProduct = false;
            Map<string,string> mapComponentToComposite = new Map<string,string>();
        }
    }
    
    @RemoteAction
    global static ccrz.cc_RemoteActionResult calculateShipping(String cartId, string storeName, string distance, string province) {          
        ccrz.cc_RemoteActionResult result = new ccrz.cc_RemoteActionResult();
        try {
            AB2_Shipping_Parameters__c shippingParameters = AB2_Shipping_Parameters__c.getInstance();
            String escapedStoreName = String.escapeSingleQuotes(storeName);
            String escapedCartId = String.escapeSingleQuotes(cartId);
            Decimal escapedDistance = Decimal.valueOf(distance);
            String escapedProvince = String.escapeSingleQuotes(province);
            
            CartInformation objCartInfo = getCartInformation(cartId, shippingParameters.AB2C_Rug_Category__c, shippingParameters);
            ccrz.ccLog.log(LoggingLevel.DEBUG, CLASSNAME, 'CartInformation: ' + objCartInfo);
            
            string queryString = 'SELECT ccrz__CurrencyISOCode__c, ccrz__MinWeight__c,ccrz__MaxWeight__c,' +
                'ccrz__Shipper__c,ccrz__ShippingRate__c,ccrz__Storefront__c,Id, Name ' +
                'FROM ccrz__E_ShippingRate__c ';
            
            string queryWhereString  = 'WHERE ' +
                'ccrz__Storefront__c = \'' + escapedStoreName  + '\'';
            
            if (objCartInfo.cartWeight > 0) {
                queryWhereString += ' AND  ccrz__MinWeight__c <= ' + objCartInfo.cartWeight + ' ';
                queryWhereString += ' AND  ccrz__MaxWeight__c >= ' + objCartInfo.cartWeight + ' ';
            }
            
            if (province.toUpperCase() == 'ONTARIO') {
                queryWhereString += ' AND AB2C_Ontario__c = true';
                queryWhereString += ' AND AB2C_GTA__c = ' + (escapedDistance <= shippingParameters.AB2C_GTA_Distance__c);
            } else {
                queryWhereString += ' AND AB2C_Rest_of_Canada__c = true';
            }
            
            queryWhereString += ' LIMIT 1';
            
            queryString += queryWhereString;
            
            system.debug('queryString' + queryString);
            
            //ccrz.ccLog.log(LoggingLevel.DEBUG, CLASSNAME, 'query: ' + querystring);
            List<SObject> sobjList = Database.query(queryString);
            //ccrz.ccLog.log(LoggingLevel.DEBUG, CLASSNAME, 'sbobjList: ' + sobjList);
            
            List<ccrz__E_ShippingRate__c> lstShippingRate = (List<ccrz__E_ShippingRate__c>)sobjList;
            lstShippingRate[0].Name = lstShippingRate[0].ccrz__Shipper__c + ' - ' + lstShippingRate[0].Name;
            
            if(objCartInfo.hasRug && !objCartInfo.hasOtherProduct){
                lstShippingRate[0].ccrz__ShippingRate__c = 0;
                lstShippingRate[0].Name = 'Alexanian Store - Free Rug Delivery';   
                
            }
            
        /*  if(objCartInfo.isOversizeRug && objCartInfo.hasRug){           
                if(shippingParameters.AB2C_Oversize_Rug_Shipping_Price__c > lstShippingRate[0].ccrz__ShippingRate__c){
                    lstShippingRate[0].ccrz__ShippingRate__c = shippingParameters.AB2C_Oversize_Rug_Shipping_Price__c;
                    lstShippingRate[0].Name = 'Alexanian Store - Oversize Rug';
                }
            }*/
            
            if(objCartInfo.hasOnlySampleProduct){
                lstShippingRate[0].ccrz__ShippingRate__c = shippingParameters.AB2C_Sample_Shipping_Price__c;
                lstShippingRate[0].Name = 'Alexanian Store - Sample Product';
            }
            
            
            system.debug('result' + sobjList);
            result.data = sobjList;
            result.success= true;
        } catch (Exception e) {
            result.success = false;
            ccrz.ccLog.log(LoggingLevel.ERROR, CLASSNAME, 'ERR:Error calculating Shipping: ' + e.getCause() + ' at line ' + e.getLineNumber());
        } finally {
            ccrz.ccLog.close(result);
        }
        
        return result;
    }
    
    
    private static List<ccrz__E_CartItem__c> getCartItem(String cartId){
        return [SELECT ID,ccrz__Product__r.ccrz__ProductWeight__c, 
                ccrz__Product__r.ccrz__ShippingWeight__c,ccrz__Quantity__c,
                ccrz__Product__c
                FROM ccrz__E_CartItem__c WHERE ccrz__Cart__c = : cartId AND ccrz__ProductType__c != 'Coupon'];
    }
    
    private static List<ccrz__E_ProductSpec__c> cartHasOnlySampleProduct(List<string> lstProductId){
        List<ccrz__E_ProductSpec__c> lstProductSpec = [SELECT ID FROM ccrz__E_ProductSpec__c 
                                                       WHERE ccrz__Product__c = : lstProductId
                                                       AND ccrz__SpecValue__c = 'SAMPLE'];
        return lstProductSpec;
    }
    
    
    private static List<ccrz__E_ProductCategory__c> cartHasRug(List<string> lstProductId, String rugCategoryId){
        List<string> rugCategoryIds = rugCategoryId.split(',');
        system.debug('rugCategoryId = ' + rugCategoryId);
        system.debug('lstProductId= '  + lstProductId);
        List<ccrz__E_ProductCategory__c> lstPC = [SELECT ID,ccrz__Product__c,ccrz__Product__r.id FROM ccrz__E_ProductCategory__c 
                                                  WHERE 
                                                  ccrz__Category__r.ccrz__CategoryID__c = : rugCategoryIds
                                                  AND ccrz__Product__c = : lstProductId];
        return lstPC;
    }
    
    private static Map<string,string> getCompositeProductId(List<string> lstProductId){
        List<ccrz__E_CompositeProduct__c> lstCP = [SELECT ccrz__Composite__c,ccrz__Component__c FROM ccrz__E_CompositeProduct__c WHERE ccrz__Component__c = : lstProductId];
        Map<string,string> mapComponentToComposite = new Map<string,string>();
        
        
        for(ccrz__E_CompositeProduct__c cp : lstCP){
            mapComponentToComposite.put(cp.ccrz__Component__c, cp.ccrz__Composite__c);
        }
        return mapComponentToComposite;
    }
    
    private static Boolean cartHasOversizeRug(List<string> lstProductRugId, AB2_Shipping_Parameters__c shippingParameters){
        Boolean isOversizeRug = false;
        
        List<ccrz__E_ProductSpec__c> lstProductSpec = [SELECT ID,ccrz__ProductID__c,AB2C_Product_Spec_SKU__c from ccrz__E_ProductSpec__c 
                                                       WHERE ccrz__Product__c  =: lstProductRugId AND AB2C_Spec_ID__c = 'SIZE'];
        
        for(ccrz__E_ProductSpec__c ps : lstProductSpec){
            string[] size = ps.AB2C_Product_Spec_SKU__c.split('x');
            if(size.size() == 2){
                String value0 = size[0].replaceAll('\\D','');
                String value1 = size[1].replaceAll('\\D','');
                decimal totalSize = decimal.valueof(value0) * decimal.valueof(value1);
                if(totalSize >= shippingParameters.AB2C_Oversized_Rug__c){
                    isOversizeRug = true;
                    break;
                }
            }
            
        }
        return isOversizeRug;
    }
    
    public static CartInformation getCartInformation(String cartId, string rugCategoryId, AB2_Shipping_Parameters__c shippingParameters){
        List<ccrz__E_CartItem__c> lstCartItem = getCartItem(cartId);
        
        CartInformation carti = new CartInformation();
        carti.lstProductId = new List<string>();
        Decimal cartWeight = 0;
        List<string> lstProductId = new List<string>();
        for(ccrz__E_CartItem__c ci : lstCartItem){
            lstProductId.add(ci.ccrz__Product__c);
        }        
        
        //Get Composite product from the Product in the Cart
        carti.mapComponentToComposite = getCompositeProductId(lstProductId);
        List<string> lstCheckForRugs = new List<string>();
        List<string> lstCompositeProducts = new List<string>();
        lstCheckForRugs.addAll(lstProductId);
        for(string key : carti.mapComponentToComposite.keySet()){
            string composite = carti.mapComponentToComposite.get(key);
            //Include Composite to check for Rugs
            lstCheckForRugs.add(composite);
            //List of composite in the cart
            lstCompositeProducts.add(composite);
        }
        
        //Check if the cart has Rugs
        List<ccrz__E_ProductCategory__c> lstRugs = cartHasRug(lstCheckForRugs, rugCategoryId);
        carti.hasRug = lstRugs.size() > 0 ? true : false;
        
        //Check if the cart has only Rugs
        Integer totalRugsInTheCart = 0;
        if(carti.hasRug){
            List<ccrz__E_CompositeProduct__c> lstRugsInTheCart = [SELECT id FROM ccrz__E_CompositeProduct__c WHERE ccrz__Composite__c =: lstCompositeProducts AND ccrz__Component__c =: lstCheckForRugs];            
            
            carti.hasOnlyRug = lstRugsInTheCart.size() == lstProductId.size() ? true : false;
            totalRugsInTheCart = lstRugsInTheCart.size();
        }
        
        //Check for oversize Rugs
        if(carti.hasRug){
            List<string> lstRugsId = new List<string>();
            for (ccrz__E_ProductCategory__c pc : lstRugs){
                for(string key :  carti.mapComponentToComposite.keySet()){
                    string composite =  carti.mapComponentToComposite.get(key);
                    if(pc.ccrz__Product__c == composite){
                        lstRugsId.add(key);
                    }    
                }
            }
            carti.isOversizeRug = cartHasOversizeRug(lstRugsId, shippingParameters);
        }
        
        List<ccrz__E_ProductSpec__c> lstProductSpecSample = cartHasOnlySampleProduct(lstProductId);
        carti.hasOnlySampleProduct = lstProductId.size() == lstProductSpecSample.size() ? true: false;
        carti.hasSampleProduct = lstProductSpecSample.size() > 0 ? true : false;
        carti.lstProductId = lstProductId;
        Integer lstR = lstRugs.size();    
        Integer totalRugsSample = totalRugsInTheCart + lstProductSpecSample.size();
        carti.hasOtherProduct = lstProductId.size() > lstR ? true : false;
        
        List<Id> rugsPresentInCart =  new List<Id>();
        for(ccrz__E_ProductCategory__c pc: lstRugs){
            rugsPresentInCart.add(pc.ccrz__Product__r.id);  
        }
        
        for(ccrz__E_CartItem__c ci : lstCartItem){
            if(!rugsPresentInCart.contains(carti.mapComponentToComposite.get(ci.ccrz__Product__r.id))){
                system.debug('2--'+ci.ccrz__Product__r.id);
                if(ci.ccrz__Product__r.ccrz__ProductWeight__c == null){
                    ci.ccrz__Product__r.ccrz__ProductWeight__c = 0;
                }
                Decimal cartItemWeight = ci.ccrz__Quantity__c * ci.ccrz__Product__r.ccrz__ProductWeight__c;
                carti.cartWeight += cartItemWeight;  
            }
        }        
        
        system.debug('3--'+ carti.cartWeight);
        return carti;
    }
    
    @RemoteAction
    global static ccrz.cc_RemoteActionResult updateCartImages(ccrz.cc_RemoteActionContext context, List<Map<String, Object>> cartItemList) {
        ccrz.cc_CallContext.initRemoteContext(context);
        ccrz.cc_RemoteActionResult response = new ccrz.cc_RemoteActionResult();
        response.success = false;
        
        try {
            Map<String, List<String>> cartItemMap = new Map<String, List<String>>();
            for (Map<String, Object> cartItem : cartItemList) {
                cartItemMap.put((String) cartItem.get('itemId'), new List<String>{
                    (String) cartItem.get('productImageUrl'), (String) cartItem.get('productSize')
                        });
            }
            
            List<ccrz__E_CartItem__c> cartItems = [SELECT Id, ccrz__ExtName__c, ccrz__AvailabilityMessage__c FROM ccrz__E_CartItem__c WHERE Id in :cartItemMap.keySet()];
            for (ccrz__E_CartItem__c cartItem : cartItems) {
                List<String> cartData = cartItemMap.get(cartItem.Id);
                cartItem.ccrz__ExtName__c = cartData.get(0);
                cartItem.ccrz__AvailabilityMessage__c = cartData.get(1);
            }
            update cartItems;
            response.success = true;
        } catch (Exception e) {
            response.data = e.getMessage();
            ccrz.ccLog.log(LoggingLevel.DEBUG,'AB2CCheckoutController','Exception: ' + e.getMessage());
        } finally {
            ccrz.ccLog.close(response);
        }
        return response;
    }
    
    @RemoteAction
    global static ccrz.cc_RemoteActionResult getCartPromos(ccrz.cc_RemoteActionContext context) {
        ccrz.cc_CallContext.initRemoteContext(context);
        ccrz.cc_RemoteActionResult response = new ccrz.cc_RemoteActionResult();
        response.success  = false;
        
        try {
            Map<String, Object> cartPromoResponse = new Map<String, Object>();
            ccrz.cc_RemoteActionResult promotionsResponse = AB2CPromotionService.getPromotions(context, 'cart', null);
            if (promotionsResponse.success) {
                cartPromoResponse.put('promotions', promotionsResponse.data);
            }
            
            response.data = cartPromoResponse;
            response.success  = true;
        } catch (Exception e) {
            response.data = e;
        }
        
        return response;
    }
    
    @RemoteAction
    global static ccrz.cc_RemoteActionResult updateProductInventory(ccrz.cc_RemoteActionContext context, String cartId) {
        ccrz.cc_CallContext.initRemoteContext(context);
        ccrz.cc_RemoteActionResult response = new ccrz.cc_RemoteActionResult();
        response.success = false;
        
        try {
            // Gather cart item SKUs
            List<ccrz__E_CartItem__c> cartItems = [SELECT ccrz__Product__r.ccrz__SKU__c, ccrz__Quantity__c 
                                                   FROM ccrz__E_CartItem__c 
                                                   WHERE ccrz__Cart__r.ccrz__EncryptedId__c = :cartId];
            Map<String, Decimal> skuQuantityMap = new Map<String, Decimal>();
            for (ccrz__E_CartItem__c cartItem : cartItems) {
                skuQuantityMap.put(cartItem.ccrz__Product__r.ccrz__SKU__c, cartItem.ccrz__Quantity__c);
            }
            
            // Check if product inventory exists for those items, and reduce the quantity if it exists
            List<ccrz__E_ProductInventoryItem__c> productInventoryItems = [SELECT Id, ccrz__ProductItem__r.ccrz__SKU__c, ccrz__QtyAvailable__c 
                                                                           FROM ccrz__E_ProductInventoryItem__c
                                                                           WHERE ccrz__ProductItem__r.ccrz__SKU__c IN :skuQuantityMap.keySet()];
            if (productInventoryItems.size() > 0) {
                for (ccrz__E_ProductInventoryItem__c inventoryItem : productInventoryItems) {
                    Decimal currentQuantity = inventoryItem.ccrz__QtyAvailable__c;
                    Decimal reduceQuantityBy = skuQuantityMap.get(inventoryItem.ccrz__ProductItem__r.ccrz__SKU__c);
                    inventoryItem.ccrz__QtyAvailable__c = Math.max(0, currentQuantity - reduceQuantityBy);
                }
                update productInventoryItems;
            }
            response.success = true;
        } catch (Exception e) {
            response.data = e.getMessage();
            ccrz.ccLog.log(LoggingLevel.DEBUG,'AB2CCheckoutController','Exception: ' + e.getMessage());
        } finally {
            ccrz.ccLog.close(response);
        }
        return response;
    }
}