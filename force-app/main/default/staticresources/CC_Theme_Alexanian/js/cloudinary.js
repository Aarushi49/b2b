const cl = cloudinary.Cloudinary.new({ cloud_name: "alexanian" });
const CL_ROOT = "https://res.cloudinary.com/alexanian/";
const ENV = "prod";
const STORAGE = sessionStorage;
const PLACEHOLDER_RESOURCE = {
  public_id: ENV + "/static/shared/placeholder",
  format: "jpg",
  context: {
    custom: {
      alt: "Image not found"
    }
  }
};
const PROTECTION_RESOURCE = {
  public_id: ENV + "/static/shared/protection",
  format: "jpg",
  context: {
    custom: {
      alt: "Alexanian Protection Plan"
    }
  }
};

/**
 * Download a list of available images from
 * Cloudinary that are tagged with a given SKU
 * @param {string} productSku - CC product SKU
 * @param {boolean} includeVideos - response should include videos
 * @param {boolean} async - should be true for list of product images
 */
function getProductImages(productSku, includeVideos, async) {
  let productImage = getImageFromStorage("product", productSku);
  if (productImage === undefined) {
    productImage = [];
    $.ajax({
      type: "GET",
      url: CL_ROOT + "image/list/v1/" + productSku + ".json",
      async: async,
      dataType: "json",
      success: function (images) {
        if (images && images.resources && images.resources.length > 0) {
          productImage = productImage.concat(images.resources);
        }

        if (includeVideos) {
          $.ajax({
            type: "GET",
            url: CL_ROOT + "video/list/v1/" + productSku + ".json",
            async: async,
            dataType: "json",
            success: function (videos) {
              if (videos && videos.resources && videos.resources.length > 0) {
                videos.resources.forEach(function (r) {
                  r.isVideo = true;
                });
                productImage = productImage.concat(videos.resources);
              }
              onImagesRetreived();
            }
          });
        } else {
          onImagesRetreived();
        }
      }
    });

    function onImagesRetreived() {
      productImage = productImage.filter(function (media) {
        return media.public_id.startsWith(ENV);
      });

      // Sort by spec_sku, and then sequence number
      productImage.sort(function (a, b) {
        const contextA = getCloudinaryMediaContext(a);
        const contextB = getCloudinaryMediaContext(b);
        if (contextA.spec_sku === contextB.spec_sku) {
          const seq1 = +(contextA.sequence || "500");
          const seq2 = +(contextB.sequence || "500");
          return seq1 - seq2;
        } else if (contextA.spec_sku < contextB.spec_sku) {
          return -1;
        } else {
          return 1;
        }
      });
      saveImageToStorage("product", productSku, productImage);

      // Trigger image retreived event
      if (async) {
        CCRZ.pubSub.trigger("view:simpleProduct:imageRefresh", productSku, productImage);
      }
    }
  }
  return productImage;
}

/**
 * Download a list of available images from
 * Cloudinary that are tagged with a given promoGroupId
 * @param {string} promoGroupId - Promotion Group ID
 */
function getPromoImages(promoGroupId) {
  let promoImage = getImageFromStorage("promo", promoGroupId);
  if (promoImage === undefined) {
    const images = $.ajax({
      type: "GET",
      url: CL_ROOT + "image/list/" + promoGroupId + ".json",
      async: false
    }).responseJSON;
    promoImage = [];
    if (images && images.resources && images.resources.length > 0) {
      promoImage = promoImage.concat(images.resources);
    }

    promoImage = promoImage.filter(function (media) {
      return media.public_id.startsWith(ENV);
    });

    // Sort by sequence number
    promoImage.sort(function (a, b) {
      const seq1 = +(getCloudinaryMediaContext(a).sequence || "500");
      const seq2 = +(getCloudinaryMediaContext(b).sequence || "500");
      return seq1 - seq2;
    });
    saveImageToStorage("promo", promoGroupId, promoImage);
  }
  return promoImage;
}

function getImageFromStorage(imageCategory, imageKey) {
  const images = JSON.parse(STORAGE.getItem(`alx-images-${imageCategory}`) || "{}");
  return images[imageKey];
}

function saveImageToStorage(imageCategory, imageKey, value) {
  const images = JSON.parse(STORAGE.getItem(`alx-images-${imageCategory}`) || "{}");
  images[imageKey] = value;
  STORAGE.setItem(`alx-images-${imageCategory}`, JSON.stringify(images));
}

/**
 * Build a list of images for product detail carousel from cloudinary
 * @param {string} targetId - BS carousel ID
 * @param {string} productSku - product SKU
 * @param {string} colorSku - AB2CProductSpecSKU
 * @param {boolean} isThumbnail - true if image list is thumbnails
 */
