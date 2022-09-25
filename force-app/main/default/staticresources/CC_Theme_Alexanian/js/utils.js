/******************************
  CCRZ Constant
******************************/
const freeInStore = "Alexanian Store - freeInStore";

/******************************
  CCRZ View and Model interceptor
******************************/

CCRZ.views = new Proxy(CCRZ.views, {
  set: function (target, key, value) {
    const keyNotDefined = typeof target[key] === "undefined";
    target[key] = value;
    if (keyNotDefined) {
      CCRZ.pubSub.trigger("ccrz.views:" + key + ":defined");
    }
    return true;
  }
});

CCRZ.models = new Proxy(CCRZ.models, {
  set: function (target, key, value) {
    const keyNotDefined = typeof target[key] === "undefined";
    target[key] = value;
    if (keyNotDefined) {
      CCRZ.pubSub.trigger("ccrz.models:" + key + ":defined");
    }
    return true;
  }
});

/******************************
  Common utility functions
******************************/

// Get Menu by ID
function getMenuById(menuId) {
  if (CCRZ.data && CCRZ.data.menus) {
    const menu = CCRZ.data.menus.find(function (menu) {
      return menu.menuId === menuId;
    });
    return menu;
  }
  return {};
}

// Return device size (desktop/tablet/mobile)
function getScreenSize() {
  let screenSize = "desktop";
  if (window.matchMedia("(min-width: 768px) and (max-width: 991px)").matches) {
    screenSize = "tablet";
  } else if (window.matchMedia("(max-width: 767px)").matches) {
    screenSize = "mobile";
  }
  return screenSize;
}
let screenSize = getScreenSize();
window.addEventListener("resize", function () {
  if (screenSize !== getScreenSize()) {
    screenSize = getScreenSize();
    CCRZ.pubSub.trigger("action:screen:resize", getScreenSize());
  }
});

// Observe and notify when an element with the given selector is available in the DOM
function whenAvailable(selector, callback) {
  let elementCount = $("body").has(selector).length;
  if (elementCount > 0) {
    callback();
  } else {
    const observer = new MutationObserver(function (mutations) {
      elementCount = $("body").has(selector).length;
      if (elementCount > 0) {
        observer.disconnect();
        callback();
      }
    });
    observer.observe(document.body, { childList: true, subtree: true });
  }
}

// Log user out
function logOutUser() {
  if (CCRZ && CCRZ.pagevars.linkOverrideMap["HeaderLogout"]) {
    window.location.href = CCRZ.pagevars.linkOverrideMap["HeaderLogout"];
  } else {
    window.location.href = "/secur/logout.jsp";
  }
}

function backToSignIn() {
  window.location.href = "/signin?registrationSuccess=false" + getCSRQueryString();
}

/* Renders a custom breadcrum. Expects model like:
    customBreadcrumbs: [
      {href: /ccrz_home, label: 'home'},
      {href: /ccrz_about, label: 'about'},
    ] 
    */
function renderCustomBreadcrumb(customBreadcrumbs) {
  const breadcrumbsTemplate = Handlebars.compile($("#AB2CBreadCrumbBrowser").html());
  $("#breadcrumb_desktop_container").html(
    breadcrumbsTemplate({
      home: {
        href: CCRZ.pageUrls.homePage,
        label: "Home"
      },
      customBreadcrumbs: customBreadcrumbs
    })
  );
}

//  Get Country List
function getAvailableCountryList() {
  return _.filter(CCRZ.geoCodes.countryList.toJSON(), function (m) {
    if (m.label === "Canada") {
      return m;
    }
    if (m.label === "United States") {
      return m;
    }
  });
}

/******************************
  Common Handlebar Helpers
******************************/

Handlebars.registerHelper("getMenuById", function (menuId) {
  return getMenuById(menuId);
});

// Return class if first param true
Handlebars.registerHelper("returnClass", function (isTrue, className) {
  if (isTrue) {
    return className + " ";
  } else {
    return "";
  }
});

// Return a URL query param value
Handlebars.registerHelper("getQueryParam", function (param) {
  let searchParams = new URLSearchParams(window.location.search);
  if (searchParams.get(param)) {
    return decodeURIComponent(searchParams.get(param) || "");
  } else {
    const index = CCRZ.pagevars.currentPageURL.indexOf("?");
    if (index > 0) {
      const searchParams = new URLSearchParams(CCRZ.pagevars.currentPageURL.substring(index));
      return decodeURIComponent(searchParams.get(param) || "");
    }
  }
  return "";
});

