const productImpressions = {};
const currentImpressionBatch = [];
let impressionPushCount = 0;

/**
 * Sets the initial data tags when the page loads
 */
function setDefaultTags() {
  window.dataLayer = window.dataLayer || [];
  dataLayer.push({
    pageType: CCRZ.pagevars.currentPageName,
    pageTitle: document.title,
    Section: "", // TODO
    userID: CCRZ.currentUser ? CCRZ.currentUser.Email : null,
    loggedStatus: CCRZ.pagevars.isGuest ? "Guest" : "Logged In",
    usedCoupon: "No" // TODO
  });

  setInterval(function () {
    pushImpressionBatch();
  }, 5000);
}

Handlebars.registerHelper("sendProductListImpression", function (product) {
  try {
    if (!productImpressions[product.SKU]) {
      productImpressions[product.SKU] = true;
      currentImpressionBatch.push({
        name: product.sfdcName,
        id: product.SKU,
        price: product.price
          ? product.price
          : product.minPrice + " - " + product.maxPrice,
        category: CCRZ.productListPageView.model.get("category")
          ? CCRZ.productListPageView.model.get("category").friendlyUrl
          : null,
        dimension1: product.serviceFlag,
        position: Object.keys(productImpressions).length
      });
      if (currentImpressionBatch.length == 10) {
        pushImpressionBatch();
      }
    }
  } catch (e) {
    console.error("Unable to send product list impression", e);
  }
});

function pushImpressionBatch() {
  if (currentImpressionBatch.length > 0) {
    impressionPushCount++;
    dataLayer.push({
      event: "eec.impressionView",
      pushNumber: impressionPushCount,
      ecommerce: {
        impressions: currentImpressionBatch.slice()
      }
    });
    currentImpressionBatch.length = 0;
  }
}

Handlebars.registerHelper("sendProductDetailImpression", function (
  eventType,
  productDetailArray,
  quantity
) {
  try {
    const product =
      productDetailArray.length > 1
        ? productDetailArray[1]
        : productDetailArray[0];
    let category = CCRZ.productDetailModel
      ? CCRZ.productDetailModel.attributes.friendlyUrl
      : null;
    if (category) {
      const productSeoId = category.split("/").pop();
      category = category.replace("/" + productSeoId, "");
    }
    const dataLayerProducts = [
      {
        name: product.sfdcName,
        id: product.SKU,
        price: product.price
          ? product.price
          : product.minPrice + " - " + product.maxPrice,
        category: category,
        dimension1: product.serviceFlag,
        position: 1
      }
    ];

    if (eventType === "eec.detail") {
      dataLayer.push({
        event: eventType,
        ecomm_prodid: dataLayerProducts[0].id,
        ecomm_totalvalue: dataLayerProducts[0].price,
        ecomm_category: dataLayerProducts[0].category,
        ecomm_pagetype: "Product Detail",
        ecommerce: {
          detail: {
            actionField: { list: "" },
            products: dataLayerProducts
          }
        }
      });
    } else if (eventType === "eec.add") {
      dataLayerProducts[0].quantity = quantity;
      dataLayer.push({
        event: eventType,
        ecommerce: {
          currencyCode: CCRZ.userIsoCode,
          add: {
            products: dataLayerProducts
          }
        }
      });
    } else if (eventType === "eec.remove") {
      dataLayerProducts[0].quantity = quantity;
      dataLayer.push({
        event: eventType,
        ecommerce: {
          currencyCode: CCRZ.userIsoCode,
          remove: {
            products: dataLayerProducts
          }
        }
      });
    }
  } catch (e) {
    console.error("Unable to send product detail impression", e);
  }
});