function getProductDetailImages(targetId, productSku, colorSku, isThumbnail) {
  const allProductMedia = getProductImages(productSku, true, false);

  // Filter media for the given SKU based on image type
  const matchingImages = allProductMedia.filter(function (media) {
    const context = getCloudinaryMediaContext(media);
    return context.is_swatch !== "true" && (!colorSku || context.spec_sku === colorSku);
  });

  if (matchingImages.length == 0) {
    matchingImages.push(PLACEHOLDER_RESOURCE);
  }

  if (isThumbnail) {
    // Build thumbnail list items
    const thumbOl = document.createElement("OL");
    thumbOl.className = "carousel-indicators";
    for (let i = 0; i < matchingImages.length; i++) {
      const context = getCloudinaryMediaContext(matchingImages[i]);
      const thubmLi = document.createElement("LI");
      thubmLi.setAttribute("data-target", targetId);
      thubmLi.setAttribute("data-slide-to", i);
      if (i === 0) {
        thubmLi.className = "active";
      }

      // Thumbnail image
      const thumbImg = cl.image(matchingImages[i].public_id, {
        width: 128,
        height: 128,
        crop: "fill",
        format: "jpg",
        fetchFormat: "auto",
        quality: "auto",
        resource_type: matchingImages[i].isVideo ? "video" : "image"
      });
      thumbImg.alt = context.alt;
      thubmLi.appendChild(thumbImg);
      thumbOl.appendChild(thubmLi);
    }
    return thumbOl.outerHTML;
  } else {
    // Build detail image carousel items
    let carouselItemsHtml = "";
    for (let i = 0; i < matchingImages.length; i++) {
      const context = getCloudinaryMediaContext(matchingImages[i]);
      const carouselDiv = document.createElement("DIV");
      carouselDiv.className = i === 0 ? "carousel-item active" : "carousel-item";

      // Detailed image/video
      if (matchingImages[i].isVideo) {
        carouselDiv.innerHTML += cl.video(matchingImages[i].public_id, {
          controls: true
        });
      } else {
        const carouselImg = cl.image(matchingImages[i].public_id, {
          fetchFormat: "auto",
          quality: "auto"
        });
        carouselImg.alt = context.alt;
        carouselDiv.appendChild(carouselImg);
      }
      if (context.badge) {
        // Product badge exists for this image, output a
        // second <img> tag with the badge image
        const badgeImg = cl.image(ENV + "/badges/" + context.badge, {
          fetchFormat: "auto",
          quality: "auto"
        });
        badgeImg.className = "alx-product-badge";
        badgeImg.alt = context.alt;
        carouselDiv.appendChild(badgeImg);
      }

      carouselItemsHtml += carouselDiv.outerHTML;
    }
    return carouselItemsHtml;
  }
}

/**
 * Build an <img> tag for product images from cloudinary
 * @param {string} type - one of "detail", "swatch"
 * @param {string} productSku
 * @param {string} colorSku - AB2CProductSpecSKU
 */
function getProductListImageTag(type, productSku, colorSku) {
  const allProductMedia = getProductImages(productSku, false, true);

  // Filter media for the given SKU based on image type
  const matchingImages = allProductMedia.filter(function (media) {
    const context = getCloudinaryMediaContext(media);
    if (type === "detail") {
      return context.is_swatch !== "true" && context.spec_sku === colorSku;
    } else if (type === "swatch") {
      return context.is_swatch === "true" && context.spec_sku === colorSku;
    }
  });

  if (productSku.includes("-PROTECTION")) {
    matchingImages.push(PROTECTION_RESOURCE);
  }

  // Build <img> tag
  if (type === "detail") {
    if (matchingImages.length == 0) {
      matchingImages.push(PLACEHOLDER_RESOURCE);
    }
    const context = getCloudinaryMediaContext(matchingImages[0]);
    const detailImg = cl.image(matchingImages[0].public_id, {
      width: 186,
      height: 220,
      crop: "fill",
      fetchFormat: "auto",
      quality: "auto"
    });
    detailImg.alt = context.alt || productSku + " " + colorSku;
    detailImg.loading = "lazy";
    if (context.badge) {
      // Product badge exists for this image, output a
      // second <img> tag with the badge image
      const badgeImg = cl.image(ENV + "/badges/" + context.badge, {
        fetchFormat: "auto",
        quality: "auto"
      });
      badgeImg.className = "alx-product-badge";
      badgeImg.loading = "lazy";
      badgeImg.alt = context.alt;
      return detailImg.outerHTML + badgeImg.outerHTML;
    } else {
      return detailImg.outerHTML;
    }
  } else if (type === "swatch") {
    // Swatch image

    if (matchingImages.length === 0) {
      debugger
      return null;
    } else {
      const swatchImg = cl.image(matchingImages[0].public_id, {
        width: 37,
        height: 37,
        crop: "fill",
        fetchFormat: "auto",
        quality: "auto"
      });
      swatchImg.loading = "lazy";
      swatchImg.alt = productSku + " " + colorSku + " swatch";
      return swatchImg.outerHTML;
    }
  }
}

