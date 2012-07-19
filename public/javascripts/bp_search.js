jQuery(document).ready(function(){
  // Wire advanced search categories
  jQuery("#search_categories").chosen({search_contains: true});
  jQuery("#search_button").button({search_contains: true});

  // Put cursor in search box by default
  jQuery("#search_keywords").focus();

  // Show/hide on refresh
  if (advancedOptionsSelected()) {
    jQuery("#search_options").removeClass("not_visible");
  }

  jQuery("#search_select_ontologies").change(function(){
    if (jQuery(this).is(":checked")) {
      jQuery("#ontology_picker_options").removeClass("not_visible");
    } else {
      jQuery("#ontology_picker_options").addClass("not_visible");
      jQuery("#ontology_ontologyId").val("");
      jQuery("#ontology_ontologyId").trigger("liszt:updated");
    }
  });

  jQuery("#search_results a.additional_results_link").live("click", function(event){
    event.preventDefault();
    jQuery("#additional_results_"+jQuery(this).attr("data-bp_additional_results_for")).toggleClass("not_visible");
    jQuery(this).children(".hide_link").toggleClass("not_visible");
    jQuery(this).toggleClass("not_underlined");
  });

  // Show advanced options
  jQuery("#advanced_options").click(function(event){
    jQuery("#search_options").toggleClass("not_visible");
    jQuery("#hide_advanced_options").toggleClass("not_visible");
  });

  // Events to run whenever search results are updated (mainly counts)
  jQuery(document).live("search_results_updated", function(){
    // Update count
    jQuery("#result_count_total").html(currentResultsCount());
    jQuery("#ontologies_count_total").html(currentOntologiesCount());

    // Tooltip for ontology counts
    updatePopupCounts();
    jQuery("#ont_tooltip").tooltip({
      position: "bottom right",
      opacity: "90%",
      offset: [-18, 5]
    });
  });

  // Perform search
  jQuery("#search_button").click(function(event){
    event.preventDefault();

    jQuery("#search_spinner").show();
    jQuery("#search_messages").html("");

    var ont_val = jQuery("#ontology_ontologyId").val();

    var onts = (ont_val === null) ? "" : ont_val.join(",");
    var query = jQuery("#search_keywords").val();

    // Advanced options
    var includeProps = jQuery("#search_include_props").is(":checked");
    var includeViews = jQuery("#search_include_views").is(":checked");
    var includeObsolete = jQuery("#search_include_obsolete").is(":checked");
    var includeNonProduction = jQuery("#search_include_non_production").is(":checked");
    var includeOnlyDefinitions = jQuery("#search_only_definitions").is(":checked");
    var exactMatch = jQuery("#search_exact_match").is(":checked");
    var categories = jQuery("#search_categories").val() || "";

    jQuery.ajax({
      url: "/search/json",
      data: {
        query: query,
        include_props: includeProps,
        include_views: includeViews,
        include_obsolete: includeObsolete,
        include_non_production: includeNonProduction,
        only_definitions: includeOnlyDefinitions,
        exact_match: exactMatch,
        categories: categories,
        ontology_ids: onts
      },
      dataType: "json",
      success: function(data){
        var results = [];
        var ontologies = {};
        var ontology_links = [];

        if (!jQuery.isEmptyObject(data)) {
          jQuery(data.results).each(function(){
            results.push(processSearchResult(this).join(""));
          });
        }

        // Obsolete terms should appear at the end with a heading
        if (data.obsolete_results.length > 0) {
          jQuery(data.obsolete_results).each(function(){
            results.push(processSearchResult(this).join(""));
          });
        }

        // Display error message if no results found
        var result_count = jQuery("#result_stats");
        if (data.current_page_results == 0) {
          result_count.html("");
          jQuery("#search_results").html("<h2 style='padding-top: 1em;'>No results found</h2>");
        } else {
          var results_by_ont = jQuery("#ontology_ontologyId").val() === null ? " in <a id='ont_tooltip' href='javascript:void(0);'><span id='ontologies_count_total'>" + data.current_page_results + "</span> ontologies</a><div id='ontology_counts' class='ontology_counts_tooltip'/>" : "";
          result_count.html("Top <span id='result_count_total'>" + data.disaggregated_current_page_results + "</span> results" + results_by_ont);
          jQuery("#search_results").html(results.join(""));
        }

        jQuery("a[rel*=facebox]").facebox();
        jQuery("#search_results").show();
        jQuery("#search_spinner").hide();
        getAllDefinitions();
      },
      error: function(){
        jQuery("#search_spinner").hide();
        jQuery("#search_results").hide();
        jQuery("#search_messages").html("<span style='color: red'>Problem searching, please try again");
        getAllDefinitions();
      }
    });
  });

  // Search on enter
  jQuery("#search_keywords").bind("keyup", function(event){
    if (event.which == 13) {
      jQuery("#search_button").click();
    }
  });

  // Details/visualze link to show details pane and visualize flexviz
  jQuery.facebox.settings.closeImage = '/javascripts/JqueryPlugins/facebox/closelabel.png';
  jQuery.facebox.settings.loadingImage = '/javascripts/JqueryPlugins/facebox/loading.gif';

  // Position of popup for details
  jQuery(document).bind('reveal.facebox', function(){
    if (jQuery("div.term_details_pop").is(":visible")) {
      jQuery("div.term_details_pop").css("max-height", jQuery(window).height() - jQuery("div.term_details_pop").offset().top * 2 + "px");
    }
  });

  // Use pop-up with flex via an iframe for "visualize" link
  jQuery("a.term_visualize").live("click", (function(){
    var ontologyid = jQuery(this).attr("data-bp_ontologyid");
    var conceptid = jQuery(this).attr("data-bp_conceptid");

    jQuery("#flexviz").html('<iframe src="/flexviz/'+ontologyid+'?conceptid='+conceptid+'" frameborder=0 height="500px" width="500px" scrolling="no"></iframe>').show();
    jQuery.facebox({ div: '#flexviz' });
  }));

  // Check for existing parameters/queries and update UI accordingly
  var params = jQuery.QueryString;
  if ("q" in params || "query" in params) {
    var query = ("q" in params) ? params["q"] : params["query"];
    jQuery("#search_keywords").val(query);

    if (params["exactmatch"] == "true") {
      jQuery("#search_exact_match").click();
    }

    if (params["searchproperties"] == "true") {
      jQuery("#search_include_props").click();
    }

    if ("ontologyids" in params) {
      var ontologyIds = params["ontologyids"].split(",");
      jQuery("#search_select_ontologies").attr("checked", false)
      jQuery("#ontology_ontologyId").val(ontologyIds);
      jQuery("#ontology_ontologyId").trigger("liszt:updated");
      jQuery("#search_select_ontologies").click().change();
    }

    jQuery("#search_button").click();
  } else if (jQuery("#search_keywords").val() != "") {
    jQuery("#search_button").click();
  }
});

