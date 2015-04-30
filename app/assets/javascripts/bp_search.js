"use strict";

// History and navigation management
(function(window, undefined) {
    // Establish Variables
    var History = window.History;
    // History.debug.enable = true;

    // Abort it not right page
    var path = currentPathArray();
    if (path[0] !== "search") {
      return;
    }

    // Bind to State Change
    History.Adapter.bind(window, 'statechange', function() {
      var state = History.getState();
      autoSearch();
    });
}(window));

var showAdditionalResults = function(obj, resultSelector) {
    var ontAcronym = jQuery(obj).attr("data-bp_ont");
    jQuery(resultSelector + ontAcronym).toggleClass("not_visible");
    jQuery(obj).children(".hide_link").toggleClass("not_visible");
    jQuery(obj).toggleClass("not_underlined");
};

var showAdditionalOntResults = function(event) {
    event.preventDefault();
    showAdditionalResults(this, "#additional_ont_results_");
};

var showAdditionalClsResults = function(event) {
    event.preventDefault();
    showAdditionalResults(this, "#additional_cls_results_");
};


// Declare the blacklisted class ID entities at the top level, to avoid
// repetitive execution within blacklistClsIDComponents.  The order of the
// declarations here matches the order of removal.  The fixed strings are
// removed once, the regex strings are removed globally from the class ID.
var blacklistFixStrArr = [],
    blacklistSearchWordsArr = [], // see performSearch and aggregateResultsWithSubordinateOntologies
    blacklistSearchWordsArrRegex = [],
    blacklistRegexArr = [],
    blacklistRegexMod = "ig";
blacklistFixStrArr.push("https://");
blacklistFixStrArr.push("http://");
blacklistFixStrArr.push("bioportal.bioontology.org/ontologies/");
blacklistFixStrArr.push("purl.bioontology.org/ontology/");
blacklistFixStrArr.push("purl.obolibrary.org/obo/");
blacklistFixStrArr.push("swrl.stanford.edu/ontologies/");
blacklistFixStrArr.push("mesh.owl"); // Avoids RH-MESH subordinate to MESH
blacklistRegexArr.push(new RegExp("abnormalities", blacklistRegexMod));
blacklistRegexArr.push(new RegExp("biological", blacklistRegexMod));
blacklistRegexArr.push(new RegExp("biology", blacklistRegexMod));
blacklistRegexArr.push(new RegExp("bioontology", blacklistRegexMod));
blacklistRegexArr.push(new RegExp("clinical", blacklistRegexMod));
blacklistRegexArr.push(new RegExp("extension", blacklistRegexMod));
blacklistRegexArr.push(new RegExp("\.gov", blacklistRegexMod));
blacklistRegexArr.push(new RegExp("ontology", blacklistRegexMod));
blacklistRegexArr.push(new RegExp("ontologies", blacklistRegexMod));
blacklistRegexArr.push(new RegExp("semanticweb", blacklistRegexMod));

function blacklistClsIDComponents(clsID) {
    var strippedID = clsID;
    // remove fixed strings first
    for (var i = 0; i < blacklistFixStrArr.length; i++) {
        strippedID = strippedID.replace(blacklistFixStrArr[i], "");
    };
    // cleanup with regex replacements
    for (var i = 0; i < blacklistRegexArr.length; i++) {
        strippedID = strippedID.replace(blacklistRegexArr[i], "");
    };
    // remove search keywords (see performSearch and aggregateResultsWithSubordinateOntologies)
    for (var i = 0; i < blacklistSearchWordsArrRegex.length; i++) {
        strippedID = strippedID.replace(blacklistSearchWordsArrRegex[i], "");
    };
    return strippedID;
}

function OntologyOwnsClass(clsID, ontAcronym) {
    // Does the clsID contain the ontAcronym?
    // Use case insensitive match
    clsID = blacklistClsIDComponents(clsID);
    return clsID.toUpperCase().lastIndexOf(ontAcronym) > -1;
}

function findOntologyOwnerOfClass(clsID, ontAcronyms) {
    // Find the index of cls_id in cls_list results with the cls_id in the 'owner'
    // ontology (cf. ontologies that import the class, or views).
    var ontAcronym = "",
        ontWeight = 0,
        ontIsOwner = false,
        ontOwner = {
            "acronym": "",
            "index": null,
            "weight": 0
        };
    for (var i = 0, j = ontAcronyms.length; i < j; i++) {
        ontAcronym = ontAcronyms[i];
        // Does the class ID contain the ontology acronym? If so, the result is a
        // potential ontology owner. Update the ontology owner, if the ontology
        // acronym matches and it has a greater 'weight' than any previous ontology owner.
        // Note that OntologyOwnsClass() modifies the clsID to blacklist various strings that
        // cause false or misleading matches for ontology acronyms in class ID.
        if (OntologyOwnsClass(clsID, ontAcronym)) {
            // This weighting that places greater value on matching an ontology acronym later in the class ID.
            ontWeight = ontAcronym.length * (clsID.toUpperCase().lastIndexOf(ontAcronym) + 1);
            if (ontWeight > ontOwner.weight) {
                ontOwner.acronym = ontAcronym;
                ontOwner.index = i;
                ontOwner.weight = ontWeight;
                // Cannot break here, in case another acronym has greater weight.
            }
        }

    }
    return ontOwner;
}




