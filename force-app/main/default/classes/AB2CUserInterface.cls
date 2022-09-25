/*
* Full source for 004 can be found here: 
* https://cloudcraze.atlassian.net/wiki/spaces/B2BDOCS411/pages/979075993/ccrz.cc+hk+UserInterface
*/
global virtual class AB2CUserInterface extends ccrz.cc_hk_UserInterface.v004 {
    private String CC_JAVASCRIPT_FRAMEWORK = 'ccrz__CC_Javascript_Framework';
    private String CCRZ_JS = 'ccrz__CCRZ_JS';
    private String THEME = 'CC_Theme_Alexanian';

    global AB2CUserInterface(){
        super();
    }

    global virtual override String standardIncludes(){
        String retElements = '';
        // Head JS includes
        // 2021-11-03 Charles 22364: Migrate Google Tag Manager to be included here instead
        retElements += '<script>\n';
        retElements += '(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({"gtm.start":\n';
        retElements += 'new Date().getTime(),event:"gtm.js"});var f=d.getElementsByTagName(s)[0],\n';
        retElements += 'j=d.createElement(s),dl=l!="dataLayer"?"&l="+l:"";j.async=true;j.src=\n';
        retElements += '"https://www.googletagmanager.com/gtm.js?id="+i+dl;f.parentNode.insertBefore(j,f);\n';
        retElements += '})(window,document,"script","dataLayer","GTM-W5W99KL");\n';
        retElements += '</script>\n';

        retElements +=
            '<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.4.1/jquery.min.js" integrity="sha256-CSXorXvZcTkaix6Yvo6HppcZGetbYMGWSFlBw8HfCJo=" crossorigin="anonymous"></script>\n'+
            '<script type="text/javascript" src="'+resourcePath(CCRZ_JS, 'v004/classic/jquery-ui-custom.1.12.1.min.js')+'"></script>\n'+
            '<script type="text/javascript" src="'+resourcePath(CCRZ_JS, 'v004/classic/jquery.cookie-1.4.1.js')+'"></script>\n'+
            '<script type="text/javascript" src="'+resourcePath(CCRZ_JS, 'v004/classic/jquery.hoverIntent-1.10.0.min.js')+'"></script>\n'+
            '<script type="text/javascript" src="'+resourcePath(CCRZ_JS, 'v004/classic/jquery-vertical-accordion-menu/js/jquery.dcjqaccordion.2.7.min.js')+'"></script>\n'+
            '<script type="text/javascript" src="'+resourcePath(CCRZ_JS, 'v004/classic/jquery.validate.1.19.1.min.js')+'"></script>\n'+
            '<script type="text/javascript" src="'+resourcePath(CCRZ_JS, 'v004/classic/underscore-1.9.2.min.js')+'"></script>\n'+
            '<script type="text/javascript" src="'+resourcePath(CCRZ_JS, 'v004/classic/backbone-1.4.0.min.js')+'"></script>\n'+
            '<script type="text/javascript" src="'+resourcePath(CCRZ_JS, 'v004/classic/modernizr-2.8.3.js')+'"></script>\n'+
            '<script type="text/javascript" src="'+resourcePath(CCRZ_JS, 'v004/classic/accounting-0.4.2.min.js')+'"></script>\n'+
            '<script type="text/javascript" src="'+resourcePath(CCRZ_JS, 'v004/classic/handlebars-v4.7.2.min.js')+'"></script>\n'+
            '<script type="text/javascript" src="'+resourcePath(CCRZ_JS, 'v004/classic/js-image-slider-2016.9.27.js')+'"></script>\n'+
            '<script type="text/javascript" src="'+resourcePath(CCRZ_JS, 'v004/classic/bootstrap-datepicker-1.9.0.min.js')+'"></script>\n'+
            '<script type="text/javascript" src="'+resourcePath(CCRZ_JS, 'v004/classic/js2form.2011.9.19.js')+'"></script>\n'+
            '<script type="text/javascript" src="'+resourcePath(CCRZ_JS, 'v004/classic/form2js-2010.9.9.js')+'"></script>\n'+
            '<script type="text/javascript" src="'+resourcePath(CCRZ_JS, 'v004/classic/backbone.paginator.2.0.8.min.js')+'"></script>\n';

        // Head CSS includes
        retElements += ccrzIncludes() +
            '<link href="https://fonts.googleapis.com/css?family=Roboto:400,500,700&display=swap" rel="stylesheet"></link>\n' + 
            '<link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css" integrity="sha384-Vkoo8x4CGsO3+Hhxv8T/Q5PaXtkKtu6ug5TOeNV6gBiFeWPGFN9MuhOf23Q9Ifjh" crossorigin="anonymous"></link>\n';
        
        // Page specific includes
        if (urlContains('ccrz__ProductList')) {
            retElements += 
                '<script type="text/javascript" src="'+resourcePath(CCRZ_JS, 'v004/boot3/nouislider.14.1.1.js')+'"></script>\n' + 
                '<link type="text/css" rel="stylesheet" href="'+resourcePath(CCRZ_JS, 'v004/boot3/css/nouislider.min.css')+'" />\n' +
                '<link type="text/css" rel="stylesheet" href="'+resourcePath(THEME, 'css3/pages/products/product-list.css')+'" />\n';
        } else if (urlContains('ccrz__ProductDetails')) {
            retElements += 
                '<script type="text/javascript" src="https://www.roomvo.com/static/scripts/b2b/alexanian.js" async></script>\n';
        } else if (urlContains('pagekey=static') || urlContains('pagekey=category')) {
            retElements += 
                '<link type="text/css" rel="stylesheet" href="'+resourcePath(THEME, 'css3/pages/static.css')+'" />\n';
                if (urlContains('content=flexiti')) {
                    retElements += 
                        '<script type="text/javascript" src="https://onlineapi.flexiti.fi/public/libs/SDK/js/flexiti-sdk-0.0.1.js"></script>\n' +
                        '<script type="text/javascript" src="'+resourcePath(THEME, 'js/flexiti/thickbox.js')+'"></script>\n' +
                        '<link type="text/css" rel="stylesheet" href="'+resourcePath(THEME, 'js/flexiti/thickbox.css')+'" media="screen"/>\n';
                } else if (urlContains('content=reviews')) {
                    retElements += 
                        '<script type="text/javascript" src="'+resourcePath(THEME, 'js/reviews.js')+'"></script>\n';
                } else if (urlContains('content=roomvo')) {
                    retElements += 
                        '<script type="text/javascript" src="https://www.roomvo.com/static/scripts/b2b/alexanian.js" async></script>\n';
                }
        } else if (urlContains('ccrz__SellerListPage') || urlContains('ccrz__SellerDetail')) {
            retElements += 
                '<script type="text/javascript" src="https://maps.googleapis.com/maps/api/js?key=AIzaSyDAKSsTNj_egWnqw8aQ92yCiv0MwLN4_EU"></script>\n' +
                '<link type="text/css" rel="stylesheet" href="'+resourcePath(THEME, 'css3/pages/store.css')+'" />\n';
        } else if (urlContains('ccrz__MyAccount') || urlContains('ccrz__StoredPaymentDetail')) {
            retElements +=
                '<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.mask/1.14.16/jquery.mask.min.js" integrity="sha256-Kg2zTcFO9LXOc7IwcBx1YeUBJmekycsnTsq2RuFHSZU=" crossorigin="anonymous"></script>\n' + 
                '<link type="text/css" rel="stylesheet" href="'+resourcePath(THEME, 'css3/pages/cart.css')+'" />\n' +
                '<link type="text/css" rel="stylesheet" href="'+resourcePath(THEME, 'css3/pages/account.css')+'" />\n';
        } else if (urlContains('ccrz__CheckoutNew') || urlContains('ccrz__Order')) {
            retElements +=
                '<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.mask/1.14.16/jquery.mask.min.js" integrity="sha256-Kg2zTcFO9LXOc7IwcBx1YeUBJmekycsnTsq2RuFHSZU=" crossorigin="anonymous"></script>\n' + 
                '<link type="text/css" rel="stylesheet" href="'+resourcePath(THEME, 'css3/pages/checkout.css')+'" />\n';
        } else if (urlContains('ccrz__Cart')) {
            retElements +=
                '<link type="text/css" rel="stylesheet" href="'+resourcePath(THEME, 'css3/pages/cart.css')+'" />\n';
        } else if  (urlContains('ccrz__CCSiteRegister')) {
            retElements +=
                '<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.mask/1.14.16/jquery.mask.min.js" integrity="sha256-Kg2zTcFO9LXOc7IwcBx1YeUBJmekycsnTsq2RuFHSZU=" crossorigin="anonymous"></script>\n'; 
        } else if (urlContains('ccrz__ProductCompare')) {
            retElements +=
            '<link type="text/css" rel="stylesheet" href="'+resourcePath(THEME, 'css3/pages/products/product-compare.css')+'" />\n';
        }
        

        return retElements;
    }

    global virtual override Map<String,Object> endContent(Map<String,Object> inpData){
        // Body end JS includes
        String retContent =
            '<script crossorigin="anonymous" src="https://polyfill.io/v3/polyfill.min.js?features=es6%2CURLSearchParams"></script>\n'+
            '<script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.0/dist/umd/popper.min.js" crossorigin="anonymous" integrity="sha384-Q6E9RHvbIyZFJoft+2mJbHaEWldlvI9IOYy5n3zV9zzTtmI3UksdQRVvoxMfooAo"></script>\n' +
            '<script src="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/js/bootstrap.min.js" crossorigin="anonymous" integrity="sha384-wfSDF2E50Y2D1uUdj0O3uMBJnjuUD4Ih7YwaYd1iqfktj0Uod8GCExl3Og8ifwB6"></script>\n' +
            '<script src="https://cdnjs.cloudflare.com/ajax/libs/algoliasearch/4.8.5/algoliasearch-lite.umd.min.js" crossorigin="anonymous" integrity="sha512-N9S1AYmXfDj4+QOHwKa0/Rvt04NU/cZ9ClDpVevB5BHoIz3CWevGue+T7HcZJJ3KN24h57tnClU/rudbjR0fzA=="></script>\n' +
            '<script src="https://cdnjs.cloudflare.com/ajax/libs/cloudinary-core/2.8.0/cloudinary-core-shrinkwrap.min.js" crossorigin="anonymous" integrity="sha256-5sQOYye1F8FcRDhazLIvoHGB06mowN0V8Cy/9w/QO00="></script>\n';
        
        retContent +=
            '<script type="text/javascript" src="'+resourcePath(THEME, 'js/utils.js')+'"></script>\n'+
            '<script type="text/javascript" src="'+resourcePath(THEME, 'js/cloudinary.js')+'"></script>\n'+
            '<script type="text/javascript" src="'+resourcePath(THEME, 'js/tags.js')+'"></script>\n';

        return new Map<String,Object>{
            EOB_CONTENT => retContent
        };
    }

    global virtual override String metaContent(){
        String retContent =
            '<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no" />\n' +
            '<meta name="facebook-domain-verification" content="pirvjxrno422tvkgk34ej6b6md93yv" />\n' +
            '<meta name="ahrefs-site-verification" content="de298fde0ec7f03b54c6e447edbab0c649eaf59ed49866e43d13d391ea652c39" />\n';
            return retContent;
    }

    global virtual override Map<String,Object> headContent(Map<String,Object> inpData){
        String retContent = metaContent();
        retContent += standardIncludes();
        retContent +=(
            pageConfigCSSIncludes()   +
            pageConfigJSIncludes()    +
            standardUIProperties()
        );

        return new Map<String,Object>{
            HEAD_CONTENT => retContent
        };
    }

    private boolean urlContains(String url) {
        return ApexPages.currentPage().getUrl().containsIgnoreCase(url);
    }
}