function processSearchResult(res) {
  var additional_results = "";
  var additional_results_link = "";

  var label_html = normalizeObsoleteTerms(res);

  // Additional terms for this ontology
  if (typeof res.additional_results !== "undefined" && res.additional_results.length > 0 ||
      typeof res.additional_results_obsolete !== "undefined" && res.additional_results_obsolete.length > 0) {
    var additional_results = res.additional_results;
    var additional_results_obsolete_count = typeof res.additional_results_obsolete !== "undefined" ? res.additional_results_obsolete.length : 0;
    var additional_results_count = typeof res.additional_results !== "undefined" ? res.additional_results.length : 0;
    var additional_rows = [];
    var ontologyId = typeof additional_results === "undefined" || additional_results.length == 0 ? res.additional_results_obsolete[0].ontologyId : additional_results[0].ontologyId;

    additional_results_link = jQuery("<span/>")
      .append(jQuery("<span/>")
      .addClass("additional_results_link search_result_link")
      .html(" - <a href='#additional_results' class='additional_results_link' data-bp_additional_results_for='"+ontologyId+"'>" + (additional_results_count + additional_results_obsolete_count) + " more from this ontology<span class='not_visible hide_link'>[hide]</span></a>")).html();

    if (typeof res.additional_results !== "undefined" && res.additional_results.length > 0) {

      jQuery(additional_results).each(function(){
        additional_rows.push([
          "<div class='search_result_additional'>",
          termHTML(this, normalizeObsoleteTerms(this), false),
          definitionHTML(this, "additional_def_container"),
          "<div class='search_result_links'>"+resultLinksHTML(this)+"</div>",
          "</div>"
        ].join(""));
      });
    }

    // Obsolete terms should appear at the end with a heading
    if (typeof res.additional_results_obsolete !== "undefined" && res.additional_results_obsolete.length > 0) {
      jQuery(res.additional_results_obsolete).each(function(){
        additional_rows.push([
          "<div class='search_result_additional'>",
          termHTML(this, normalizeObsoleteTerms(this), false),
          definitionHTML(this, "additional_def_container"),
          "<div class='search_result_links'>"+resultLinksHTML(this)+"</div>",
          "</div>"
        ].join(""));
      });
    }

    additional_results = jQuery("<div/>")
                                .append(jQuery("<div/>")
                                .attr("id", "additional_results_"+ontologyId)
                                .addClass("additional_results")
                                .addClass("not_visible")
                                .html(additional_rows.join("")))
                              .html();

  }

  var row = [
    "<div class='search_result' data-bp_ont_name='"+res.ontologyDisplayLabel+"' data-bp_ontology_id='"+res.ontologyId+"'>",
    termHTML(res, label_html, true),
    definitionHTML(res),
    "<div class='search_result_links'>"+resultLinksHTML(res) + additional_results_link+"</div>",
    additional_results,
    "</div>"
  ];

  return row;
}

