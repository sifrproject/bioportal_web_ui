// History and navigation management
(function(window,undefined) {
  // Establish Variables
  var History = window.History;
  History.debug.enable = true;

  // Bind to State Change
  History.Adapter.bind(window, 'statechange', function() {
    var state = History.getState();
    if (typeof state.data.route !== "undefined") {
      router.route(state.data.route, state.data);
    } else {
      router.route("index");
    }
  });
})(window);

var bpResourceIndexEmbedded = false;
jQuery(document).ready(function(){
  bpResourceIndexEmbedded = (jQuery("#resource_table").parents("div.resource_index_embed").length > 0);

  // Hide/Show resources
  jQuery(".resource_link").live("click", function(event){
    event.preventDefault();
    switchResources(this);
  });

  // Spinner for pagination
  jQuery(".pagination a").live("click", function(){
    jQuery(this).parents("div.pagination").append('&nbsp;&nbsp; <span style="font-size: small; font-weight: normal;">loading</span> <img style="vertil-align: text-bottom;" src="/images/spinners/spinner_000000_16px.gif">');
  })

  // Make chosen work via ajax
  if (jQuery("#resource_index_terms").length > 0) {
    jQuery("#resource_index_terms").ajaxChosen({
        minLength: 3,
        queryLimit: 10,
        delay: 500,
        chosenOptions: {},
        searchingText: "Searching for term ",
        noresultsText: "Term not found",
        initialQuery: false
      }, function (options, response, event) {
        // jQuery("#resource_index_terms_chzn .chzn-results li.active-result").remove();
        jQuery.getJSON("/search/json", {query: options.term, ontology_ids: currentOntologyIds().join(",")}, function (data) {
          var terms = {};
          jQuery.each(data.results, function (index, result) {
              terms[result.ontologyId + "/" + result.conceptIdShort] = "&nbsp;<span title='" + result.ontologyDisplayLabel + "'>" + result.preferredName + "<span class='search_dropdown_ont'>(" + result.ontologyDisplayLabel + ")</span></span>";
          });
          response(terms);
      });
    });
  }

  // If all terms are removed from the search, put the UI in base state
  jQuery("a.search-choice-close").live("click", function(){
    if (currentConceptIds() === null) {
      pushIndex();
      var input = document.activeElement
      jQuery("#resource_index_terms_chzn").trigger("mousedown");
      input.blur();
      jQuery("#resource_index_terms_chzn input").data("prevVal", "");
      jQuery("#resource_index_terms_chzn .chzn-results li").remove();
    }
  })

  // Get search results
  if (jQuery("#resource_index_button").length > 0) {
    jQuery("#resource_index_button").click(function(){
      var url = "/resource_index/resources?conceptids="+currentConceptIds().join(",");
      pushDisplayResources(url, {conceptids: currentConceptIds()});
      getSearchResults();
    });
  }

  // Show/Hide results with zero matches
  jQuery("#show_hide_no_results").live("click", function(){
    jQuery("#resource_table .zero_results").toggleClass("not_visible").effect("highlight", { color: "yellow" }, 500);
    jQuery("#show_hide_no_results .show_hide_text").toggleClass("not_visible");
  });

  jQuery(".show_element_details").live("click", function(e){
    e.preventDefault();

    var el = jQuery(this);
    var cleanElementId = el.attr("data-clean_element_id");
    var el_text = jQuery("#"+cleanElementId+"_text");
    el_text.toggleClass("not_visible");
    if (el_text.attr("highlighted") !== "true") {
      var element = new Element(el.attr("data-element_id"), cleanElementId, currentConceptIds(), el.attr("data-resource_id"));
      jQuery("#"+element.cleanId+"_text .ri_legend_container").append("<span id='"+element.cleanId+"_ani'class='highlighting'>highlighting... <img style='vertical-align: text-bottom;' src='/images/spinners/spinner_000000_16px.gif'></span>");
      element.highlightAnnotationPositions();
      el_text.attr("highlighted", "true");
    }
  });
});

