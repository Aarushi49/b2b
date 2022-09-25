jQuery(function ($) {
    CCRZ.pubSub.on("view:StaticContentView:loaded", function (theView) {
        var script = document.createElement("script");
        script.type = "text/javascript";
        script.async = true;
        script.src =
          "https://quick-feedback.co/reviews-widget/widget.js?merchant_id=5b1aa480365e2d004ecfee80";
        var embedder = document.getElementById(
          "quick-feedback-reviews-widget"
        );
        embedder.parentNode.insertBefore(script, embedder);
    });    
});