function updatePopupCounts() {
  var ontologies = [];
  jQuery("#search_results div.search_result").each(function(){
    var result = jQuery(this);
    // Add one to the additional results to get total count (1 is for the primary result)
    var resultsCount = result.children("div.additional_results").find("div.search_result_additional").length + 1;
    ontologies.push(result.attr("data-bp_ont_name")+" <span class='popup_counts'>"+resultsCount+"</span><br/>")
  });

  // Sort using case insensitive sorting
  ontologies.sort(function(x, y){
    var a = String(x).toUpperCase();
    var b = String(y).toUpperCase();
    if (a > b)
       return 1
    if (a < b)
       return -1
    return 0;
  });

  // Insert header at beginning
  // ontologies.splice(0, 0, "<b>Ontology<span class='popup_counts'>Results</span></b><br/>");

  jQuery("#ontology_counts").html(ontologies.join(""));
}

function normalizeObsoleteTerms(res) {
  // We have to look for a span here, indicating that the term is obsolete.
  // If not, add the term to a new span to match obsolete structure so we can process them the same.
  var max_word_length = 60;
  var elipses = (res.preferredName.length > max_word_length) ? "..." : "";
  var label_html = (res.isObsolete == "1") ? jQuery(res.label_html) : jQuery("<span/>").append(res.label_html);
  label_html = jQuery("<span/>").append(label_html.html(label_html.html().substring(0, max_word_length)+elipses));
  return label_html;
}

function getAllDefinitions() {
  var keepOnlyDefinitions = jQuery("#search_only_definitions").is(":checked");

  // Notice for filtering search results without definitions
  if (keepOnlyDefinitions) {
    jQuery("#search_messages").html("removing terms without definitions...");
  }

  // Get the top level stuff first
  var count = 0;
  var totalSearchResults = currentResultsCount();
  jQuery("#search_results .def_container .ajax_def").each(function(){
    var def = jQuery(this);
    getDefinition(def, keepOnlyDefinitions, count, totalSearchResults);

    count += 1;
    if (count == totalSearchResults) {
      if (keepOnlyDefinitions) {
        jQuery("#search_messages").html("");
      }
    }
  });

  // Now get the additional that are hidden
  jQuery("#search_results .additional_def_container .ajax_def").each(function(){
    var def = jQuery(this);
    count += 1;
    getDefinition(def, keepOnlyDefinitions, count, totalSearchResults);
  });
}

