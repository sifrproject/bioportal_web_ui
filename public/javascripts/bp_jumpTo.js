
// search box selector can be overriden in search_box_init.
var searchBoxSelector = "#search_box";

// Called when the "Go" button on the Jump To form is clicked
function jumpToValue(li) {
	if (jQuery("#jump_to_concept_id") == null && jQuery("#jump_to_ontology_id") == null) {
		var search = confirm("Class could not be found or is not browsable in " + BP_SITE + ".\n\nPress OK to go to the " + BP_SITE + " Search page or Cancel to try again");
		if (search) {
		    document.location = BP_SEARCH_SERVER + "/search/";
			return;
		}
	}
	if (jQuery("#jump_to_concept_id") != null && jQuery("#jump_to_ontology_id") != null) {
		var sValue = jQuery("#jump_to_concept_id").val();
		var ontology_id = jQuery("#jump_to_ontology_id").val();
		document.location = BP_SEARCH_SERVER + "/ontologies/" + ontology_id + "/?p=classes&conceptid=" + encodeURIComponent(sValue);
		return;
	}
}


// Sets a hidden form value that records the concept id when a concept is chosen in the jump to
// This is a workaround because the default autocomplete search method cannot distinguish between two
// concepts that have the same preferred name but different ids.
function jumpToSelect(li) {
	jQuery("#jump_to_concept_id").val(li.extra[0]);
	jQuery("#jump_to_ontology_id").val(li.extra[2]);
    jumpToValue(li);
}


// Formats the Jump To search results
// This is closely related to the data returned from search_controller::json_search.
function formatItem(row) {
    var specials = new RegExp("[.*+?|()\\[\\]{}\\\\]", "g"); // .*+?|()[]{}\
    var keywords = jQuery(searchBoxSelector).val().trim().replace(specials, "\\$&").split(' ').join('|');
    // var keywords = jQuery("#BP_search_box").val().trim().replace(specials, "\\$&").split(' ').join('|');
    var regex = new RegExp('(' + keywords + ')', 'gi');
    var matchType = "";
    if (typeof row[2] !== "undefined" && row[2] !== "") {
        matchType = " <span style='font-size:9px;color:blue;'>(" + row[2] + ")</span>";
    }
    if (row[0].match(regex) == null) {
        var contents = row[6].split("\t");
        var synonym = contents[0] || "";
        synonym = synonym.split(";");
        if (synonym !== "") {
            var matchSynonym = jQuery.grep(synonym, function(e) {
                return e.match(regex) != null;
            });
            row[0] = row[0] + " (synonym: " + matchSynonym.join(" ") + ")";
        }
    }
    // Cleanup obsolete class tag before markup for search keywords.
    if (row[0].indexOf("[obsolete]") != -1) {
        row[0] = row[0].replace("[obsolete]", "");
        obsolete_prefix = "<span class='obsolete_class' title='obsolete class'>";
        obsolete_suffix = "</span>";
    } else {
        obsolete_prefix = "";
        obsolete_suffix = "";
    }
    // Markup the search keywords.
    var row0_markup = row[0].replace(regex, "<b><span style='color:#006600;'>$1</span></b>");
    return obsolete_prefix + row0_markup + matchType + obsolete_suffix;
}


search_box_init = function(searchURL, params) {
    var autocomplete_options = {
        selectFirst: true,
        lineSeparator: "~!~",
        matchSubset: 0,
        minChars: 2,
        maxItemsToShow: 25,
        width: "400px",
        onFindValue: jumpToValue,
        onItemSelect: jumpToSelect,
        footer: "",
        formatItem: formatItem
    };
    // Override defaults with input params
    if (params.extraParams !== undefined) {
        autocomplete_options.extraParams = params.extraParams;
    }
    if (params.footer !== undefined) {
        autocomplete_options.footer = params.footer;
    }
    if (params.formatItem !== undefined) {
        autocomplete_options.formatItem = params.formatItem;
    }
    if (params.onFindValue !== undefined) {
        autocomplete_options.onFindValue = params.onFindValue;
    }
    if (params.onItemSelect !== undefined) {
        autocomplete_options.onItemSelect = params.onItemSelect;
    }
    if (params.width !== undefined) {
        autocomplete_options.width = params.width;
    }

    if (params.searchBoxSelector !== undefined) {
        searchBoxSelector = params.searchBoxSelector;
    }
    jQuery(searchBoxSelector).bioportal_autocomplete(searchURL, autocomplete_options);
}






// function jumpTo_formatItem(row, position, count) {
//     var specials = new RegExp("[.*+?|()\\[\\]{}\\\\]", "g"); // .*+?|()[]{}\
//     var keywords = jQuery("#BP_search_box").val().trim().replace(specials, "\\$&").split(' ').join('|');
//     var regex = new RegExp('(' + keywords + ')', 'gi');
//     var result = "";
//     // Results
//     var result_type = row[2];
//     var result_class = row[0];
//     var result_ont_version = row[3];
//     var result_uri = row[4];
//     // Set class name column width
//     var class_name_width = "350px";
//     if (BP_include_definitions) {
//         class_name_width = "150px";
//     } else if (BP_ontology_id == "") {
//         class_name_width = "300px";
//     }
//     // row[7] is the ontology_id, only included when searching multiple ontologies
//     if (BP_ontology_id !== "") {
//         if (BP_include_definitions) {
//             result += definitionMarkup(result_ont_version, result_uri);
//         }
//         result += "<div class='result_class' style='width: " + class_name_width + ";'>" + result_class.replace(regex, "<b><span class='result_class_highlight'>$1</span></b>") + "</div>";
//         result += "<div class='result_type' style='overflow: hidden; float: none;'>" + result_type + "</div>";
//     } else {
//         // Results
//         var result_ont = row[7];
//         result += "<div class='result_class' style='width: " + class_name_width + ";'>" + result_class.replace(regex, "<b><span class='result_class_highlight'>$1</span></b>") + "</div>"
//         if (BP_include_definitions) {
//             result += definitionMarkup(result_ont_version, result_uri);
//         }
//         result += "<div>" + " <div class='result_type'>" + result_type + "</div><div class='result_ontology' style='overflow: hidden;'>" + truncateText(result_ont, 30) + "</div></div>";
//     }
//     return result;
// }
