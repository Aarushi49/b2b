//
// Theme driven uiProperties overrides.  If you want to override elements
// of uiProperties within this file then
// 1) Uncomment the code between //OVERRIDES START HERE and
//                               //OVERRIDES END HERE
// 2) Define the specific property(ies) that you wish to
//    override from the managed package.
//
// Note that you must override according to the full object path
// but you can only override specific values, i.e. you do not need
// to provide the whole object copy.
//
// OVERRIDES START HERE
CCRZ.uiProperties = $.extend(true, CCRZ.uiProperties, {
  Menu: {
    // Prevent default CC menu view from being rendered
    desktop: {
      tmpl: null,
      selector: null
    },
    phone: {
      tmpl: null,
      selector: null
    }
  },
  productDetailView: {
    desktop: {
      tmpl: null,
      selector: null
    },
    phone: {
      tmpl: null,
      selector: null
    }
  },
  breadcrumbView: {
    desktop: {
      tmpl: "AB2CBreadCrumbBrowser",
      selector: "#breadcrumb_desktop_container"
    }
  },
  myaccountView: {
    desktop: {
      selector: null
    },
    phone: {
      selector: null
    }
  },
  myAccountNavView: {
    desktop: {
      tmpl: null,
      selector: null
    },
    tablet: {
      tmpl: null,
      selector: null
    }
  },
  loginView: {
    desktop: {
      selector: ".contentBody"
    }
  },
  contactInfoView: {
    desktop: {
      tmpl: null
    },
    phone: {
      tmpl: null
    }
  },
  myAccountChangePasswordView: {
    desktop: {
      tmpl: null,
      tmplOverride: null
    },
    phone: {
      tmpl: null
    }
  },
  myOrdersView: {
    desktop: {
      tmpl: null
    },
    phone: {
      tmpl: null
    },
    cancelModal: {
      tmpl: null,
      selector: null
    }
  },
  myAddressBookView: {
    desktop: {
      tmpl: null
    },
    phone: {
      tmpl: null
    },
    addressEditModal: {
      tmpl: null,
      selector: null
    }
  },
  quickWishlistView: {
    desktop: {
      tmpl: null,
      selector: null
    },
  }
});
// OVERRIDES END HERE

// CCRZ Overrides
CCRZ.setCookieWithPath = function (c_name, value, expiredays, path) {
  if (value) {
    const exdate = new Date();
    exdate.setDate(exdate.getDate() + expiredays);
    document.cookie =
      c_name +
      "=" +
      window.escape(value) +
      (expiredays === null ? "" : ";expires=" + exdate.toGMTString()) +
      ";path=" +
      path +
      "; Secure";
  }
};

// Disable mobile and tablet templates
CCRZ.disableAdaptive = true;
CCRZ.display.isPhone = function () {
  return false;
};
CCRZ.display.isTablet = function () {
  return false;
};
CCRZ.display.isDesktop = function () {
  return true;
};
CCRZ.display.setCurrentView = function () {
  this.currentView = "desktop";
};

const DISPLAY_TEMPLATE_NAMES = false;
jQuery(function ($) {
  // Normalize classes in built-in templates for our needs
  $(".phoneLayout").hide();
  $(".deskLayout").removeClass("container");

  // For debugging purposes, display CC template names
  if (DISPLAY_TEMPLATE_NAMES) {
    CCRZ.util.template = function (id) {
      var source = $("#" + id).html();
      preSource = "<div class='internalHB'>" + id + " (" + findUIProperty(CCRZ.uiProperties, id).join(";") + ")</div>";
      source = "<div class='cc_hb'>" + preSource + source + "</div>";
      return Handlebars.compile(source);
    };

    // Finds what is the CCRZ.uiproperty for the value passed:
    findUIProperty = function (uiPropertyArray, strToFind) {
      let arrKeys = Object.keys(uiPropertyArray);
      var uiTest = false;
      var uiArray = [];
      var regex;
      for (uiKey of arrKeys) {
        uiTest = false;
        replaceThis = '(("tmpl":"' + strToFind + '"))';
        regex = new RegExp(replaceThis, "g");
        uiTest = JSON.stringify(uiPropertyArray[uiKey]).match(regex);
        if (uiTest) {
          uiArray.push(uiKey);
        }
      }
      return uiArray;
    };
  }
});