/**
 * Build an <img> tag for promo images from cloudinary
 * @param {string} type - one of "square", "banner"
 * @param {string} promoGroupId - promotion group ID
 * @param {string} sequence - sequence of image
 */
function getPromoImageTag(type, promoGroupId, sequence) {
  const allPromoMedia = getPromoImages(promoGroupId);

  // Filter media for the promo image based on sequence
  const matchingImages = allPromoMedia.filter(function (media) {
    const context = getCloudinaryMediaContext(media);
    return !context.sequence || context.sequence === sequence.toString();
  });

  if (matchingImages.length > 0) {
    const pictureTag = document.createElement("picture");
    const imgFallback = document.createElement("img");

    // Generate <picture> tag with appropriate <source> children
    for (let i = 0; i < matchingImages.length; i++) {
      const media = matchingImages[i];
      const context = getCloudinaryMediaContext(media);
      if (!context.device || context.device === "desktop") {
        const desktopSource = document.createElement("source");
        desktopSource.media = "(min-width: 992px)";
        desktopSource.srcset = cl.url(media.public_id, {
          fetchFormat: "auto",
          quality: "auto"
        });
        pictureTag.appendChild(desktopSource);
        imgFallback.src = cl.url(media.public_id, {
          fetchFormat: "auto",
          quality: "auto"
        });
        imgFallback.alt = context.alt;
        imgFallback.loading = "lazy";
      } else if (context.device === "tablet") {
        const tabletSource = document.createElement("source");
        tabletSource.media = "(max-width: 991px) and (min-width: 768px)";
        tabletSource.srcset = cl.url(media.public_id, {
          fetchFormat: "auto",
          quality: "auto"
        });
        pictureTag.appendChild(tabletSource);
      } else if (context.device === "mobile") {
        const mobileSource = document.createElement("source");
        mobileSource.media = "(max-width: 767px)";
        mobileSource.srcset = cl.url(media.public_id, {
          fetchFormat: "auto",
          quality: "auto"
        });
        pictureTag.appendChild(mobileSource);
      }
    }
    pictureTag.appendChild(imgFallback);
    return pictureTag.outerHTML;
  } else {
    // Placeholder images for when the requested
    // Promo Group ID is not found on Cloudinary
    const placeholderSize = type === "square" ? "400x400" : "1000x400";
    return (
      '<img src="https://via.placeholder.com/' + placeholderSize + "?text=" + promoGroupId + " " + sequence + '"/>'
    );
  }
}

/**
 * Return a cloudinary image source for a product given the product sku and spec sku
 * @param {string} productSku
 * @param {string} colorSku - AB2CProductSpecSKU
 */
function getProductImageUrl(productSku, colorSku) {
  const allProductMedia = getProductImages(productSku, false, true);
  const matchingImages = allProductMedia.filter(function (media) {
    const context = getCloudinaryMediaContext(media);
    return context.is_swatch !== "true" && context.spec_sku === colorSku;
  });
  if (matchingImages.length > 0) {
    return cl.url(matchingImages[0].public_id, {
      fetchFormat: "auto",
      quality: "auto"
    });
  } else {
    return cl.url(PLACEHOLDER_RESOURCE.public_id, {
      fetchFormat: "auto",
      quality: "auto"
    });
  }
}

/**
 * Extract context from a Cloudinary media resource json
 */
function getCloudinaryMediaContext(media) {
  return media && media.context && media.context.custom ? media.context.custom : {};
}

Handlebars.registerHelper("productDetailImages", function (targetId, productSku, colorSku) {
  if (colorSku === "null") colorSku = null;
  return getProductDetailImages(targetId, productSku, colorSku, false);
});

Handlebars.registerHelper("productDetailThumbnails", function (targetId, productSku, colorSku) {
  if (colorSku === "null") colorSku = null;
  return getProductDetailImages(targetId, productSku, colorSku, true);
});

Handlebars.registerHelper("productListImage", function (productSku, swatchSku) {
  return getProductListImageTag("detail", productSku, swatchSku);
});

Handlebars.registerHelper("productSwatchImage", function (productSku, swatchSku) {
  return getProductListImageTag("swatch", productSku, swatchSku);
});

Handlebars.registerHelper("promoSquareImage", function (promoGroupId, sequence) {
  return getPromoImageTag("square", promoGroupId, sequence);
});

Handlebars.registerHelper("promoBannerImage", function (promoGroupId, sequence) {
  return getPromoImageTag("banner", promoGroupId, sequence);
});
