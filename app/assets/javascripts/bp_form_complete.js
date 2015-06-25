// Widget-specific code

// Set a variable to check to see if this script is loaded
var BP_INTERNAL_FORM_COMPLETE_LOADED = true;

// Set the defaults if they haven't been set yet
if (typeof BP_INTERNAL_SEARCH_SERVER === 'undefined') {
  var BP_INTERNAL_SEARCH_SERVER = "http://bioportal.bioontology.org";
}
if (typeof BP_INTERNAL_SITE === 'undefined') {
  var BP_INTERNAL_SITE = "BioPortal";
}
if (typeof BP_INTERNAL_ORG === 'undefined') {
  var BP_INTERNAL_ORG = "NCBO";
}
if (typeof BP_INTERNAL_ONTOLOGIES === 'undefined') {
  var BP_INTERNAL_ONTOLOGIES = "";
}

var BP_INTERNAL_ORG_SITE = (BP_INTERNAL_ORG == "") ? BP_INTERNAL_SITE : BP_INTERNAL_ORG + " " + BP_INTERNAL_SITE;

function determineHTTPS(url) {
  return url.replace("http:", ('https:' == document.location.protocol ? 'https:' : 'http:'));
}

BP_INTERNAL_SEARCH_SERVER = determineHTTPS(BP_INTERNAL_SEARCH_SERVER);

jQuery(document).ready(function(){
  // Install any CSS we need (check to make sure it hasn't been loaded)
  if (jQuery('link[href$="' + BP_INTERNAL_SEARCH_SERVER + '/javascripts/JqueryPlugins/autocomplete/jquery.autocomplete.css"]')) {
    jQuery("head").append("<link>");
    css = jQuery("head").children(":last");
    css.attr({
      rel:  "stylesheet",
      type: "text/css",
      href: BP_INTERNAL_SEARCH_SERVER + "/javascripts/JqueryPlugins/autocomplete/jquery.autocomplete.css"
    });
  }

  // Grab the specific scripts we need and fires the start event
  jQuery.getScript(BP_INTERNAL_SEARCH_SERVER + "/javascripts/bp_crossdomain_autocomplete.js",function(){
    bp_internal_formComplete_setup_functions();
  });
});

function bp_internal_formComplete_formatItem(row) {
  var input = this.extraParams.input;
  var specials = new RegExp("[.*+?|()\\[\\]{}\\\\]", "g"); // .*+?|()[]{}\
  var keywords = jQuery(input).val().replace(specials, "\\$&").split(' ').join('|');
  var regex = new RegExp( '(' + keywords + ')', 'gi' );
  var result = "";
  var ontology_id;
  var class_name_width = "350px";

  // Get ontology id and other parameters
  var classes = jQuery(input).attr('class').split(" ");
  jQuery(classes).each(function() {
    if (this.indexOf("bp_internal_form_complete") === 0) {
      var values = this.split("-");
      ontology_id = values[1];
    }
  });
  var BP_include_definitions = jQuery(input).attr("data-bp_include_definitions");

  // Set wider class name column
  if (BP_include_definitions === "true") {
    class_name_width = "150px";
  } else if (ontology_id == "all") {
    class_name_width = "320px";
  }

  // Results
  var result_type = row[2];
  var result_class = row[0];

  // row[7] is the ontology_id, only included when searching multiple ontologies
  if (ontology_id !== "all") {
    var result_def = row[7];

    if (BP_include_definitions === "true") {
      result += "<div class='result_definition'>" + truncateText(decodeURIComponent(result_def.replace(/\+/g, " ")), 75) + "</div>"
    }

    result += "<div class='result_class' style='width: "+class_name_width+";'>" + result_class.replace(regex, "<b><span class='result_class_highlight'>$1</span></b>") + "</div>";

    result += "<div class='result_type' style='overflow: hidden;'>" + result_type + "</div>";
  } else {
    // Results
    var result_ont = row[7];
    var result_def = row[9];

    result += "<div class='result_class' style='width: "+class_name_width+";'>" + result_class.replace(regex, "<b><span class='result_class_highlight'>$1</span></b>") + "</div>"

    if (BP_include_definitions === "true") {
      result += "<div class='result_definition'>" + truncateText(decodeURIComponent(result_def.replace(/\+/g, " ")), 75) + "</div>"
    }

    result += "<div>" + " <div class='result_type'>" + result_type + "</div><div class='result_ontology' style='overflow: hidden;'>" + truncateText(result_ont, 35) + "</div></div>";
  }

  return result;
}

