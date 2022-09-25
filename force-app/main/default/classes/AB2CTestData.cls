@isTest public class AB2CTestData {
    public Map<String,Object> ccData;
    public ccrz__E_Product__c[] products;
    public ccrz__E_AccountGroup__c[] accountGroups;
    public ccrz__E_Pricelist__c[] priceLists;
    public ccrz__E_AccountGroupPriceList__c[] accountGroupPriceLists;
    public Account[] accounts;
    public Contact[] contacts;
    public User[] users;
    public ccrz__E_PriceListItem__c[] priceListItems;
    public ccrz__E_Category__c[] categories;
    public ccrz__E_Promo__c[] promos;
    public ccrz__E_Cart__c[] carts;
    public ccrz__E_CartItem__c[] cartItems;
    public ccrz__E_TaxRate__c[] taxs;
    public Account portalAccount;
    public ccrz__E_Product__c componentProduct, prod1;
    public ccrz__E_ShippingRate__c[] shippingRates;

    
    public AB2CTestData() {
        ccData = ccrz.ccApiTestData.setupData(new Map<String,Map<String,Object>>{
            ccrz.ccApiTestData.CONFIG_SETTINGS => new Map<String,Object>{
                'eff.enabled' => 'false'
            },
            ccrz.ccApiTestData.SERVICE_SETTINGS => new Map<String,Object>{
                'DefaultStore' => new Map<String, Object>{
                    'ccServiceRichContent' => 'c.AB2CServiceRichContent'
                }
            },
            ccrz.ccApiTestData.ACCOUNTGROUP_DATA => new Map<String,Object>{
                ccrz.ccApiTestData.ACCOUNTGROUP_LIST => new List<Map<String,Object>>{
                    new Map<String,Object>{
                        'name' => 'PortalAccount',
                        'ccrz__dataId__c' => 'portalAccountGroup',
                        'ccrz__PriceListSelectionMethod__c' => 'Best Price',
                        'ccrz__ThemeName__c' => 'CC Test Theme'
                    }
                }
            },
            ccrz.ccApiTestData.ACCOUNT_DATA => new Map<String,Object>{
                ccrz.ccApiTestData.ACCOUNT_LIST => new List<Map<String,Object>>{
                    new Map<String,Object>{
                        'name' => 'PortalAccount',
                        'ccrz__dataId__c' => 'portalAccount',
                        'ccrz__E_AccountGroup__r' => new ccrz__E_AccountGroup__c(ccrz__dataId__c = 'portalAccountGroup')
                    }
                }
            },
            ccrz.ccApiTestData.DATAOPTIONS => new Map<String,Object>{
            ccrz.ccApiTestData.LOADDEFAULTS => true
        }});

        Map<String,Object> agData = (Map<String,Object>)ccData.get(ccrz.ccApiTestData.ACCOUNTGROUP_DATA);
        accountGroups = (List<ccrz__E_AccountGroup__c>)agData.get(ccrz.ccApiTestData.ACCOUNTGROUP_LIST);
        Map<String,Object> plData = (Map<String,Object>)ccData.get(ccrz.ccApiTestData.PRICELIST_DATA);
        priceLists = (List<ccrz__E_Pricelist__c>)plData.get(ccrz.ccApiTestData.PRICELIST_LIST);
        Map<String,Object> agplData = (Map<String,Object>)ccData.get(ccrz.ccApiTestData.AGPL_DATA);
        accountGroupPriceLists = (List<ccrz__E_AccountGroupPriceList__c>)agplData.get(ccrz.ccApiTestData.AGPL_LIST);
        Map<String,Object> accData = (Map<String,Object>)ccData.get(ccrz.ccApiTestData.ACCOUNT_DATA);
        accounts = (List<Account>)accData.get(ccrz.ccApiTestData.ACCOUNT_LIST);        
        Map<String,Object> conData = (Map<String,Object>)ccData.get(ccrz.ccApiTestData.CONTACT_DATA);
        List<Contact> theList = (List<Contact>)conData.get(ccrz.ccApiTestData.CONTACT_LIST);       
        Map<String,Object> uData = (Map<String,Object>)ccData.get(ccrz.ccApiTestData.USER_DATA);
        users = (List<User>)uData.get(ccrz.ccApiTestData.USER_LIST); 

        Map<String,Object> catData = (Map<String,Object>)ccData.get(ccrz.ccApiTestData.CATEGORY_DATA);
        categories = (List<ccrz__E_Category__c>)catData.get(ccrz.ccApiTestData.CATEGORY_LIST);

        ccrz__E_Product__c prodRugBase = new ccrz__E_Product__c(
            Name = 'rugBase', ccrz__SKU__c = 'rugBase',
            ccrz__ProductStatus__c = 'Released', 
            ccrz__StartDate__c = Date.today() - 1,
            ccrz__EndDate__c = Date.today().addYears(10),
            ccrz__Quantityperunit__c = 1.0,
            ccrz__Taxable__c = true,
            ccrz__ShippingWeight__c = 30,
            ccrz__ProductWeight__c = 10
        );

        ccrz__E_Product__c prodRug = new ccrz__E_Product__c(
            Name = 'rug', ccrz__SKU__c = 'rug',
            ccrz__ProductStatus__c = 'Released', 
            ccrz__StartDate__c = Date.today() - 1,
            ccrz__EndDate__c = Date.today().addYears(10),
            ccrz__Quantityperunit__c = 1.0,
            ccrz__Taxable__c = true,
            ccrz__ShippingWeight__c = 30,
            ccrz__ProductWeight__c = 10
        );

        prod1 = new ccrz__E_Product__c(
            Name = 'foo', ccrz__SKU__c = 'prod1',
            ccrz__ProductStatus__c = 'Released', 
            ccrz__StartDate__c = Date.today() - 1,
            ccrz__EndDate__c = Date.today().addYears(10),
            ccrz__Quantityperunit__c = 1.0,
            ccrz__Taxable__c = true,
            ccrz__ShippingWeight__c = 30,
            ccrz__ProductWeight__c = 10,
            AB2C_Is_Component__c = false
        );
        ccrz__E_Product__c prod2 = new ccrz__E_Product__c(
            Name = 'bar', ccrz__SKU__c = 'prod2',
            ccrz__ProductStatus__c = 'Released', 
            ccrz__StartDate__c = Date.today() - 1,
            ccrz__EndDate__c = Date.today().addYears(10),
            ccrz__Quantityperunit__c = 1.0,
            ccrz__Taxable__c = true,
            ccrz__ShippingWeight__c = 15,
            ccrz__ProductWeight__c = 10
        );
        ccrz__E_Product__c shapeProd = new ccrz__E_Product__c(
            Name = 'fiz', ccrz__SKU__c = 'RECTANGLE',
            ccrz__ProductStatus__c = 'Released', 
            ccrz__StartDate__c = Date.today() - 1,
            ccrz__EndDate__c = Date.today().addYears(10),
            ccrz__Quantityperunit__c = 1.0
        );
        componentProduct = new ccrz__E_Product__c(
            Name = 'pop', ccrz__SKU__c = 'componentProduct',
            ccrz__ProductStatus__c = 'Released', 
            ccrz__StartDate__c = Date.today() - 1,
            ccrz__EndDate__c = Date.today().addYears(10),
            ccrz__Quantityperunit__c = 1.0,
            AB2C_Is_Component__c = true,
            ccrz__Taxable__c = true,
            ccrz__ProductWeight__c = 10,
            ccrz__ShippingWeight__c = 10
        );
        products = new List<ccrz__E_Product__c>{prodRugBase,prodRug,prod1, prod2, shapeProd, componentProduct};

        ccrz__E_PriceListItem__c pli1 = new ccrz__E_PriceListItem__c(
            ccrz__Price__c = 1, ccrz__Pricelist__c = priceLists[0].Id,
            ccrz__Product__r = new ccrz__E_Product__c(ccrz__SKU__c = 'prod1'),
            ccrz__StartDate__c = Date.today() - 1,
            ccrz__EndDate__c = Date.today().addYears(10)
        );
        priceListItems = new ccrz__E_PriceListItem__c[] {pli1};

        ccrz__E_ProductIndex__c pindex1 = new ccrz__E_ProductIndex__c(
            ccrz__Active__c = true, ccrz__IndexCurrency__c = 'USD',
            ccrz__IndexPrice__c = '1', ccrz__IndexType__c = 'U0VBUkNI',
            ccrz__Product__r = new ccrz__E_Product__c(ccrz__SKU__c = 'prod1'),
            ccrz__PriceLists__c = priceLists[0].Id, ccrz__ProductName__c = 'prod1',
            ccrz__ProductStartDate__c = Date.today() - 1, ccrz__ProductStatus__c = 'Released',
            ccrz__ProductEndDate__c = Date.today().addYears(10),
            ccrz__SKU__c = 'prod1', ccrz__LastIndex__c = true
        );
        ccrz__E_ProductIndex__c pindex2 = new ccrz__E_ProductIndex__c(
            ccrz__Active__c = true, ccrz__IndexCurrency__c = 'USD',
            ccrz__IndexPrice__c = '1', ccrz__IndexType__c = 'U0VBUkNI',
            ccrz__Product__r = new ccrz__E_Product__c(ccrz__SKU__c = 'RECTANGLE'),
            ccrz__ProductName__c = 'RECTANGLE',
            ccrz__ProductStartDate__c = Date.today() - 1, ccrz__ProductStatus__c = 'Released',
            ccrz__ProductEndDate__c = Date.today().addYears(10),
            ccrz__SKU__c = 'RECTANGLE', ccrz__LastIndex__c = true
        );

        ccrz__E_Promo__c promo1 = new ccrz__E_Promo__c(
            ccrz__PageLocation__c = 'productList',
            ccrz__Enabled__c = true,
            ccrz__StartDate__c = Date.today() - 1,
            ccrz__EndDate__c = Date.today().addYears(10),
            ccrz__StorefrontMS__c = 'DefaultStore',
            ccrz__Category__c = categories[0].Id, AB2C_Category__c = categories[0].Id,
            ccrz__Sequence__c = 1,
            Promotion_Group_ID__c = 'someGroup',
            ccrz__LinkType__c = 'Category'
        );
        ccrz__E_Promo__c promo2 = new ccrz__E_Promo__c(
            ccrz__PageLocation__c = 'home',
            ccrz__Enabled__c = true,
            ccrz__StartDate__c = Date.today() - 1,
            ccrz__EndDate__c = Date.today().addYears(10),
            ccrz__StorefrontMS__c = 'DefaultStore',
            ccrz__Sequence__c = 2,
            Promotion_Group_ID__c = 'someGroup',
            ccrz__LinkType__c = 'Category'
        );
        promos = new ccrz__E_Promo__c[]{promo1, promo2};

        ccrz__E_Cart__c cart1 = new ccrz__E_Cart__c(
            ccrz__EncryptedId__c = 'cart1',
            ccrz__CartId__c = 'cart1',
            ccrz__CartStatus__c = 'Open'
        );
        carts = new ccrz__E_Cart__c[]{cart1};

        ccrz__E_CartItem__c citem1 = new ccrz__E_CartItem__c(
            ccrz__Product__r = new ccrz__E_Product__c(ccrz__SKU__c = 'prod1'),
            ccrz__Price__c = 1.23, ccrz__ItemLabel__c = 'RECT-0025x0030',
            ccrz__cartItemType__c = 'Major',
            ccrz__Cart__r = new ccrz__E_Cart__c(ccrz__CartId__c = 'cart1')
        );
        ccrz__E_CartItem__c citem2 = new ccrz__E_CartItem__c(
            ccrz__Product__r = new ccrz__E_Product__c(ccrz__SKU__c = 'RECTANGLE'),
            ccrz__Price__c = 1.23, ccrz__cartItemType__c = 'Minor',
            ccrz__Cart__r = new ccrz__E_Cart__c(ccrz__CartId__c = 'cart1')
        );
        ccrz__E_CartItem__c citem3 = new ccrz__E_CartItem__c(
            ccrz__Product__r = new ccrz__E_Product__c(ccrz__SKU__c = 'rug'),
            ccrz__Price__c = 1.23, ccrz__Quantity__c = 10, ccrz__cartItemType__c = 'Major',
            ccrz__Cart__r = new ccrz__E_Cart__c(ccrz__CartId__c = 'cart1')
        );
        cartItems = new ccrz__E_CartItem__c[]{citem1, citem2,citem3};

        ccrz__E_CompositeProduct__c compositeProduct = new ccrz__E_CompositeProduct__c(
            ccrz__Component__r = new ccrz__E_Product__c(ccrz__SKU__c = 'rug'),
            ccrz__Composite__r = new ccrz__E_Product__c(ccrz__SKU__c = 'rugBase'),
            ccrz__CompositeProductId__c = 'UniqueProduct',
            ccrz__Quantity__c = 1,
            ccrz__Sequence__c = 1
        );

        ccrz__E_TaxRate__c tax = new ccrz__E_TaxRate__c(
            ccrz__CountryCode__c = 'CA',
            ccrz__StateCode__c = 'ON',
            ccrz__TaxRate__c = 5,
            ccrz__TaxRateId__c = 'CA_ON_HST'
        );
        taxs = new ccrz__E_TaxRate__c[]{tax};


        ccrz__E_ShippingRate__c shippingRate1 = new ccrz__E_ShippingRate__c(
            AB2C_GTA__c = false,
            AB2C_Ontario__c = false,
            AB2C_Rest_of_Canada__c = true,
            ccrz__CurrencyISOCode__c = 'CAD',
            ccrz__MinWeight__c = 0,
            ccrz__MaxWeight__c = 750,
            ccrz__Shipper__c = 'AlexanianStore',
            ccrz__ShippingRate__c = 99,
            ccrz__Storefront__c = 'AlexanianStore'
        );

        ccrz__E_ShippingRate__c shippingRate2 = new ccrz__E_ShippingRate__c(
            AB2C_GTA__c = true,
            AB2C_Ontario__c = true,
            AB2C_Rest_of_Canada__c = false,
            ccrz__CurrencyISOCode__c = 'CAD',
            ccrz__MinWeight__c = 0,
            ccrz__MaxWeight__c = 750,
            ccrz__Shipper__c = 'AlexanianStore',
            ccrz__ShippingRate__c = 9,
            ccrz__Storefront__c = 'AlexanianStore'
        );

        shippingRates = new ccrz__E_ShippingRate__c[]{shippingRate1,shippingRate2};


        ccrz__E_Category__c category = new ccrz__E_Category__c(
            ccrz__CategoryID__c = 'Rugs01',
            ccrz__SEOId__c = 'AreaRugs',
            ccrz__Sequence__c = 1,
            ccrz__StartDate__c = Date.today() - 1,
            ccrz__EndDate__c = Date.today().addYears(10)
        );

        ccrz__E_ProductCategory__c productCategory = new ccrz__E_ProductCategory__c(
            ccrz__IsCanonicalPath__c = true,
            ccrz__Category__r =  new ccrz__E_Category__c(ccrz__SEOId__c = 'AreaRugs'),
            ccrz__Product__r =  new ccrz__E_Product__c(ccrz__SKU__c = 'rug'),
            ccrz__StartDate__c = Date.today() - 1
        );

        


        AB2_Shipping_Parameters__c customShippingParameter = new AB2_Shipping_Parameters__c(
            AB2C_GTA_Distance__c = 10,
            AB2C_Oversized_Rug__c = 10,
            AB2C_Oversize_Rug_Shipping_Price__c = 1,
            AB2C_Rug_Category__c = 'Rugs01', 
            AB2C_Sample_Shipping_Price__c = 1 
        );

        insert new SObject[]{
            prod1, prod2, shapeProd, componentProduct,prodRugBase,prodRug,
            pli1,
            pindex1, pindex2,
            promo1, promo2,
            cart1,
            citem1, citem2,citem3,
            tax,
            shippingRate1,shippingRate2
        };

        insert new SObject[]{
            customShippingParameter,
            category,productCategory
        };

        citem2.ccrz__ParentCartItem__r = citem1;
        citem2.ccrz__ParentCartItem__c = citem1.id;
        
        update citem2;
        
    }

    @isTest static void testApi(){
        AB2CTestData data = new AB2CTestData();

        // System.runAs(data.users[0]){
        //     ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        //     context.storefront = 'DefaultStore';
        //     context.userIsoCode = 'USD';
        //     ccrz.cc_CallContext.initRemoteContext(context);
            
        //     Map<String, Object> productRequest = new Map<String, Object>{
        //         ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
        //         ccrz.ccAPIProduct.PRODUCTSKULIST => new Set<String>{'prod1'},
        //         ccrz.ccApiProduct.PARAM_INCLUDE_PRICING => true
        //     };
    
        //     Map<String, Object> productResponse = ccrz.ccAPIProduct.fetch(productRequest);
        //     System.debug(JSON.serialize(productResponse));
        //     System.debug(JSON.serialize(data.ccData));    
        // }

        ccrz.cc_RemoteActionContext context = new ccrz.cc_RemoteActionContext();
        context.storefront = 'DefaultStore';
        context.userIsoCode = 'USD';
        ccrz.cc_CallContext.initRemoteContext(context);

        Map<String, Object> productRequest = new Map<String, Object>{
            ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
            ccrz.ccAPIProduct.PRODUCTSKULIST => new Set<String>{'prod1'},
            ccrz.ccApiProduct.PARAM_INCLUDE_PRICING => true
        };

        Map<String, Object> productResponse = ccrz.ccAPIProduct.fetch(productRequest);
        System.debug(JSON.serialize(productResponse));
        System.debug(JSON.serialize(data.ccData));    

    }
}