// Return swatches or sizes from product specs
Handlebars.registerHelper("swatchSpecs", function (specs) {
  return returnSwatches(specs).sort(function (a, b) {
    if (a.sequence === b.sequence) {
      return a.specValue > b.specValue ? 1 : -1;
    }
    return a.sequence > b.sequence ? 1 : -1;
  });
});

Handlebars.registerHelper("sizeSpecs", function (product, selectedSwatch) {
  return returnSizes(product.compositeProductsS, selectedSwatch, product.productSpecsS).sort(function (a, b) {
    if (a.sequence > 0 && b.sequence > 0) {
      return a.sequence > b.sequence ? 1 : -1;
    } else {
      const regex = /[0-9]+x[0-9]+/i;
      if (a.specValue.match(regex) && b.specValue.match(regex)) {
        let a_size = a.specValue.match(regex)[0].split("x").map(Number);
        let b_size = b.specValue.match(regex)[0].split("x").map(Number);
        if (a_size[0] > b_size[0]) {
          return 1;
        } else if (a_size[0] == b_size[0]) {
          return a_size[1] > b_size[1] ? 1 : -1;
        } else {
          return -1;
        }
      } else {
        return a.specValue > b.specValue ? 1 : -1;
      }
    }
  });
});

Handlebars.registerHelper("defaultStyleName", function (specs) {
  const swatches = Handlebars.helpers.swatchSpecs(specs);
  return swatches.length ? swatches[0].AB2CProductSpecSKU : null;
});

Handlebars.registerHelper("defaultStyleSku", function (specs) {
  const swatches = Handlebars.helpers.swatchSpecs(specs);
  return swatches.length ? swatches[0].AB2CProductSpecSKU : null;
});

Handlebars.registerHelper("hasSingleStyle", function (specs) {
  return Handlebars.helpers.swatchSpecs(specs).length < 2;
});

Handlebars.registerHelper("hasSingleSize", function (product, selectedSwatch) {
  return Handlebars.helpers.sizeSpecs(product, selectedSwatch).length < 2;
});

Handlebars.registerHelper("findSampleSKU", function (prod) {
  if (prod.length > 1) {
    const styleSpec = Handlebars.helpers.swatchSpecs(prod[1].productSpecsS);
    if (styleSpec) {
      return getSampleSkuFor(styleSpec, prod);
    }
  }
});

Handlebars.registerHelper("findProtectionPlanCart", function (prod) {
  if (prod.productSpecsS) {
    let productSpecsClean = prod.productSpecsS.find((prod) => {
      return prod.AB2CSpecName === "Protection";
    });

    if (productSpecsClean) {
      //AB2CProductSpecSKU: "PROTECTION_1428-6621-0525F-NVYCOP-2X3-PROTECTION"
      productSpecsClean.AB2CProductSpecSKU = productSpecsClean.AB2CProductSpecSKU.replace("PROTECTION_", "");
      //specValue: "PROTECTION-199.00"
      productSpecsClean.specValue = productSpecsClean.specValue.replace("PROTECTION-", "");
      return [productSpecsClean];
    }
    return [];
  }
});

Handlebars.registerHelper("hasProtectionPlan", function (prod) {
  let protectionPlanProduct = prod.filter((prod) => {
    return prod.SKU.includes("-PROTECTION");
  });
  return protectionPlanProduct;
});

Handlebars.registerHelper("isProtectionOrSampleProduct", function (prod) {
  if (prod.SKU.includes("-PROTECTION")) {
    return true;
  }
  return isSampleProduct(prod);
});

Handlebars.registerHelper("isSampleProduct", function (prod) {
  return isSampleProduct(prod);
});

Handlebars.registerHelper("getSKUComponents", function (product, selectedSwatch) {
  const skuComponents = {
    sku: product.SKU || product.sku
  };
  if (product.productSpecsS) {
    const swatchSpecs = Handlebars.helpers.swatchSpecs(product.productSpecsS);
    const sizeSpecs = Handlebars.helpers.sizeSpecs(product, selectedSwatch);
    if (swatchSpecs.length > 0) {
      skuComponents.swatchSku = swatchSpecs[0].AB2CProductSpecSKU;
      if (product.AB2CIsComponent) {
        // Component products have swatch in the SKU, need to remove this to get the parent SKU
        skuComponents.sku = skuComponents.sku.replace(`-${skuComponents.swatchSku}`, "");
      }
    }
    if (sizeSpecs.length > 0) {
      skuComponents.sizeSku = sizeSpecs[0].AB2CProductSpecSKU;
      if (product.AB2CIsComponent) {
        // Component products have size in the SKU, need to remove this to get the parent SKU
        skuComponents.sku = skuComponents.sku.replace(`-${skuComponents.sizeSku}`, "");
      }
    }
  }
  return skuComponents;
});