// Get parameters from the URL
var BP_urlParams = {};
(function () {
    var match,
        pl     = /\+/g,  // Regex for replacing addition symbol with a space
        search = /([^&=]+)=?([^&]*)/g,
        decode = function (s) { return decodeURIComponent(s.replace(pl, " ")); },
        query  = window.location.search.substring(1);
        queryH = window.location.hash.substring(1);

    while (match = search.exec(query))
       BP_urlParams[decode(match[1])] = decode(match[2]);
    while (match = search.exec(queryH))
       BP_urlParams[decode(match[1])] = decode(match[2]);
})();

function pageInit() {
  var state = History.getState();
  var params = {}, paramLocations = ["root", "resources", "resourceId"], route, queryString;
  route = state.hash.split("?");
  queryString = (typeof route[1] !== "undefined") ? "" : route[1];
  route = route[0].split("/").slice(1);
  for (var i = 0; i < route.length; i++) {
    params[paramLocations[i]] = route[i];
  }
  jQuery.extend(params, BP_urlParams);
  params["conceptids"] = (typeof params["conceptids"] !== "undefined") ? params["conceptids"].split(",") : undefined;
  BP_urlParams = params;

  if (typeof params["resourceId"] !== "undefined") {
    router.route("resource", params);
  } else if (typeof params["resources"] !== "undefined") {
    router.route("resources", params);
  }
}

function pushDisplayResource(url, params) {
  var route = "resource";
  if (bpResourceIndexEmbedded) {
    router.route(route, params);
  } else {
    params["route"] = route;
    History.pushState(params, document.title, url);
  }
}

function pushDisplayResources(url, params) {
  var route = "resources";
  if (bpResourceIndexEmbedded) {
    router.route(route, params);
  } else {
    params["route"] = "resources";
    History.pushState(params, document.title, url);
  }
}

function pushIndex() {
  var route = "index";
  if (bpResourceIndexEmbedded) {
    router.route(route);
  } else {
    History.pushState(null, document.title, "/resource_index");
  }
}

function replaceIndex() {
  var route = "index";
  if (bpResourceIndexEmbedded) {
    router.route(route);
  } else {
    History.replaceState(null, document.title, "/resource_index");
  }
}

// This will look up any term labels that haven't already been processed. If there are none it just exits without doing anything.
// To decrease ajax calls, we also use the bp_term_cache. This method is used via polling.
var bp_term_cache = {};
function lookupTermLabels() {
  jQuery("#resource_results a.ri_concept[data-applied_label='false']").each(function(){
    var link = jQuery(this);
    var params = { conceptid: link.data("concept_id"), ontologyid: link.data("ontology_id") };
    link.attr("data-applied_label", "true");

    // Check to see if another thread is already making an ajax request and start polling
    if (bp_term_cache[params.ontologyid+"/"+params.conceptid] === "getting") {
      return setTimeout((function() {
        return applyTermLabel(link, params);
      }), 100);
    }

    if (typeof bp_term_cache[params.ontologyid+"/"+params.conceptid] === "undefined") {
      bp_term_cache[params.ontologyid+"/"+params.conceptid] = "getting";
      jQuery.ajax({
        url: "/ajax/json_term",
        data: params,
        dataType: 'json',
        success: (function(link){
          return function(data){
            bp_term_cache[params.ontologyid+"/"+params.conceptid] = data;
            if (data !== null) jQuery(link).html(data.label);
          }
        })(this),
      });
    }
  })
}

// Poll for term information
jQuery(document).ready(function(){
  setInterval((function() {
    lookupTermLabels();
 }), 1000);
})

// This function will poll to see if term information exists
function applyTermLabel(link, params, calledAgain) {
  var term_info = bp_term_cache[params.ontologyid+"/"+params.conceptid];

  if (term_info === "getting") {
    if (typeof calledAgain !== "undefined") calledAgain = 0
    return setTimeout((function() {
      return applyTermLabel(link, params, calledAgain += 1);
    }), 100);
  }

  if (term_info !== null) jQuery(link).html(term_info.label);
}

function Router() {
  this.route = function(route, params) {
    switch(route) {
      case "index":
        this.index();
        break;
      case "resources":
        this.resources(params);
        break;
      case "resource":
        this.resource(params);
        break;
    }
  }

  this.index = function() {
    jQuery("#results").html("");
    jQuery("#results_error").html("");
    jQuery("#resource_index_terms_chzn .search-choice-close").click();
  }

  this.resources = function(params) {
    if (typeof params["conceptids"] === "undefined") {
      replaceIndex();
    }

    displayResources(params["conceptids"]);
  }

  this.resource = function(params) {
    if (typeof params["conceptids"] === "undefined" || typeof params["resourceId"] === "undefined") {
      replaceIndex();
    }

    displayResource(params);
  }
}
router = new Router();