function bp_internal_formComplete_setup_functions() {
  jQuery("input[class*='bp_internal_form_complete']").each(function(){
    var classes = this.className.split(" ");
    var values;
    var ontology_id;
    var target_property;

    var BP_search_branch = jQuery(this).attr("data-bp_search_branch");
    if (typeof BP_search_branch === "undefined") {
      BP_search_branch = "";
    }

    var BP_include_definitions = jQuery(this).attr("data-bp_include_definitions");
    if (typeof BP_include_definitions === "undefined") {
      BP_include_definitions = "";
    }

    var BP_objecttypes = jQuery(this).attr("data-bp_objecttypes");
    if (typeof BP_objecttypes === "undefined") {
      BP_objecttypes = "";
    }

    jQuery(classes).each(function() {
      if (this.indexOf("bp_internal_form_complete") === 0) {
        values = this.split("-");
        ontology_id = values[1];
        target_property = values[2];
      }
    });

    if (ontology_id == "all") { ontology_id = ""; }

    var extra_params = {
    		input: this,
    		target_property: target_property,
    		subtreerootconceptid: encodeURIComponent(BP_search_branch),
    		includedefinitions: BP_include_definitions,
    		objecttypes: BP_objecttypes,
    		id: BP_INTERNAL_ONTOLOGIES
    };

    var result_width = 450;

    // Add extra space for definition
    if (BP_include_definitions) {
      result_width += 275;
    }

    // Add space for ontology name
    if (ontology_id === "") {
      result_width += 200;
    }

    // Add ontology id to params
    extra_params["id"] = ontology_id;

    jQuery(this).bp_autocomplete(BP_INTERNAL_SEARCH_SERVER + "/search/json_search/", {
        extraParams: extra_params,
        lineSeparator: "~!~",
        matchSubset: 0,
        mustMatch: true,
        sortRestuls: false,
        minChars: 3,
        maxItemsToShow: 20,
        cacheLength: -1,
        width: result_width,
        onItemSelect: bpFormSelect,
        formatItem: bp_internal_formComplete_formatItem
    });

    var html = "";
    if (document.getElementById(jQuery(this).attr('name') + "_bioportal_concept_id") == null)
      html += "<input type='hidden' id='" + jQuery(this).attr('name') + "_bioportal_concept_id'>";
    if (document.getElementById(jQuery(this).attr('name') + "_bioportal_ontology_id") == null)
      html += "<input type='hidden' id='" + jQuery(this).attr('name') + "_bioportal_ontology_id'>";
    if (document.getElementById(jQuery(this).attr('name') + "_bioportal_full_id") == null)
      html += "<input type='hidden' id='" + jQuery(this).attr('name') + "_bioportal_full_id'>";
    if (document.getElementById(jQuery(this).attr('name') + "_bioportal_preferred_name") == null)
      html += "<input type='hidden' id='" + jQuery(this).attr('name') + "_bioportal_preferred_name'>";

    jQuery(this).after(html);
  });
}

// Sets a hidden form value that records the concept id when a concept is chosen in the jump to
// This is a workaround because the default autocomplete search method cannot distinguish between two
// concepts that have the same preferred name but different ids.
function bpFormSelect(li) {
  var input = this.extraParams.input;
  switch (this.extraParams.target_property) {
    case "uri":
      jQuery(input).val(li.extra[3])
      break;
    case "shortid":
      jQuery(input).val(li.extra[0])
      break;
    case "name":
      jQuery(input).val(li.extra[4])
      break;
  }

  jQuery("#" + jQuery(input).attr('name') + "_bioportal_concept_id").val(li.extra[0]);
  jQuery("#" + jQuery(input).attr('name') + "_bioportal_ontology_id").val(li.extra[2]);
  jQuery("#" + jQuery(input).attr('name') + "_bioportal_full_id").val(li.extra[3]);
  jQuery("#" + jQuery(input).attr('name') + "_bioportal_preferred_name").val(li.extra[4]);
}

function truncateText(text, max_length) {
  if (typeof max_length === 'undefined' || max_length == "") {
    max_length = 70;
  }

  var more = '...';

  var content_length = $.trim(text).length;
  if (content_length <= max_length)
    return text;  // bail early if not overlong

  var actual_max_length = max_length - more.length;
  var truncated_node = jQuery("<div>");
  var full_node = jQuery("<div>").html(text).hide();

  text = text.replace(/^ /, '');  // node had trailing whitespace.

  var text_short = text.slice(0, max_length);

  // Ensure HTML entities are encoded
  // http://debuggable.com/posts/encode-html-entities-with-jquery:480f4dd6-13cc-4ce9-8071-4710cbdd56cb
  text_short = $('<div/>').text(text_short).html();

  var other_text = text.slice(max_length, text.length);

  text_short += "<span class='expand_icon'><b>"+more+"</b></span>";
  text_short += "<span class='long_text'>" + other_text + "</span>";
  return text_short;
}


