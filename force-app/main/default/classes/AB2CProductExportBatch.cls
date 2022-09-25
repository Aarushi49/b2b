public with sharing class AB2CProductExportBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable, Database.AllowsCallouts {
    Map<String, List<String>> productImageMap;
    Set<String> PARENT_CATEGORIES;

    public AB2CProductExportBatch() {
    }

    public void execute(SchedulableContext SC){
        Database.executeBatch(this);
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        // Build Cloudinary image map
        productImageMap = new Map<String, List<String>>();
        PARENT_CATEGORIES = new Set<String>{'Carpet', 'Window Coverings', 'Flooring', 'Area Rugs'};
        getCloudinaryImages();

        system.debug('productImageMap ==>'+JSON.serialize(productImageMap));

        return Database.getQueryLocator([SELECT AB2C_Composite_SKU__c, AB2C_Component_SKU__c, ccrz__Component__r.Name, ccrz__Composite__r.Name,
                                            ccrz__Composite__r.ccrz__ShortDescRT__c, ccrz__Composite__r.ccrz__LongDescRT__c,
                                            ccrz__Composite__r.ccrz__SEOId__c, ccrz__Component__r.ccrz__Quantityperunit__c,
                                            ccrz__Component__r.AB2C_Show_Square_Footage_Calculator__c  
                                        FROM ccrz__E_CompositeProduct__c 
                                        WHERE ccrz__Composite__r.ccrz__ProductStatus__c IN ('Released', 'Not Orderable')
                                            AND AB2C_Component_SKU__c != NULL
                                        ORDER BY AB2C_Component_SKU__c]);
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        Map<String, ComponentProduct> componentProductMap = new Map<String, ComponentProduct>();
        List<ccrz__E_CompositeProduct__c> scopeProducts = (List<ccrz__E_CompositeProduct__c>)scope;
        List<String> scopeProductSkus = new List<String>();

        // These maps collect data that live on aggregate product
        Map<String, String> parentCategoryMap = new Map<String, String>();
        Map<String, Set<String>> otherCategoryMap = new Map<String, Set<String>>();
        Map<String, String> constructionMap = new Map<String, String>();
        Map<String, String> featuresMap = new Map<String, String>();
        Map<String, String> appearanceMap = new Map<String, String>();

        // CC Products
        for (ccrz__E_CompositeProduct__c compositeProduct : scopeProducts){
            ComponentProduct componentProduct = new ComponentProduct();
            componentProduct.parentSku = compositeProduct.AB2C_Composite_SKU__c;
            componentProduct.parentName = compositeProduct.ccrz__Composite__r.Name;
            componentProduct.sku = compositeProduct.AB2C_Component_SKU__c;
            componentProduct.name = compositeProduct.ccrz__Component__r.Name;
            componentProduct.shortDesc = compositeProduct.ccrz__Composite__r.ccrz__ShortDescRT__c;
            componentProduct.longDesc = compositeProduct.ccrz__Composite__r.ccrz__LongDescRT__c;
            componentProduct.seoId = compositeProduct.ccrz__Composite__r.ccrz__SEOId__c;
            componentProduct.quantityPerUnit = compositeProduct.ccrz__Component__r.ccrz__Quantityperunit__c;
            componentProduct.isFlooring = compositeProduct.ccrz__Component__r.AB2C_Show_Square_Footage_Calculator__c;

            scopeProductSkus.add(compositeProduct.AB2C_Component_SKU__c);
            parentCategoryMap.put(compositeProduct.AB2C_Composite_SKU__c, null);
            otherCategoryMap.put(compositeProduct.AB2C_Composite_SKU__c, new Set<String>());
            constructionMap.put(compositeProduct.AB2C_Composite_SKU__c, null);
            componentProductMap.put(compositeProduct.AB2C_Component_SKU__c, componentProduct);
        }

        // CC Product Specs
        List<ccrz__E_ProductSpec__c> specs = [SELECT ccrz__Product__r.ccrz__SKU__c, AB2C_Spec_Name__c, AB2C_Product_Spec_SKU__c, ccrz__SpecValue__c 
                                                FROM ccrz__E_ProductSpec__c 
                                                WHERE AB2C_Spec_Name__c IN ('COLOUR', 'SIZE', 'MATERIAL', 'BRAND', 'LENGTH', 'WIDTH', 'COLLECTION')
                                                AND ccrz__Product__r.ccrz__SKU__c IN :scopeProductSkus];
        for (ccrz__E_ProductSpec__c ps : specs) {
            ComponentProduct componentProduct = getComponentProduct(componentProductMap, ps.ccrz__Product__r.ccrz__SKU__c);
            if ('Colour'.equals(ps.AB2C_Spec_Name__c)) {
                componentProduct.swatchSku = ps.AB2C_Product_Spec_SKU__c;
                componentProduct.colour = ps.ccrz__SpecValue__c;
            } else if ('Size'.equals(ps.AB2C_Spec_Name__c)) {
                componentProduct.sizeSku = ps.AB2C_Product_Spec_SKU__c;
                componentProduct.size = ps.ccrz__SpecValue__c;
            } else if ('Brand'.equals(ps.AB2C_Spec_Name__c)) {
                componentProduct.brand = ps.ccrz__SpecValue__c;
            } else if ('Material'.equals(ps.AB2C_Spec_Name__c)) {
                componentProduct.material = ps.ccrz__SpecValue__c;
            } else if ('Length'.equals(ps.AB2C_Spec_Name__c)) {
                componentProduct.length = ps.ccrz__SpecValue__c;
            } else if ('Width'.equals(ps.AB2C_Spec_Name__c)) {
                componentProduct.width = ps.ccrz__SpecValue__c;
            } else if ('Collection'.equals(ps.AB2C_Spec_Name__c)) {
                componentProduct.collection = ps.ccrz__SpecValue__c;
            }
            componentProductMap.put(ps.ccrz__Product__r.ccrz__SKU__c, componentProduct);
        }

        // Construction specs live on the aggregate product
        List<ccrz__E_ProductSpec__c> constructionSpecs = [SELECT ccrz__Product__r.ccrz__SKU__c, AB2C_Spec_Value_RT__c, AB2C_Spec_Name__c
                                                            FROM ccrz__E_ProductSpec__c 
                                                            WHERE AB2C_Spec_Name__c IN ('CONSTRUCTION', 'APPEARANCE', 'FEATURES')
                                                            AND ccrz__Product__r.ccrz__SKU__c IN :constructionMap.keySet()];
        for (ccrz__E_ProductSpec__c ps : constructionSpecs) {
            if ('Construction'.equals(ps.AB2C_Spec_Name__c)) {
                constructionMap.put(ps.ccrz__Product__r.ccrz__SKU__c, ps.AB2C_Spec_Value_RT__c);
            } else if ('Appearance'.equals(ps.AB2C_Spec_Name__c)) {
                appearanceMap.put(ps.ccrz__Product__r.ccrz__SKU__c, ps.AB2C_Spec_Value_RT__c);
            } else if ('Features'.equals(ps.AB2C_Spec_Name__c)) {
                featuresMap.put(ps.ccrz__Product__r.ccrz__SKU__c, ps.AB2C_Spec_Value_RT__c);
            }
        }

        // CC Price List Items
        List<ccrz__E_PriceListItem__c> priceListItems = [SELECT ccrz__Product__r.ccrz__SKU__c, AB2C_Unit_Price__c, ccrz__Price__c, AB2C_Is_Sale__c 
                                                            FROM ccrz__E_PriceListItem__c 
                                                            WHERE ccrz__Price__c > 0 
                                                                AND ccrz__StartDate__c <= TODAY 
                                                                AND ccrz__EndDate__c > TODAY 
                                                                AND ccrz__Product__r.ccrz__SKU__c != NULL 
                                                                AND ccrz__Product__r.ccrz__SKU__c IN :scopeProductSkus];
        for (ccrz__E_PriceListItem__c pli : priceListItems) {
            ComponentProduct componentProduct = getComponentProduct(componentProductMap, pli.ccrz__Product__r.ccrz__SKU__c);
            if (pli.AB2C_Is_Sale__c) {
                componentProduct.priceSale = pli.ccrz__Price__c;
                componentProduct.priceUnit = pli.AB2C_Unit_Price__c;
            } else {
                componentProduct.priceStandard = pli.ccrz__Price__c;
                if (componentProduct.priceUnit < 1) {
                    componentProduct.priceUnit = pli.AB2C_Unit_Price__c;
                }
            }
            componentProductMap.put(pli.ccrz__Product__r.ccrz__SKU__c, componentProduct);
        }

        // CC Prouct Categories
        List<ccrz__E_ProductCategory__c> productCategories = [SELECT ccrz__Product__r.ccrz__SKU__c, ccrz__Category__r.Name 
                                                                FROM ccrz__E_ProductCategory__c 
                                                                WHERE ccrz__Product__r.ccrz__SKU__c IN :parentCategoryMap.keySet()];
        for (ccrz__E_ProductCategory__c pc : productCategories) {
            String parentSku = pc.ccrz__Product__r.ccrz__SKU__c;
            String category = pc.ccrz__Category__r.Name;
            if (PARENT_CATEGORIES.contains(category)) {
                parentCategoryMap.put(parentSku, category);
            } else {
                Set<String> otherCategories = otherCategoryMap.get(parentSku);
                otherCategories.add(category);
                otherCategoryMap.put(parentSku, otherCategories);
            }
        }

        // Bring in data from aggregate product
        for (ComponentProduct cp : componentProductMap.values()) {
            cp.parentCategory = parentCategoryMap.get(cp.parentSku);
            cp.otherCategories = otherCategoryMap.get(cp.parentSku);
            cp.construction = constructionMap.get(cp.parentSku);
            cp.features = featuresMap.get(cp.parentSku);
            cp.appearance = appearanceMap.get(cp.parentSku);
        }

        // CC Prouct Inventory Item
        List<ccrz__E_ProductInventoryItem__c> productInventories = [SELECT ccrz__ProductItem__r.ccrz__SKU__c, ccrz__QtyAvailable__c 
                        FROM ccrz__E_ProductInventoryItem__c
                        WHERE ccrz__ProductItem__r.ccrz__SKU__c IN :scopeProductSkus];
        for (ccrz__E_ProductInventoryItem__c pi : productInventories) {
            ComponentProduct componentProduct = getComponentProduct(componentProductMap, pi.ccrz__ProductItem__r.ccrz__SKU__c);
            componentProduct.inventory = pi.ccrz__QtyAvailable__c;
            componentProductMap.put(pi.ccrz__ProductItem__r.ccrz__SKU__c, componentProduct);
        }

        // Update new Product Feed records
        List<Product_Feed__c> productFeedsToInsert = new List<Product_Feed__c>();
        for (ComponentProduct cp : componentProductMap.values()) {
            productFeedsToInsert.add(mapComponentProductToProductFeed(cp));
        }
        Database.upsert(productFeedsToInsert, Product_Feed__c.mpn__c, false);
    }

    /**
     * Convert a ComponentProduct object to Product_Feed__c record
     */
    private Product_Feed__c mapComponentProductToProductFeed(ComponentProduct cp) {
        Product_Feed__c pf = new Product_Feed__c();
        pf.Name = cp.sku; // Product SKU
        pf.mpn__c = cp.sku; // Product SKU
        pf.title__c = cp.name; // Product Name
        pf.custom_label_0__c = cp.parentName; // Parent product name
        pf.item_group_id__c = cp.parentSku; // Parent product SKU
        pf.description__c = stripRichText(cp.shortDesc); // Product short description
        pf.description_1__c = stripRichText(cp.longDesc); // Product long description
        pf.description_2__c = stripRichText(cp.appearance); // Appearance (product spec rich text)
        pf.description_3__c = stripRichText(cp.features); // Features (product spec rich text)
        pf.product_type__c = stripRichText(cp.construction); // Construction (product spec rich text)
        pf.link__c = cp.getProductLink();
        pf.availability__c = (cp.inventory == null || cp.inventory > 0) ? 'in stock' : 'out of stock';
        pf.Stock__c = cp.inventory;
        pf.price__c = cp.priceStandard;
        pf.sale_price__c = cp.priceSale;
        pf.color__c = cp.colour;
        pf.size__c = cp.size;
        pf.length__c = cp.length;
        pf.width__c = cp.width;
        pf.collection__c = cp.collection;
        pf.condition__c = 'new';

        if (cp.isFlooring) {
            pf.unit_pricing_base_measure__c = cp.quantityPerUnit;
            pf.unit_pricing_measure__c = cp.priceUnit;
            pf.brand__c = cp.brand;
            pf.material__c = stripRichText(cp.construction);
        } else {
            pf.brand__c = cp.name;
            pf.material__c = cp.material;
        }

        // Prouct categories
        pf.google_product_category__c = cp.parentCategory; // Product parent category (area rug, carpet, flooring or window coverings)
        if (cp.otherCategories != null && cp.otherCategories.size() > 0) {
            List<String> otherCategories = new List<String>(cp.otherCategories);
            otherCategories.sort();
            pf.custom_label_1__c = String.join(otherCategories, ', '); // Other categories
        } 

        // Product images
        String imageKey = (cp.parentSku + '-' + cp.swatchSku).toLowerCase();
        if (productImageMap.containsKey(imageKey)) {
            List<String> urls = productImageMap.get(imageKey);

            // Set top-down image if it exists
            for (String url : urls) {
                if (url.contains('-top-') || url.contains('-top_')) {
                    pf.top_image_link__c = url;
                }
            }

            if (urls.size() > 0) pf.image_link__c = urls.get(0);
            if (urls.size() > 1) pf.additional_image_link__c = urls.get(1);
            if (urls.size() > 2) pf.additional_image_link_1__c = urls.get(2);
            if (urls.size() > 3) pf.additional_image_link_2__c = urls.get(3);
            if (urls.size() > 4) pf.additional_image_link_3__c = urls.get(4);
            if (urls.size() > 5) pf.additional_image_link_4__c = urls.get(5);
        }
        return pf;
    }

    private ComponentProduct getComponentProduct(Map<String, ComponentProduct> componentProductMap, String sku) {
        if (componentProductMap.containsKey(sku)) {
            return componentProductMap.get(sku);
        } else {
            return new ComponentProduct();
        }
    }

    private String stripRichText(String input) {
        if (input != null) {
            return input.unescapeHtml4().replaceAll('<[/a-zAZ0-9]*>', ' ').trim().replaceAll(' +', ' ');
        }
        return null;
    }

    /**
     * Download all image resources from Cloudinary with the 'product-image' tag
     */
    private void getCloudinaryImages() {
        String nextCursor = null;
        integer i=0;
        do {
            HttpRequest req = new HttpRequest();
            req.setHeader('Content-Type', 'application/json'); 
            req.setMethod('GET');
            String username = '342314592926168';
            String password = 'MB_iLEIU5f7SYdp12j3IHaSp8Fg';
            Blob headerValue = Blob.valueOf(username + ':' + password);
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            req.setHeader('Authorization', authorizationHeader);
            String endpoint = 'https://api.cloudinary.com/v1_1/alexanian/resources/image/tags/product-image?max_results=500&context=true';
            if (nextCursor == null) {
                req.setEndpoint(endpoint); 
            } else {
                req.setEndpoint(endpoint + '&next_cursor=' + nextCursor);
            } 
        
            List<Object> results = new List<Object>();
            HttpResponse res = new Http().send(req);
            i++;
            system.debug('res ==>'+i);
            system.debug(res.getBody());  
            system.debug(res.getBody().containsignorecase('mel-MLCREU'));  


            Map<String, Object> fieldMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> resources = (List<Object>) fieldMap.get('resources');
            if (results != null && resources != null) {
                results.addall(resources);
            }

            mapCloudinaryImages(results);
            nextCursor = (String) fieldMap.get('next_cursor');
        } while (nextCursor != null && i<40);
    }
    
    /**
     * Parse and list all Cloudinary resources for easy access, mapped by parentSku-swatchSku
     */
    private void mapCloudinaryImages(List<Object> resources) {
        for (Object resourceObj : resources) {
            Map<String, Object> resource = (Map<String, Object>) resourceObj;
            Map<String, Object> context = (Map<String, Object>) resource.get('context');
            String url = (String) resource.get('secure_url');
            String publicId = (String) resource.get('public_id');
            if (publicId != null) {
                String parentSku = publicId.split('/')[2];
                if (context != null) {
                    Map<String, Object> custom = (Map<String, Object>) context.get('custom');
                    if (custom != null) {
                        String specSku = (String) custom.get('spec_sku');
                        String imageKey = (parentSku + '-' + specSku).toLowerCase();
                        List<String> urls;
                        if (productImageMap.containsKey(imageKey)) {
                            urls = productImageMap.get(imageKey);
                        } else {
                            urls = new List<String>();
                        }
                        urls.add(url);
                        productImageMap.put(imageKey, urls);
                    }
                }
            }
        }
    }

    public void finish(Database.BatchableContext c) {

    }

    class ComponentProduct {
        // CC Products
        String sku;
        String name;
        String shortDesc;
        String longDesc;
        String seoId;
        Decimal quantityPerUnit;
        String parentSku;
        String parentName;
        Boolean isFlooring;
    
        // CC Product Specs
        String length;
        String width;
        String collection;
        String construction;
        String features;
        String appearance;
        String brand;
        String colour;
        String size;
        String material;
        String swatchSku;
        String sizeSku;
    
        // CC Price List
        Decimal priceStandard;
        Decimal priceSale;
        Decimal priceUnit;
    
        // CC Product Category
        String parentCategory;
        Set<String> otherCategories;

        // CC Product Inventory
        Decimal inventory;
        
        public String getProductLink() {
            String urlSku = parentSku == null ? sku : parentSku;
            String urlSwatch = swatchSku == null ? '' : '&styleSKU=' + swatchSku;
            String urlSize = sizeSku == null ? '' : '&sizeSKU=' + sizeSku;
            return 'https://www.alexanian.com/' + seoId + '/?sku=' + urlSku + urlSwatch + urlSize;
        }
    }    
}