// Strips out possible spec skus from the component sku, making it match the parent sku
Handlebars.registerHelper("getParentSku", function (parentSku, specs, isComponent) {
  let sku = parentSku;
  if (specs && isComponent) {
    for (let spec of specs) {
      if (spec.AB2CPSIsSwatch || spec.AB2CIsSize) {
        sku = sku.replace("-" + spec.AB2CProductSpecSKU, "");
      }
    }
  }
  return sku;
});

Handlebars.registerHelper("getProductDetailUrl", function (baseProduct, styleSKU, sizeSKU) {
  const baseUrl = baseProduct.SEOId ? "/" + baseProduct.SEOId : CCRZ.pageUrls.productDetails;
  const skuComponents = Handlebars.helpers.getSKUComponents(baseProduct, styleSKU);
  const cartId = CCRZ.pagevars.currentCartID ? `&cartId=${CCRZ.pagevars.currentCartID}` : "";
  if (typeof styleSKU !== "string") styleSKU = skuComponents.swatchSku;
  if (typeof sizeSKU !== "string") sizeSKU = skuComponents.sizeSku;
  skuComponents.sku = skuComponents.sku.replace("-PROTECTION", "");
  if (baseProduct.productSpecsS) {
    const styleSkuPart = styleSKU ? `&styleSKU=${styleSKU}` : "";
    const sizeSkuPart = sizeSKU ? `&sizeSKU=${sizeSKU}` : "";
    return `${baseUrl}/?sku=${skuComponents.sku}${styleSkuPart}${sizeSkuPart}${cartId}`;
  } else {
    return `${baseUrl}/?sku=${skuComponents.sku}${cartId}`;
  }
});

Handlebars.registerHelper("getProductDetailUrlNoSizeSpec", function (baseProduct, styleSKU) {
  return Handlebars.helpers.getProductDetailUrl(baseProduct, styleSKU, null);
});

Handlebars.registerHelper("pagevars", function (key) {
  return CCRZ.pagevars[key];
});

function returnSwatches(specs) {
  if (specs) {
    const swatches = specs.filter(function (spec) {
      return spec.AB2CPSIsSwatch;
    });
    if (swatches && swatches.length > 0) {
      return swatches;
    }
  }
  return [];
}

function isSampleProduct(prod) {
  if (prod.productSpecsS) {
    for (const spec of prod.productSpecsS) {
      if (spec.specValue === "SAMPLE") return true;
    }
  }
}

function returnSizes(composites, selectedSwatch, specs) {
  if (specs) {
    if (selectedSwatch && composites && composites.length > 0) {
      const componentSkus = composites.reduce(function (acc, val) {
        if (val.componentR.SKU.includes(selectedSwatch)) {
          acc += val.componentR.SKU + "/";
        }
        return acc;
      }, "");
      return (
        specs.filter(function (spec) {
          return spec.AB2CIsSize && spec.specValue !== "SAMPLE" && componentSkus.includes(spec.AB2CProductSpecSKU);
        }) || []
      );
    } else {
      return (
        specs.filter(function (spec) {
          return spec.AB2CIsSize && spec.specValue !== "SAMPLE";
        }) || []
      );
    }
  }
  return [];
}

function getSampleSkuFor(styleSpec, prod) {
  if (styleSpec && prod && prod.length > 0 && prod[0].compositeProductsS) {
    for (const compProd of prod[0].compositeProductsS) {
      if (
        styleSpec.length > 0 &&
        compProd.componentR.SKU.includes(styleSpec[0].AB2CProductSpecSKU) &&
        compProd.componentR.SKU.includes("SAMPLE")
      ) {
        return compProd.componentR.SKU;
      }
    }
  }
}