function displayResource(params) {
  var resource = params["resourceId"];
  var resourceName = resources[resource.toLowerCase()].resourceName;

  // Only retreive term information if this is an initial load
  if (jQuery("#resource_index_terms").val() !== null) {
    showResourceResults(resource, resourceName);
    return;
  }

  displayTerms(params["conceptids"], function() {
    showResourceResults(resource, resourceName);
  });
}

function displayResources(concepts) {
  // Only retreive term information if this is an initial load
  if (jQuery("#resource_index_terms").val() !== null) {
    showAllResources();
    return;
  }

  displayTerms(concepts);
}

function displayTerms(concepts, completedCallback) {
  var concept, conceptOpt, ontologyId, conceptId, ontologyName, conceptRetreivedCount, conceptsLength = concepts.length, params;

  conceptRetreivedCount = 0;
  jQuery("#resource_index_terms").html("");
  for (var i = 0; i < conceptsLength; i++) {
    concept = concepts[i];
    ontologyId = concept.split("/")[0];
    conceptId = concept.split("/")[1];
    ontologyName = ont_names[ontologyId];
    params = { ontologyid: ontologyId, conceptid: conceptId };
    jQuery.getJSON("/ajax/json_term", params, (function(ontologyName){
      return function(data){
        jQuery("#resource_index_terms").append(jQuery("<option/>").val(concept).html(" "+data.label+" <span class='search_dropdown_ont'>("+ontologyName+")</span>"));
        conceptRetreivedCount += 1;
        if (conceptRetreivedCount == conceptsLength) {
          for (var j = 0; j < conceptsLength; j++) {
            conceptOpt = concepts[j];
            jQuery("#resource_index_terms option[value='"+conceptOpt+"']").attr("selected", true);
          }
          updateChosen();
          getSearchResults(completedCallback);
        }
      }
    })(ontologyName));
  }
}

function updateChosen() {
  jQuery("#resource_index_terms").trigger("liszt:updated");
  jQuery("#resource_index_terms").trigger("change");
}

function getSearchResults(success) {
  jQuery("#results_error").html("");
  jQuery("#resource_index_spinner").show();
  jQuery("#results.contains_search_results").hide();
  var params = {
    "ontologyids": currentOntologyIds(),
    "conceptids": currentConceptIds()
  };

  jQuery.ajax({
    type: 'POST',
    url: '/resource_index',
    data: params,
    dataType: 'html',
    success: function(data) {
      jQuery("#results").html(data);
      jQuery("#results").addClass("contains_search_results");
      jQuery("#results.contains_search_results").show();
      jQuery("#results_container").show();
      jQuery("#resource_index_spinner").hide();

      if (success && typeof success === "function") {
        success();
      }

      jQuery("#resource_table table").dataTable({
        "bPaginate": false,
        "bFilter": false,
        "aoData": [
          { "sType": "html" },
          { "sType": "html-formatted-num", "asSorting": [ "desc", "asc"] },
          { "sType": "html-formatted-num", "asSorting": [ "desc", "asc"] }
        ]
      });

      // Update result counts for resources with matches
      updateCounts();
    },
    error: function() {
      jQuery("#resource_index_spinner").hide();
      jQuery("#results_error").html("Problem retrieving search results, please try again");
    }
  })
}

function updateCounts() {
  var hiddenRows, totalRows, visibleRows;
  hiddenRows = jQuery("#resource_table table tbody tr.not_visible").length;
  totalRows = jQuery("#resource_table table tbody tr").length;
  visibleRows = totalRows - hiddenRows;
  jQuery("#result_counts").html("matches in "+visibleRows+" of "+totalRows+" resources")
}

jQuery("a.results_link").live("click", function(event){
  var resource = jQuery(this).data("resource_id");
  var resourceName = jQuery(this).data("resource_name");
  var url = "/resource_index/resources/"+resource+"?conceptids="+currentConceptIds().join(",");
  pushDisplayResource(url, {conceptids: currentConceptIds(), resourceId: resource});
});

