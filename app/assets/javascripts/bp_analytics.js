jQuery(document).ready(function(){
  new SearchAnalytics().bindTracker();
});

function Analytics() {
  this.track = function(segment, analytics_action, params, callback) {
    params["segment"] = segment;
    params["analytics_action"] = analytics_action;
    jQuery.ajax({
      url: "/analytics",
      data: params,
      type: "POST",
      timeout: 100,
      success: function(){
        if (typeof callback === "function") callback();
      },
      error: function(){
        if (typeof callback === "function") callback();
      }
    });
  };
}

function SearchAnalytics() {
  this.bindTracker = function() {
    jQuery("#search_results_container div.class_link a").live("click", function(e){
      e.preventDefault();
      var href = jQuery(this).attr("href");
      var params = new SearchAnalytics().linkInformation(this);
      new Analytics().track("search", "result_clicked", params, function(){
        window.location.href = href;
      });
    });
  };

  this.linkInformation = function(link) {
    var info = {}, resultsIndex = 0;
    var ontologyPosition = jQuery("#search_results div.search_result").index(jQuery(link).closest(".search_result")) + 1;
    link = jQuery(link);

    info.ontology_clicked = link.closest(".search_result").attr("data-bp_ontology_id");

    // Find out the position of the search result in the list
    if (link.closest(".additional_results").length === 0) {
      info.position = ontologyPosition;
    } else {
      info.position = link.closest(".additional_results").children(".search_result_additional").index(link.closest(".search_result_additional")) + 1;
    }

    // Was this an additional result or a top-level
    info.additional_result = link.closest(".additional_results").length > 0;

    // Get the name of ontologies higher in the list
    if (info.position > 1 || info.additional_result === true) {
      var results = jQuery("#search_results div.search_result");
      info.higher_ontologies = [];
      while (resultsIndex < ontologyPosition - 1) {
        info.higher_ontologies.push(jQuery(results[resultsIndex]).attr("data-bp_ontology_id"));
        resultsIndex += 1;
      }
    }

    // Concept id
    info.concept_id = link.attr("data-bp_conceptid");

    // Search query
    info.query = jQuery("#search_keywords").val();

    // Exact match
    info.exact_match = link.attr("data-exact_match");

    return info;
  };
}