jQuery(document).ready(function() {
    // Wire advanced search categories
    jQuery("#search_categories").chosen({
        search_contains: true
    });
    jQuery("#search_button").button({
        search_contains: true
    });
    jQuery("#search_button").click(function(event) {
        ajax_process_halt();
    });
    jQuery("#search_keywords").click(function(event) {
        ajax_process_halt();
    });

    // Put cursor in search box by default
    jQuery("#search_keywords").focus();

    // Show/hide on refresh
    if (advancedOptionsSelected()) {
        jQuery("#search_options").removeClass("not_visible");
    }

    jQuery("#search_select_ontologies").change(function() {
        if (jQuery(this).is(":checked")) {
            jQuery("#ontology_picker_options").removeClass("not_visible");
        } else {
            jQuery("#ontology_picker_options").addClass("not_visible");
            jQuery("#ontology_ontologyId").val("");
            jQuery("#ontology_ontologyId").trigger("liszt:updated");
        }
    });

    jQuery("#search_results a.additional_ont_results_link").live("click", showAdditionalOntResults);
    jQuery("#search_results a.additional_cls_results_link").live("click", showAdditionalClsResults);

    // Show advanced options
    jQuery("#advanced_options").click(function(event) {
        jQuery("#search_options").toggleClass("not_visible");
        jQuery("#hide_advanced_options").toggleClass("not_visible");
    });

    // Events to run whenever search results are updated (mainly counts)
    jQuery(document).live("search_results_updated", function() {
        // Update count
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
    jQuery("#search_button").click(function(event) {
        event.preventDefault();
        History.pushState(currentSearchParams(), document.title, "/search?" + objToQueryString(currentSearchParams()));
    });

    // Search on enter
    jQuery("#search_keywords").bind("keyup", function(event) {
        if (event.which == 13) {
            jQuery("#search_button").click();
        }
    });

    // Details/visualize link to show details pane and visualize biomixer
    jQuery.facebox.settings.closeImage = '/javascripts/JqueryPlugins/facebox/closelabel.png';
    jQuery.facebox.settings.loadingImage = '/javascripts/JqueryPlugins/facebox/loading.gif';

    // Position of popup for details
    jQuery(document).bind("reveal.facebox", function() {
        if (jQuery("div.class_details_pop").is(":visible")) {
            jQuery("#facebox").css("max-height", jQuery(window).height() - (jQuery("#facebox").offset().top - jQuery(window).scrollTop()) * 2 + "px");
        }
    });

    // Use pop-up with flex via an iframe for "visualize" link
    jQuery("a.class_visualize").live("click", function() {
        var acronym = jQuery(this).attr("data-bp_ontologyid"),
            conceptid = jQuery(this).attr("data-bp_conceptid");
        jQuery("#biomixer").html('<iframe src="/ajax/biomixer/?ontology=' + acronym + '&conceptid=' + conceptid + '" frameborder=0 height="500px" width="500px" scrolling="no"></iframe>').show();
        jQuery.facebox({
            div: '#biomixer'
        });
    });

    autoSearch();
});

// Automatically perform search based on input parameters
function autoSearch() {
    // Check for existing parameters/queries and update UI accordingly
    var params = BP_queryString(),
        query = null,
        ontologyIds = null,
        categories = null;

    if (params.hasOwnProperty("query") || params.hasOwnProperty("q")) {
        query = params.query || params.q;
        jQuery("#search_keywords").val(query);

        if (params.exactmatch === "true" || params.exact_match === "true") {
            if (!jQuery("#search_exact_match").is(":checked")) {
                jQuery("#search_exact_match").attr("checked", true);
            }
        } else {
            jQuery("#search_exact_match").attr("checked", false);
        }

        if (params.searchproperties === "true" || params.include_properties === "true") {
            if (!jQuery("#search_include_properties").is(":checked")) {
                jQuery("#search_include_properties").attr("checked", true);
            }
        } else {
            jQuery("#search_include_properties").attr("checked", false);
        }

        if (params.require_definition === "true") {
            if (!jQuery("#search_require_definition").is(":checked")) {
                jQuery("#search_require_definition").attr("checked", true);
            }
        } else {
            jQuery("#search_require_definition").attr("checked", false);
        }

        if (params.include_views === "true") {
            if (!jQuery("#search_include_views").is(":checked")) {
                jQuery("#search_include_views").attr("checked", true);
            }
        } else {
            jQuery("#search_include_views").attr("checked", false);
        }

        if (params.hasOwnProperty("ontologyids") || params.hasOwnProperty("ontologies")) {
            ontologyIds = params.ontologies || params.ontologyids || "";
            ontologyIds = ontologyIds.split(",");
            jQuery("#ontology_ontologyId").val(ontologyIds);
            jQuery("#ontology_ontologyId").trigger("liszt:updated");
        }

        if (params.hasOwnProperty("categories")) {
            categories = params.categories || "";
            categories = categories.split(",");
            jQuery("#search_categories").val(categories);
            jQuery("#search_categories").trigger("liszt:updated");
        }

      performSearch();
    }

    // Show/hide on refresh
    if (advancedOptionsSelected()) {
      jQuery("#search_options").removeClass("not_visible");
    }
}


function currentSearchParams() {
    var params = {}, ont_val = null;
    // Search query
    params.q = jQuery("#search_keywords").val();
    // Ontologies
    ont_val = jQuery("#ontology_ontologyId").val();
    params.ontologies = (ont_val === null) ? "" : ont_val.join(",");
    // Advanced options
    params.include_properties = jQuery("#search_include_properties").is(":checked");
    params.include_views = jQuery("#search_include_views").is(":checked");
    params.includeObsolete = jQuery("#search_include_obsolete").is(":checked");
    // params.includeNonProduction =
    // jQuery("#search_include_non_production").is(":checked");
    params.require_definition = jQuery("#search_require_definition").is(":checked");
    params.exact_match = jQuery("#search_exact_match").is(":checked");
    params.categories = jQuery("#search_categories").val() || "";
    return params;
}



function objToQueryString(obj) {
    var str = [],
        p = null;
    for (p in obj) {
        if (obj.hasOwnProperty(p)) {
            str.push(encodeURIComponent(p) + "=" + encodeURIComponent(obj[p]));
        }
    }
    return str.join("&");
}

function performSearch() {
    jQuery("#search_spinner").show();
    jQuery("#search_messages").html("");
    jQuery("#search_results").html("");
    jQuery("#result_stats").html("");

    var ont_val = jQuery("#ontology_ontologyId").val() || null,
        onts = (ont_val === null) ? "" : ont_val.join(","),
        query = jQuery("#search_keywords").val(),
        // Advanced options
        includeProps = jQuery("#search_include_properties").is(":checked"),
        includeViews = jQuery("#search_include_views").is(":checked"),
        includeObsolete = jQuery("#search_include_obsolete").is(":checked"),
        includeNonProduction = jQuery("#search_include_non_production").is(":checked"),
        includeOnlyDefinitions = jQuery("#search_require_definition").is(":checked"),
        exactMatch = jQuery("#search_exact_match").is(":checked"),
        categories = jQuery("#search_categories").val() || "";

    // Set the list of search words to be blacklisted for the ontology ownership algorithm
    blacklistSearchWordsArr = query.split(/\s+/);

    jQuery.ajax({
        // bp.config is created in views/layouts/_header..., which calls
        // ApplicationController::bp_config_json
        url: determineHTTPS(jQuery(document).data().bp.config.rest_url) + "/search",
        data: {
            q: query,
            include_properties: includeProps,
            include_views: includeViews,
            obsolete: includeObsolete,
            include_non_production: includeNonProduction,
            require_definition: includeOnlyDefinitions,
            exact_match: exactMatch,
            categories: categories,
            ontologies: onts,
            pagesize: 150,
            apikey: jQuery(document).data().bp.config.apikey,
            userapikey: jQuery(document).data().bp.config.userapikey,
            format: "jsonp"
        },
        dataType: "jsonp",
        success: function(data) {
            var results = [],
                ontologies = {},
                groupedResults = null,
                result_count = jQuery("#result_stats"),
                resultsByOnt = "",
                resultsOntCount = "",
                resultsOntDiv = "";
            if (categories.length > 0) {
                data.collection = filterCategories(data.collection, categories);
            }
            if (!jQuery.isEmptyObject(data)) {
                groupedResults = aggregateResults(data.collection);
                jQuery(groupedResults).each(function() {
                    results.push(formatSearchResults(this));
                });
            }
            // Display error message if no results found
            if (data.collection.length === 0) {
                result_count.html("");
                jQuery("#search_results").html("<h2 style='padding-top: 1em;'>No matches found</h2>");
            } else {
                if (jQuery("#ontology_ontologyId").val() === null) {
                    resultsOntCount = jQuery("<span>");
                    resultsOntCount.attr("id", "ontologies_count_total");
                    resultsOntCount.text(groupedResults.length);
                    resultsByOnt = jQuery("<a>");
                    resultsByOnt.attr({
                        "id": "ont_tooltip",
                        "href": "javascript:void(0)"
                    });
                    resultsByOnt.append("Matches in ");
                    resultsByOnt.append(resultsOntCount);
                    resultsByOnt.append(" ontologies");
                    resultsOntDiv = jQuery("<div>");
                    resultsOntDiv.attr("id", "ontology_counts");
                    resultsOntDiv.addClass("ontology_counts_tooltip");
                    resultsByOnt.append(resultsOntDiv);
                }
                result_count.html(resultsByOnt);
                jQuery("#search_results").html(results.join(""));
            }
            jQuery("a[rel*=facebox]").facebox();
            jQuery("#search_results").show();
            jQuery("#search_spinner").hide();
        },
        error: function() {
            jQuery("#search_spinner").hide();
            jQuery("#search_results").hide();
            jQuery("#search_messages").html("<span style='color: red'>Problem searching, please try again");
        }
    });
}

function aggregateResults(results) {
    // class URI aggregation, promotes a class that belongs to 'owning' ontology,
    // e.g. /search?q=cancer returns several hits for
    // 'http://purl.obolibrary.org/obo/DOID_162'
    // those results should be aggregated below the DOID ontology.
    // var classes = aggregateResultsByClassURI(results);
    var ontologies = aggregateResultsByOntology(results);
    // return aggregateResultsByOntologyWithClasses(results, classes);
    // return aggregateResultsWithoutDuplicateClasses(ontologies, classes);
    // return aggregateResultsWithSubordinateOntologies(ontologies, classes);
    return aggregateResultsWithSubordinateOntologies(ontologies);
}


function aggregateResultsWithSubordinateOntologies(ontologies) {
    var i, j,
        resultsWithSubordinateOntologies = [],
        tmpOnt = null,
        tmpResult = null,
        tmpClsID = null,
        tmpOntOwner = null,
        ontAcronym = null,
        ontAcronyms = [],
        clsOntOwnerTracker = {};
    // build array of ontology acronyms
    for (i = 0, j = ontologies.length; i < j; i++) {
        tmpOnt = ontologies[i];
        tmpResult = tmpOnt.same_ont[0]; // primary result for this ontology
        ontAcronym = ontologyIdToAcronym(tmpResult.links.ontology);
        ontAcronyms.push(ontAcronym);
    }
    // Remove any items in blacklistSearchWordsArr that match ontology acronyms.
    blacklistSearchWordsArrRegex = [];
    for (var i = 0; i < blacklistSearchWordsArr.length; i++) {
        // Convert blacklistSearchWordsArr to regex constructs so they are removed
        // with case insensitive matches in blacklistClsIDComponents
        blacklistSearchWordsArrRegex.push(new RegExp(blacklistSearchWordsArr[i], blacklistRegexMod));

        // Check for any substring matches against ontology acronyms, where the
        // acronyms are assumed to be upper case strings.  (Note, cannot use the
        // ontAcronyms array .indexOf() method, because it doesn't search for
        // substring matches).
        var searchToken = blacklistSearchWordsArr[i];
        var match = false;
        for (var j = ontAcronyms.length - 1; j >= 0; j--) {
            if (ontAcronyms[j].indexOf(searchToken) > -1) {
                match = true;
                break;
            }
        };
        if (match) {
            // Remove this blacklisted search token because it matches or partially matches an ontology acronym.
            blacklistSearchWordsArr.splice(i,1);
            // Don't increment i, the slice moves everything so i+1 is now at i.
        } else {
            i++; // check the next search token.
        }
    }
    // build hash of primary class results with an ontology owner
    for (i = 0, j = ontologies.length; i < j; i++) {
        tmpOnt = ontologies[i];
        tmpOnt.sub_ont = []; // add array for any subordinate ontology results
        tmpResult = tmpOnt.same_ont[0];
        tmpClsID = tmpResult["@id"];
        if (clsOntOwnerTracker.hasOwnProperty(tmpClsID)) {
            continue;
        }
        // find the best match for the ontology owner (must iterate over all ontAcronyms)
        tmpOntOwner = findOntologyOwnerOfClass(tmpClsID, ontAcronyms);
        if (tmpOntOwner.index !== null) {
            // This primary class result is owned by an ontology
            clsOntOwnerTracker[tmpClsID] = tmpOntOwner;
        }
    }
    // aggregate the subordinate results below the owner ontology results
    for (i = 0, j = ontologies.length; i < j; i++) {
        tmpOnt = ontologies[i];
        tmpResult = tmpOnt.same_ont[0];
        tmpClsID = tmpResult["@id"];
        if (clsOntOwnerTracker.hasOwnProperty(tmpClsID)) {
            // get the ontology that owns this class (if any)
            tmpOntOwner = clsOntOwnerTracker[tmpClsID];
            if (tmpOntOwner.index === i) {
                // the current ontology is the owner of this primary result
                resultsWithSubordinateOntologies.push(tmpOnt);
            } else {
                // There is an owner, so put this ont result set into the sub_ont array
                var tmpOwnerOnt = ontologies[tmpOntOwner.index];
                tmpOwnerOnt.sub_ont.push(tmpOnt);
            }
        } else {
            // There is no ontology that owns this primary class result, just
            // display this at the top level (it's not a subordinate)
            resultsWithSubordinateOntologies.push(tmpOnt);
        }
    }
    return resultsWithSubordinateOntologies;
}


function aggregateResultsByOntology(results) {
    // NOTE: Cannot rely on the order of hash keys (obj properties) to preserve
    // the order of the results, see
    // http://stackoverflow.com/questions/280713/elements-order-in-a-for-in-loop
    var ontologies = {
        "list": [], // used to ensure we have ordered ontologies
        "hash": {}
    },
        res = null,
        ont = null;
    for (var r in results) {
        res = results[r];
        ont = res.links.ontology;
        if (typeof ontologies.hash[ont] === "undefined") {
            ontologies.hash[ont] = initOntologyResults();
            // Manage an ordered set of ontologies (no duplicates)
            ontologies.list.push(ont);
        }
        ontologies.hash[ont].same_ont.push(res);
    }
    return resultsByOntologyArray(ontologies);
}


function initOntologyResults() {
    return {
        // classes with same URI
        "same_cls": [],
        // other classes from the same ontology
        "same_ont": [],
        // subordinate ontologies
        "sub_ont": []
    }
}


function resultsByOntologyArray(ontologies) {
    var resultsByOntology = [],
        ont = null;
    // iterate the ordered ontologies, not the hash keys
    for (var i = 0, j = ontologies.list.length; i < j; i++) {
        ont = ontologies.list[i];
        resultsByOntology.push(ontologies.hash[ont]);
    }
    return resultsByOntology;
}


function aggregateResultsByClassURI(results) {
    var cls_hash = {}, res = null,
        cls_id = null;
    for (var r in results) {
        res = results[r];
        cls_id = res['@id'];
        if (typeof cls_hash[cls_id] === "undefined") {
            cls_hash[cls_id] = {
                "clsResults": [],
                "clsOntOwner": null
            };
        }
        cls_hash[cls_id].clsResults.push(res);
    }
    promoteClassesWithOntologyOwner(cls_hash);
    // passed by ref, modified in-place.
    return cls_hash;
}


function promoteClassesWithOntologyOwner(cls_hash) {
    var cls_id = null,
        clsData = null,
        ont_owner_result = null;
    // Detect and 'promote' the class with an 'owner' ontology.
    for (cls_id in cls_hash) {
        clsData = cls_hash[cls_id];
        // Find the class in the 'owner' ontology (cf. ontologies that import the
        // class, or views). Only promote the class result if the ontology owner
        // is not already in the first position.
        clsData.clsOntOwner = findClassWithOntologyOwner(cls_id, clsData.clsResults);
        if (clsData.clsOntOwner.index > 0) {
            // pop the owner and shift it to the top of the list; note that splice and
            // unshift modify in-place so there's no need to reassign into cls_hash.
            ont_owner_result = clsData.clsResults.splice(clsData.clsOntOwner.index, 1)[0];
            clsData.clsResults.unshift(ont_owner_result);
            clsData.clsOntOwner.index = 0;
        }
    }
}


function findClassWithOntologyOwner(cls_id, cls_list) {
    // Find the index of cls_id in cls_list results with the cls_id in the 'owner'
    // ontology (cf. ontologies that import the class, or views).
    var clsResult = null,
        ontAcronym = "",
        ontOwner = {
            "index": null,
            "acronym": ""
        }, ontIsOwner = false;
    for (var i = 0, j = cls_list.length; i < j; i++) {
        clsResult = cls_list[i];
        ontAcronym = ontologyIdToAcronym(clsResult.links.ontology);
        // Does the cls_id contain the ont acronym? If so, the result is a
        // potential ontology owner. Update the ontology owner, if the ontology
        // acronym matches and it is longer than any previous ontology owner.
        ontIsOwner = OntologyOwnsClass(ontAcronym, clsID);
        if (ontIsOwner && (ontAcronym.length > ontOwner.acronym.length)) {
            ontOwner.acronym = ontAcronym;
            ontOwner.index = i;
            // console.log("Detected owner: index = " + ontOwner.index + ", ont = " + ontOwner.acronym);
        }
    }
    return ontOwner;
}


var sortStringFunction = function(a, b) {
    // See http://www.sitepoint.com/sophisticated-sorting-in-javascript/
    var x = String(a).toLowerCase(),
        y = String(b).toLowerCase();
    return x < y ? -1 : x > y ? 1 : 0;
};

function sortResultsByOntology(results) {
    // See http://www.sitepoint.com/sophisticated-sorting-in-javascript/
    return results.sort(function(a, b) {
        var ontA = String(a.links.ontology).toLowerCase(),
            ontB = String(b.links.ontology).toLowerCase();
        return ontA < ontB ? -1 : ontA > ontB ? 1 : 0;
    });
}


function formatSearchResults(aggOntologyResults) {
    var
    ontResults = aggOntologyResults.same_ont,
        clsResults = aggOntologyResults.same_cls,
        // init primary result values
        res = ontResults.shift(),
        ontAcronym = ontologyIdToAcronym(res.links.ontology),
        clsID = res["@id"],
        clsCode = encodeURIComponent(clsID),
        label_html = classLabelSpan(res),
        // init search results jQuery objects
        searchResultLinks = null,
        searchResultDiv = null,
        additionalResultsSpan = null,
        additionalResultsHide = null,
        additionalOntResultsAnchor = null,
        additionalOntResults = "",
        additionalOntResultsAttr = null,
        additionalClsResults = "",
        additionalClsResultsAttr = null,
        additionalClsResultsAnchor = null;

    searchResultDiv = jQuery("<div>");
    searchResultDiv.addClass("search_result");
    searchResultDiv.attr("data-bp_ont_id", res.links.ontology);
    searchResultDiv.append(classDiv(res, label_html, true));
    searchResultDiv.append(definitionDiv(res));

    additionalResultsSpan = jQuery("<span>");
    additionalResultsSpan.addClass("additional_results_link");
    additionalResultsSpan.addClass("search_result_link");

    additionalResultsHide = jQuery("<span>");
    additionalResultsHide.addClass("not_visible");
    additionalResultsHide.addClass("hide_link");
    additionalResultsHide.text("[hide]");

    // Process additional ontology results
    if (ontResults.length > 0) {
        additionalOntResultsAttr = {
            "href": "#additional_ont_results",
            "data-bp_ont": ontAcronym,
            "data-bp_cls": clsID
        };
        additionalOntResultsAnchor = jQuery("<a>");
        additionalOntResultsAnchor.addClass("additional_ont_results_link");
        additionalOntResultsAnchor.addClass("search_result_link");
        additionalOntResultsAnchor.attr(additionalOntResultsAttr);
        additionalOntResultsAnchor.append(ontResults.length + " more from this ontology");
        additionalOntResultsAnchor.append(additionalResultsHide.clone());
        additionalResultsSpan.append(" - ");
        additionalResultsSpan.append(additionalOntResultsAnchor);
        additionalOntResults = formatAdditionalOntResults(ontResults, ontAcronym);
    }

    // Process additional clsResults
    if (clsResults.length > 0) {
        additionalClsResultsAttr = {
            "href": "#additional_cls_results",
            "data-bp_ont": ontAcronym,
            "data-bp_cls": clsID
        };
        additionalClsResultsAnchor = jQuery("<a>");
        additionalClsResultsAnchor.addClass("additional_cls_results_link");
        additionalClsResultsAnchor.addClass("search_result_link");
        additionalClsResultsAnchor.attr(additionalClsResultsAttr);
        additionalClsResultsAnchor.append(clsResults.length + " more for this class");
        additionalClsResultsAnchor.append(additionalResultsHide.clone());
        additionalResultsSpan.append(" - ");
        additionalResultsSpan.append(additionalClsResultsAnchor);
        additionalClsResults = formatAdditionalClsResults(clsResults, ontAcronym);
    }

    // Nest subordinate ontology results
    var subOntResults = "",
        subordinateOntTitle = "";
    if (aggOntologyResults.sub_ont.length > 0) {
        subOntResults = jQuery("<div>");
        subOntResults.addClass("subordinate_ont_results");
        subordinateOntTitle = jQuery("<h3>");
        subordinateOntTitle.addClass("subordinate_ont_results_title");
        subordinateOntTitle.addClass("search_result_link");
        subordinateOntTitle.attr("data-bp_ont", ontAcronym);
        subordinateOntTitle.text("Additional References from other Ontologies");
        subOntResults.append(subordinateOntTitle);
        jQuery(aggOntologyResults.sub_ont).each(function() {
            subOntResults.append(formatSearchResults(this));
        });
    }

    searchResultLinks = jQuery("<div>");
    searchResultLinks.addClass("search_result_links");
    searchResultLinks.append(resultLinksSpan(res));
    searchResultLinks.append(additionalResultsSpan);

    searchResultDiv.append(searchResultLinks);
    searchResultDiv.append(additionalOntResults);
    searchResultDiv.append(additionalClsResults);
    searchResultDiv.append(subOntResults);
    return searchResultDiv.prop("outerHTML");
}



function formatAdditionalClsResults(clsResults, ontAcronym) {
    var additionalClsTitle = null,
        clsResultsFormatted = null,
        searchResultDiv = null,
        classLabelDiv = null,
        classDetailsDiv = null;
    additionalClsTitle = jQuery("<h3>");
    additionalClsTitle.addClass("additional_cls_results_title");
    additionalClsTitle.text("Same Class URI - Other Ontologies");
    clsResultsFormatted = jQuery("<div>");
    clsResultsFormatted.attr("id", "additional_cls_results_" + ontAcronym);
    clsResultsFormatted.addClass("additional_cls_results");
    clsResultsFormatted.addClass("not_visible");
    clsResultsFormatted.append(additionalClsTitle);
    jQuery(clsResults).each(function() {
        searchResultDiv = jQuery("<div>");
        searchResultDiv.addClass("search_result_links");
        searchResultDiv.append(resultLinksSpan(this));
        // class prefLabel with ontology name
        classLabelDiv = classDiv(this, classLabelSpan(this), true);
        classDetailsDiv = jQuery("<div>");
        classDetailsDiv.addClass("search_result_additional");
        classDetailsDiv.append(classLabelDiv);
        classDetailsDiv.append(definitionDiv(this, "additional_def_container"));
        classDetailsDiv.append(searchResultDiv);
        clsResultsFormatted.append(classDetailsDiv);
    });
    return clsResultsFormatted;
}

function formatAdditionalOntResults(ontResults, ontAcronym) {
    var additionalOntTitle = null,
        ontResultsFormatted = null,
        searchResultDiv = null,
        classLabelDiv = null,
        classDetailsDiv = null;
    additionalOntTitle = jQuery("<span>");
    additionalOntTitle.addClass("additional_ont_results_title");
    additionalOntTitle.addClass("search_result_link");
    additionalOntTitle.attr("data-bp_ont", ontAcronym);
    additionalOntTitle.text("Same Ontology - Other Classes");
    ontResultsFormatted = jQuery("<div>");
    ontResultsFormatted.attr("id", "additional_ont_results_" + ontAcronym);
    ontResultsFormatted.addClass("not_visible");
    // ontResultsFormatted.addClass( "additional_ont_results" );
    // ontResultsFormatted.append( additionalOntTitle );
    jQuery(ontResults).each(function() {
        searchResultDiv = jQuery("<div>");
        searchResultDiv.addClass("search_result_links");
        searchResultDiv.append(resultLinksSpan(this));
        // class prefLabel without ontology name
        classLabelDiv = classDiv(this, classLabelSpan(this), false);
        classDetailsDiv = jQuery("<div>");
        classDetailsDiv.addClass("search_result_additional");
        classDetailsDiv.append(classLabelDiv);
        classDetailsDiv.append(definitionDiv(this, "additional_def_container"));
        classDetailsDiv.append(searchResultDiv);
        ontResultsFormatted.append(classDetailsDiv);
    });
    return ontResultsFormatted;
}

function updatePopupCounts() {
    var ontologies = [],
        result = null,
        resultsCount = 0;
    jQuery("#search_results div.search_result").each(function() {
        result = jQuery(this);
        // Add one to the additional results to get total count (1 is for the
        // primary result)
        resultsCount = result.children("div.additional_ont_results").find("div.search_result_additional").length + 1;
        ontologies.push(result.attr("data-bp_ont_name") + " <span class='popup_counts'>" + resultsCount + "</span><br/>");
    });
    // Sort using case insensitive sorting
    ontologies.sort(sortStringFunction);
    jQuery("#ontology_counts").html(ontologies.join(""));
}


function classLabelSpan(cls) {
    // Wrap the class prefLabel in a span, indicating that the  class is obsolete
    // if necessary.
    var MAX_LENGTH = 60,
        labelText = cls.prefLabel,
        labelSpan = null;
    if (labelText > MAX_LENGTH) {
        labelText = cls.prefLabel.substring(0, MAX_LENGTH) + "...";
    }
    labelSpan = jQuery("<span>").text(labelText);
    if (cls.obsolete === true) {
        labelSpan.addClass('obsolete_class');
        labelSpan.attr('title', 'obsolete class');
    } else {
        labelSpan.addClass('prefLabel');
    }
    return labelSpan;
    // returns a jQuery object; use .prop('outerHTML') to get markup.
}

function filterCategories(results, filterCats) {
    var newResults = [],
        result = null,
        acronym = null;
    jQuery(results).each(function() {
        result = this;
        acronym = ontologyIdToAcronym(result.links.ontology);
        jQuery(filterCats).each(function() {
            if (categoriesMap[this].indexOf(acronym) > -1) {
                newResults.push(result);
            }
        });
    });
    return newResults;
}

function shortenDefinition(def) {
    var defLimit = 210,
        defWords = null;
    if (typeof def !== "undefined" && def !== null && def.length > 0) {
        // Make sure definitions isn't an array
        def = (typeof def === "string") ? def : def.join(". ");
        // Strip out xml elements and/or html
        def = jQuery("<div/>").html(def).text();
        if (def.length > defLimit) {
            defWords = def.slice(0, defLimit).split(" ");
            // Remove the last word in case we got one partway through
            defWords.pop();
            def = defWords.join(" ") + " ...";
        }
    }
    jQuery(document).trigger("search_results_updated");
    return def || "";
}

function advancedOptionsSelected() {
    var selected = null,
        check = null,
        i = null,
        j = null;
    if (document.URL.indexOf("opt=advanced") >= 0) {
        return true;
    }
    check = [

        function() {
            return jQuery("#search_include_properties").is(":checked");
        },
        function() {
            return jQuery("#search_include_views").is(":checked");
        },
        function() {
            return jQuery("#search_include_non_production").is(":checked");
        },
        function() {
            return jQuery("#search_include_obsolete").is(":checked");
        },
        function() {
            return jQuery("#search_only_definitions").is(":checked");
        },
        function() {
            return jQuery("#search_exact_match").is(":checked");
        },
        function() {
            return jQuery("#search_categories").val() !== null && (jQuery("#search_categories").val() || []).length > 0;
        },
        function() {
            return jQuery("#ontology_ontologyId").val() !== null && (jQuery("#ontology_ontologyId").val() || []).length > 0;
        }
    ];
    for (i = 0, j = check.length; i < j; i++) {
        selected = check[i]();
        if (selected) {
            return true;
        }
    };
    return false;
}

function ontologyIdToAcronym(id) {
    return id.split("/").slice(-1)[0];
}

function getOntologyName(cls) {
    var ont = jQuery(document).data().bp.ontologies[cls.links.ontology];
    if (typeof ont === 'undefined') {
        return "";
    }
    return " - " + ont.name + " (" + ont.acronym + ")";
}

function currentResultsCount() {
    return jQuery(".search_result").length + jQuery(".search_result_additional").length;
}

function currentOntologiesCount() {
    return jQuery(".search_result").length;
}

function classDiv(res, clsLabel, displayOntologyName) {
    var clsID = null,
        clsCode = null,
        clsURI = null,
        ontAcronym = null,
        ontName = null,
        clsAttr = null,
        clsAnchor = null,
        clsIdDiv = null;
    ontAcronym = ontologyIdToAcronym(res.links.ontology);
    clsID = res["@id"];
    clsCode = encodeURIComponent(clsID);
    clsURI = "/ontologies/" + ontAcronym + "?p=classes&conceptid=" + clsCode;
    ontName = displayOntologyName ? getOntologyName(res) : "";
    clsAttr = {
        "title": res.prefLabel,
        "data-bp_conceptid": clsID,
        "data-exact_match": res.exactMatch,
        "href": clsURI
    };
    clsAnchor = jQuery("<a>");
    clsAnchor.attr(clsAttr);
    clsAnchor.append(clsLabel);
    clsAnchor.append(ontName);
    clsIdDiv = jQuery("<div>");
    clsIdDiv.addClass("concept_uri");
    clsIdDiv.text(res["@id"]);
    return jQuery("<div>").addClass("class_link").append(clsAnchor).append(clsIdDiv);
}


function resultLinksSpan(res) {
    var ontAcronym = null,
        clsID = null,
        clsCode = null,
        detailsAttr = null,
        detailsAnchor = null,
        vizAttr = null,
        vizAnchor = null,
        resLinks = null;
    ontAcronym = ontologyIdToAcronym(res.links.ontology);
    clsID = res["@id"];
    clsCode = encodeURIComponent(clsID);
    // construct link for class 'details' in facebox
    detailsAttr = {
        "href": "/ajax/class_details?ontology=" + ontAcronym + "&conceptid=" + clsCode + "&styled=false",
        "rel": "facebox[.class_details_pop]"
    };
    detailsAnchor = jQuery("<a>");
    detailsAnchor.attr(detailsAttr);
    detailsAnchor.addClass("class_details");
    detailsAnchor.addClass("search_result_link");
    detailsAnchor.text("details");
    // construct link for class 'visualizer' in facebox
    vizAttr = {
        "href": "javascript:void(0);",
        "data-bp_conceptid": clsID,
        "data-bp_ontologyid": ontAcronym
    };
    vizAnchor = jQuery("<a>");
    vizAnchor.attr(vizAttr);
    vizAnchor.addClass("class_visualize");
    vizAnchor.addClass("search_result_link");
    vizAnchor.text("visualize");
    resLinks = jQuery("<span>");
    resLinks.addClass("additional");
    resLinks.append(detailsAnchor);
    resLinks.append(" - ");
    resLinks.append(vizAnchor);
    return resLinks;
}


function definitionDiv(res, defClass) {
    defClass = typeof defClass === "undefined" ? "def_container" : defClass;
    return jQuery("<div>").addClass(defClass).text(shortenDefinition(res.definition));
}

function determineHTTPS(url) {
    return url.replace("http:", ('https:' == document.location.protocol ? 'https:' : 'http:'));
}