jQuery("a#show_all_resources").live("click", function(){
  var url = "/resource_index/resources?conceptids="+currentConceptIds().join(",");
  pushDisplayResources(url, {conceptids: currentConceptIds()});
});

function showResourceResults(resource, resourceName) {
  jQuery(".resource_info").addClass("not_visible");
  jQuery("#resource_table").addClass("not_visible");
  jQuery("#resource_info_"+resource).removeClass("not_visible");
  jQuery("#resource_title").html(resourceName);
  jQuery(".resource_title").removeClass("not_visible");
  jQuery("#resource_title").removeClass("not_visible");
  updateCounts();
}

function showAllResources() {
  jQuery(".resource_info").addClass("not_visible");
  jQuery(".resource_title").addClass("not_visible");
  jQuery("#resource_title").addClass("not_visible");
  jQuery("#resource_table").removeClass("not_visible");
  updateCounts();
}

function Element(id, cleanId, conceptIds, resource) {
  this.positions;
  this.id = id;
  this.cleanId = cleanId;
  this.jdomId = "#"+cleanId+"_text";
  this.conceptIds = conceptIds;
  this.resource = resource;
  this.loadAni = null;

  this.highlightAnnotationPositions = function() {
    var element = this;
    jQuery.ajax({
      url: "/resource_index/element_annotations",
      data: {
        elementid: this.id,
        conceptids: this.conceptIds.join(","),
        resourceid: this.resource
      },
      dataType: "json",
      success: function(data) {
        element.positions = data;
        element.highlight();
      }
    });
  }

  this.highlight = function() {
    var element = this;
    jQuery.each(this.positions,
      function(contextName, positions){
        var context = jQuery(element.jdomId+" p[data-context_name="+contextName+"]");
        if (context.length !== 0) {
          highlighter = new PositionHighlighter();
          // Replace the current text with highlighted version
          context.html(highlighter.highlightUsingPosition(context.html(), positions));
        }
      }
    );
    jQuery("#"+this.cleanId+"_text").find(".highlighting").remove();
    if (this.loadAni !== null) {
      clearInterval(this.loadAni);
    }
  }
}

function PositionHighlighter() {
  this.offsetPositions = [];
  this.textToHighlight = "";

  this.highlightUsingPosition = function(text, positions) {
    // This is stupid, but annotator/resource index output starts counting text at one
    var start = 1;
    var end = text.length;
    var positionsLength = positions.length;
    var highlightType, startPosition, endPosition;

    // We do this to decode HTML entities
    this.textToHighlight = jQuery("<div/>").html(text).text();

    // Starting offsets should be zero
    for (var i = start; i <= end; i++) {
      this.offsetPositions[i] = 0;
    }

    for (var j = 0; j < positionsLength; j++) {
      highlightType = positions[j]['type'];
      startPosition = positions[j]['from'];
      endPosition = positions[j]['to'];

      // Add the highlight opener
      this.addText("<span class='"+highlightType+"'>", startPosition, -1);
      // Add the highlight closer
      this.addText("</span>", endPosition, 0);
    }

    return this.textToHighlight;
  }

  this.updatePositions = function(start, added_count) {
    var offset_length = this.offsetPositions.length;
    for (var i = start; i <= offset_length; i++) {
      this.offsetPositions[i] += added_count;
    }
  }

  this.addText = function(textToAdd, position, offset) {
    this.textToHighlight = [this.textToHighlight.slice(0, this.getActualPosition(position) + offset), textToAdd, this.textToHighlight.slice(this.getActualPosition(position) + offset)].join('');
    this.updatePositions(position, textToAdd.length);
  }

  this.getActualPosition = function(position) {
    return position + this.offsetPositions[position];
  }
}

function currentOntologyIds() {
  var selectedOntIds = jQuery("#ontology_ontologyId").val();
  return selectedOntIds == null || selectedOntIds === "" ? ri_ontology_ids : selectedOntIds;
}

function currentConceptIds() {
  var conceptIds = jQuery("#resource_index_terms").val();
  if (typeof conceptIds === "string") {
    conceptIds = conceptIds.split(",");
  }
  return conceptIds;
}