function sendCartEvent() {
  try {
    if (
      CCRZ.cartDetailModel.get("ECartItemsS") &&
      CCRZ.cartDetailModel.get("ECartItemsS").length > 0
    ) {
      const dataLayerProducts = [];
      const skuList = [];
      let position = 1;
      for (let cartModel of CCRZ.cartDetailModel.get("ECartItemsS").models) {
        if (cartModel.get("productType") !== "Coupon") {
          dataLayerProducts.push({
            name: cartModel.get("product").sfdcName,
            id: cartModel.get("product").SKU,
            price: cartModel.get("price"),
            dimension1: cartModel.get("product").serviceFlag,
            position: position,
            quantity: cartModel.get("quantity"),
            coupon: CCRZ.cartDetailModel.get("couponName")
          });
          skuList.push(cartModel.get("product").SKU);
          position++;
        }
      }
      dataLayer.push({
        event: "eec.cart",
        ecomm_prodid: skuList,
        ecomm_totalvalue: CCRZ.cartDetailModel.get("subtotalAmount"),
        ecomm_category: [],
        ecomm_pagetype: "Cart",
        products: dataLayerProducts
      });
    }
  } catch (e) {
    console.error("Unable to send checkout impression", e);
  }
}

function sendCheckoutEvent(step) {
  try {
    const dataLayerProducts = [];
    let position = 1;
    for (let cartItem of CCRZ.cartCheckoutModel.get("cartItems")) {
      if (cartItem.productType !== "Coupon") {
        dataLayerProducts.push({
          name: cartItem.mockProduct.sfdcName,
          id: cartItem.mockProduct.sku,
          price: cartItem.price,
          dimension1: cartItem.mockProduct.serviceFlag,
          position: position,
          quantity: cartItem.quantity,
          coupon: CCRZ.cartCheckoutModel.get("couponName")
        });
        position++;
      }
    }
    dataLayer.push({
      event: "eec.checkout",
      ecommerce: {
        checkout: {
          actionField: { step: step },
          products: dataLayerProducts
        }
      }
    });
  } catch (e) {
    console.error("Unable to send checkout impression", e);
  }
}

function sendCheckoutOptionEvent(step, option) {
  dataLayer.push({
    event: "eec.checkout_option",
    ecommerce: {
      checkout_option: {
        actionField: {
          step: step,
          option: option
        }
      }
    }
  });
}

function sendTransactionEvent(transactionId) {
  try {
    // Save transaction ID so it's not sent a second time
    const transactionList = JSON.parse(STORAGE.getItem(`alx-transactions`) || "[]");
    if (transactionList.includes(transactionId)) {
      return;
    } else {
      transactionList.push(transactionId);
      STORAGE.setItem(`alx-transactions`, JSON.stringify(transactionList));
    }

    const dataLayerProducts = [];
    let position = 1;
    let couponAmount = 0;
    for (let cartItem of CCRZ.cartCheckoutModel.get("cartItems")) {
      if (cartItem.productType !== "Coupon") {
        dataLayerProducts.push({
          name: cartItem.mockProduct.sfdcName,
          id: cartItem.mockProduct.sku,
          price: cartItem.price,
          dimension1: cartItem.mockProduct.serviceFlag,
          position: position,
          quantity: cartItem.quantity,
          coupon: CCRZ.cartCheckoutModel.get("couponName")
        });
        position++;
      } else {
        couponAmount = cartItem.itemTotal;
      }
    }

    dataLayer.push({
      event: "eec.purchase",
      ecommerce: {
        currencyCode: CCRZ.userIsoCode,
        purchase: {
          actionField: {
            id: transactionId,
            revenue: CCRZ.cartCheckoutModel.get("subTotal"),
            revenueWCoupon: CCRZ.cartCheckoutModel.get("subTotal") + couponAmount,
            affiliation: "",
            tax: CCRZ.cartCheckoutModel.get("tax"),
            shipping: CCRZ.cartCheckoutModel.get("shippingCharge"),
            coupon: CCRZ.cartCheckoutModel.get("couponName"),
            discount: Math.abs(couponAmount)
          },
          products: dataLayerProducts
        }
      }
    });
  } catch (e) {
    console.error("Unable to send transaction event", e);
  }
}

Handlebars.registerHelper("sendPromotionImpression", function (promotions) {
  try {
    const promotionItems = [];
    if (promotions && promotions.length > 0) {
      for (let promotion of promotions) {
        promotionItems.push({
          id: promotion.Id,
          name: promotion.Name,
          creative: promotion.Promotion_Group_ID__c,
          position: promotion.ccrz__LocationType__c
        });
      }
      dataLayer.push({
        event: "eec.promoView",
        ecommerce: {
          promoView: {
            promotions: promotionItems
          }
        }
      });
    }
  } catch (e) {
    console.error("Unable to send promotion impression", e);
  }
});