function returnDisplayedProduct(model) {
  if (!model[0].productSpecsS || model.length === 1) {
    return model[0];
  }
  const styleSpecs = returnSwatches(model[0].productSpecsS);
  const sizeSpecs = returnSizes(model[0].compositeProductsS, null, model[0].productSpecsS);
  if ((styleSpecs && styleSpecs.length > 1) || (sizeSpecs && sizeSpecs.length > 1)) {
    return model[1];
  } else {
    return model[0];
  }
}

//General style
Handlebars.registerHelper("toLowerCase", function (str) {
  return str.toLowerCase();
});

/******************************
  Common CloudCraze Models
******************************/

function getSellerLocatorModel() {
  if (!CCRZ.models.SellerLocatorModel) {
    CCRZ.models.SellerLocatorModel = CCRZ.CloudCrazeModel.extend({
      className: "AB2CSellerController",
      selectInformation: function (store) {
        const sellerList = JSON.parse(STORAGE.getItem(`alx-sellers`) || "[]");
        return _.find(sellerList, function (m) {
          if (m.sellerId === store) {
            return m;
          }
        });
      },
      fetch: function (callback) {
        const sellerList = JSON.parse(STORAGE.getItem(`alx-sellers`) || "[]");
        const cities = JSON.parse(STORAGE.getItem(`alx-cities`) || "[]");
        if (sellerList.length > 0 && cities.length > 0) {
          callback({ sellerList: sellerList, cities: cities });
        } else {
          this.invokeCtx(
            "searchSellersByRadius",
            0,
            0,
            0,
            function (response, event) {
              if (!response.success) {
                console.error(response.data);
              }
              response.data.sellerList = response.data.sellerList.sort(function (a, b) {
                return a.sfdcName.localeCompare(b.sfdcName);
              });
              response.data.cities = response.data.cities.sort();
              STORAGE.setItem(`alx-sellers`, JSON.stringify(response.data.sellerList));
              STORAGE.setItem(`alx-cities`, JSON.stringify(response.data.cities));
              callback(response.data);
            },
            { nmsp: false, buffer: false }
          );
        }
      }
    });
  }
  return new CCRZ.models.SellerLocatorModel();
}

//Calculate Distance between client and stores
// Returns a promise of user's lat/lng if address/city provided, or else use browser's location
function getCoordinates(address, city, country) {
  return new Promise(function (resolve, reject) {
    if (city) {
      city += " " + country;
    }
    const userInputLocation = address || city;
    if (userInputLocation) {
      $.ajax({
        type: "GET",
        url:
          "https://maps.googleapis.com/maps/api/geocode/json?key=" +
          CCRZ.pagevars.pageConfig["sel.gkey"] +
          "&address=" +
          userInputLocation,
        dataType: "json",
        success: function (response) {
          if (response && response.results && response.status === "OK") {
            const location = response.results[0].geometry.location;
            resolve({ lat: location.lat, lng: location.lng });
          } else {
            reject("Unable to geocode user location");
          }
        },
        error: function (error) {
          reject("Unable to geocode user location", error);
        }
      });
    } else {
      if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
          function (position) {
            resolve({
              lat: position.coords.latitude,
              lng: position.coords.longitude
            });
          },
          function (error) {
            reject("Unable to get user's location", error);
          }
        );
      } else {
        reject("Geolocation is not supported by this browser.");
      }
    }
  });
}

// Returns the distance between lat/lng coordinates in KMs
function getDistanceBetweenPointsKm(lat1, lng1, lat2, lng2) {
  const rad = function (x) {
    return (x * Math.PI) / 180;
  };
  const round = function (value, precision) {
    const multiplier = Math.pow(10, precision || 0);
    return Math.round(value * multiplier) / multiplier;
  };
  const R = 6378137; // Earth’s mean radius in meter
  const dLat = rad(lat2 - lat1);
  const dLong = rad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(rad(lat1)) * Math.cos(rad(lat2)) * Math.sin(dLong / 2) * Math.sin(dLong / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const d = R * c;
  return round(d / 1000, 1);
}

// Add Canonical URL to pages
function addCanonicalURL(productName) {
  if (CCRZ.prodDetailView && CCRZ.prodDetailView.model.attributes.friendlyUrl) {
    const type = "canonical";
    let linkElement = document.getElementById("canonical");
    if (!linkElement) {
      linkElement = document.createElement("link");
      linkElement.id = type;
      linkElement.type = type;
      document.head.appendChild(linkElement);
    }
    linkElement.href = CCRZ.prodDetailView.model.attributes.friendlyUrl.concat("/", productName);
  }
}