function getDefinition(def, keepOnlyDefinitions, count, totalSearchResults) {
  jQuery.ajax({
    url: "/ajax/json_term?conceptid="+def.attr("data-bp_conceptid")+"&ontologyid="+def.attr("data-bp_ontologyid"),
    dataType: 'json',
    success: function(data){
      showDefinition(data, def, keepOnlyDefinitions);
      if (count == totalSearchResults) {
        if (keepOnlyDefinitions) {
          jQuery("#search_messages").html("");
        }
      }
    },
    error: function(){
      // Failed to retreive definition
      if (keepOnlyDefinitions) {
        // Remove entire term
        def.parent().parent().html("");
      } else {
        // Remove loading text
        def.parent().html("");
      }

      if (count == totalSearchResults) {
        if (keepOnlyDefinitions) {
          jQuery("#search_messages").html("");
        }
      }
    }
  });
}

function showDefinition(data, def, keepOnlyDefinitions) {
  var defLimit = 210;

  if (typeof keepOnlyDefinitions === "undefined" || keepOnlyDefinitions == null) {
    keepOnlyDefinitions = false;
  }

  if (data !== null && typeof data.definitions !== "undefined" && data.definitions !== null && data.definitions.length != 0) {
    // Strip out xml elements and/or html
    data.definitions = jQuery("<div/>").html(data.definitions).text();

    if (data.definitions.length > defLimit) {
      var defs = data.definitions.slice(0, defLimit).split(" ");
      // Remove the last word in case we got one partway through
      defs.pop();
      def.html(defs.join(" ")+" ...");
    } else {
      def.html(data.definitions)
    }
  } else {
    if (keepOnlyDefinitions) {
      // Remove entire term
      def.parent().parent().remove();
    } else {
      // Remove loading text
      def.parent().html("");
    }
  }

  jQuery(document).trigger("search_results_updated");
}

function advancedOptionsSelected() {
  if (document.URL.indexOf("opt=advanced") >= 0) {
    return true;
  }

  var check = [
    function(){return jQuery("#search_include_props").is(":checked");},
    function(){return jQuery("#search_include_views").is(":checked");},
    function(){return jQuery("#search_include_non_production").is(":checked");},
    function(){return jQuery("#search_include_obsolete").is(":checked");},
    function(){return jQuery("#search_only_definitions").is(":checked");},
    function(){return jQuery("#search_exact_match").is(":checked");},
    function(){return jQuery("#search_categories").val() !== null && jQuery("#search_categories").val().length > 0;},
    function(){return jQuery("#ontology_ontologyId").val() !== null && jQuery("#ontology_ontologyId").val().length > 0;},
  ];

  var length = check.length;
  for (var i = 0; i < length; i++) {
    var selected = check[i]();
    if (selected)
      return true;
  }

  return false;
}

function currentResultsCount() {
  return jQuery(".search_result").length + jQuery(".search_result_additional").length;
}

function currentOntologiesCount() {
  return jQuery(".search_result").length;
}

function termHTML(res, label_html, displayOntologyName) {
  var ontologyName = displayOntologyName ? " - " + res.ontologyDisplayLabel : "";
  return "<div class='term_link'><a title='"+res.preferredName+"' data-bp_conceptid='"+encodeURIComponent(res.conceptId)+"' href='/ontologies/"+res.ontologyId+"?p=terms&conceptid="+encodeURIComponent(res.conceptId)+"'>"+jQuery(label_html).html()+ontologyName+"</a></div>";
}

function resultLinksHTML(res) {
  return "<span class='additional'><a href='/ajax/term_details/"+res.ontologyId+"?styled=false&conceptid="+encodeURIComponent(res.conceptId)+"' class='term_details search_result_link' rel='facebox[.term_details_pop]'>details</a> - <a href='javascript:void(0);' data-bp_ontologyid='"+res.ontologyId+"' data-bp_conceptid='"+encodeURIComponent(res.conceptId)+"' class='term_visualize search_result_link'>visualize</a></span>";
}

function definitionHTML(res, defClass) {
  defClass = typeof defClass === "undefined" ? "def_container" : defClass;
  return "<div class='"+defClass+"'><span class='ajax_def' data-bp_conceptid='"+encodeURIComponent(res.conceptId)+"' data-bp_ontologyid='"+res.ontologyId+"'><em>loading...</em></span></div>";
}