// History and navigation management
(function(window,undefined) {
  // Establish Variables
  var History = window.History;
  // History.debug.enable = true;

  // Abort it not right page
  var path = currentPathArray();
  if (path[0] !== "ontologies" || (path[0] === "ontologies" && path.length !== 2)) {
    return;
  }

  // Bind to State Change
  History.Adapter.bind(window, 'statechange', function() {
    var hashParams = null;
    var queryStringParams = null;
    var params = {};
    var state = History.getState();

    jQuery(document).trigger("ont_view_change");

    if (typeof state.data.p !== 'undefined') {
      if (state.data.p == "classes") {
        displayTree(state.data);
      }

      showOntologyContent(state.data.p);
    } else if (typeof state.url !== 'undefined') {
      if (window.location.hash != "") {
        hashParams = window.location.hash.split('?').pop().split('&');

        jQuery(hashParams).each(function(index, value){
          var paramName = value.split("=")[0];
          var paramValue = value.split("=")[1];
          params[paramName] = paramValue;
        });
      } else {
        queryStringParams = window.location.search.substring(1).split("&");

        jQuery(queryStringParams).each(function(index, value){
          var paramName = value.split("=")[0];
          var paramValue = value.split("=")[1];
          params[paramName] = paramValue;
        });
      }

      if (typeof params["p"] !== 'undefined' && content_section != params["p"]) {
        showOntologyContent(params["p"]);
        document.title = jQuery.bioportal.ont_pages[params["p"]].page_name + " | " + jQuery(document).data().bp.ont_viewer.org_site;

        // We need to get everything using AJAX
        content_section = null;
      } else {
        showOntologyContent(content_section);
        document.title = jQuery.bioportal.ont_pages[content_section].page_name + " | " + jQuery(document).data().bp.ont_viewer.org_site;
      }
    }
  });
})(window);

// Handles display of the tree depending on parameters
function displayTree(data) {
  jQuery(document).trigger("classes_tab_visible");

  var new_concept_id = data.conceptid;
  var new_concept_link = getConceptLinkEl(new_concept_id);
  var concept_label;
  var old_html;

  var ontology_id = jQuery(document).data().bp.ont_viewer.ontology_id;
  var ontology_version_id = jQuery(document).data().bp.ont_viewer.ontology_version_id;
  var ontology_name = jQuery(document).data().bp.ont_viewer.ontology_name;
  var org_site = jQuery(document).data().bp.ont_viewer.org_site;
  var concept_id = jQuery(document).data().bp.ont_viewer.concept_id;
  var content_section = jQuery(document).data().bp.ont_viewer.content_section;
  var concept_param = jQuery(document).data().bp.ont_viewer.concept_param;
  var concept_name = jQuery(document).data().bp.ont_viewer.concept_name;
  var metadata_only = jQuery(document).data().bp.ont_viewer.metadata_only;
  var current_purl = jQuery(document).data().bp.ont_viewer.current_purl;
  var purl_prefix = jQuery(document).data().bp.ont_viewer.purl_prefix;
  var concept_name_title = jQuery(document).data().bp.ont_viewer.concept_name_title;

  // Check to see if we're actually loading a new concept or just displaying the one we already loaded previously
  if (typeof new_concept_id === 'undefined' || new_concept_id == concept_id) {

    if (concept_id !== "") {
      History.replaceState({p:"classes", conceptid:concept_id}, jQuery.bioportal.ont_pages["classes"].page_name + " | " + org_site, "?p=classes" + "&conceptid=" + concept_id);
    }
    jQuery.unblockUI();
    return;

  } else {

    var new_concept_param = (typeof new_concept_id === 'undefined') ? "" : "&conceptid=" + new_concept_id;

    if (typeof new_concept_id !== 'undefined') {
      // Get label for new title
      concept_label = (new_concept_link.html() == null) ? "" : " - " + new_concept_link.html().trim().replace(/<(?:.|\n)*?>/gm, '');

      // Retrieve new concept and display tree
      old_html = jQuery.bioportal.ont_pages["classes"].html;
      jQuery.bioportal.ont_pages["classes"] = new jQuery.bioportal.OntologyPage("classes",
        "/ontologies/" + ontology_id + "?p=classes" + new_concept_param,
        "Problem retrieving classes",
        ontology_name + concept_label + " - Classes",
        "Classes");

      if (typeof data.suid !== 'undefined' && data.suid === "jump_to") {
        jQuery.blockUI({ message: '<h1><img src="/images/tree/spinner.gif" /> Loading Class...</h1>', showOverlay: false });

        if (data.flat === true) {
          // We have a flat ontology, so we'll replace existing information in the UI and add the new class to the list

          // Remove fake root node if it exists
          if (jQuery("li#bp_fake_root").length) {
            jQuery("li#bp_fake_root").remove();
            jQuery("#non_fake_tabs").show();
            jQuery("#fake_tabs").hide();
          }

          // If the concept is already visible and in cache, then just switch to it
          if (getCache(data.conceptid) == null) {
            var list = jQuery("div#sd_content ul.simpleTree li.root ul");

            // Remove existing classes
            list.children().remove();

            // Add new class
            jQuery(list).append('<li id="'+data.conceptid+'"><a href="/ontologies/'+ontology_id+'/?p=classes&conceptid='+data.conceptid+'">'+data.label+'</a></li>');

            // Configure tree
            jQuery(list).children(".line").remove();
            jQuery(list).children(".line-last").remove();
            simpleTreeCollection.get(0).setTreeNodes(list);

            // Simulate node click
            nodeClicked(data.conceptid);

            // Make "clicked" node active
            jQuery("a.active").removeClass("active");
            getConceptLinkEl(new_concept_id).children("a").addClass("active");

            // Clear the search box
            jQuery("#search_box").val("");
          } else {
            nodeClicked(data.conceptid);

            // Clear the search box
            jQuery("#search_box").val("");
          }
        } else {
          // Are we jumping into the ontology? If so, get the whole tree
          jQuery.bioportal.ont_pages["classes"].retrieve_and_publish();
          getConceptLinkEl(new_concept_id)
        }
      } else {
        jQuery.blockUI({ message: '<h1><img src="/images/tree/spinner.gif" /> Loading Class...</h1>', showOverlay: false });
        if (document.getElementById(new_concept_id) !== null) {
          // We have a visible node that's been clicked, get the details for that node
          jQuery.bioportal.ont_pages["classes"].manualRetrieve(old_html);
          jQuery.bioportal.ont_pages["classes"].published = true;
          nodeClicked(new_concept_id);
        } else {
          // Get a new copy of the tree because our concept isn't visible
          // This could be due to using the forward/back button
          jQuery.bioportal.ont_pages["classes"].retrieve_and_publish();
        }
      }

      concept_label = (getConceptLinkEl(new_concept_id).html() == null) ? "" : " - " + getConceptLinkEl(new_concept_id).html().trim().replace(/<(?:.|\n)*?>/gm, '');
      jQuery.bioportal.ont_pages["classes"].page_name =  ontology_name + concept_label + " - Classes"
      document.title = jQuery.bioportal.ont_pages["classes"].page_name + " | " + org_site;
    } else {
      // Retrieve new concept and display tree
      concept_label = (getConceptLinkEl(new_concept_id).html() == null) ? "" : " - " + getConceptLinkEl(new_concept_id).html().trim().replace(/<(?:.|\n)*?>/gm, '');
      jQuery.bioportal.ont_pages["classes"] = new jQuery.bioportal.OntologyPage("classes", "/ontologies/" + ontology_id + "?p=classes", "Problem retrieving classes", ontology_name + concept_label + " - Classes", "Classes");
      jQuery.bioportal.ont_pages["classes"].retrieve_and_publish();
    }

    if (typeof new_concept_id !== 'undefined') {
      concept_id = new_concept_id;
    }
  }
}

function getConceptLinkEl(concept_id) {
  // Escape special chars so jQuery selector doesn't break, see:
  // http://docs.jquery.com/Frequently_Asked_Questions#How_do_I_select_an_element_by_an_ID_that_has_characters_used_in_CSS_notation.3F
  var el_new_concept_link = document.getElementById(concept_id);
  return jQuery(el_new_concept_link);
}

function showOntologyContent(content_section) {
  jQuery.bioportal.ont_pages[content_section].publish();
  jQuery(".ontology_viewer_content").addClass("hidden");
  jQuery("#ont_" + content_section + "_content").removeClass("hidden");
}

// Prevent the default behavior of clicking the ontology page links
// Instead, fire some history events
var nav_ont = function(link) {
  var page = jQuery(link).attr("data-bp_ont_page");
  History.pushState({p:page}, jQuery.bioportal.ont_pages[page].page_name + " | " + jQuery(document).data().bp.ont_viewer.org_site, "?p=" + page);
}


jQuery(document).ready(function() {
  var path = currentPathArray();
  if (path[0] !== "ontologies" || (path[0] === "ontologies" && path.length !== 2)) {
    return;
  }

  // Set appropriate title
  var content_section = jQuery(document).data().bp.ont_viewer.content_section || "";
  var ontology_name = jQuery(document).data().bp.ont_viewer.ontology_name;
  var org_site = jQuery(document).data().bp.ont_viewer.org_site;
  var metadata_only = jQuery(document).data().bp.ont_viewer.metadata_only;
  var content_section_obj = jQuery.bioportal.ont_pages[content_section] || {};
  var title = (content_section == null) ? ontology_name + " | " + org_site
    : content_section_obj.page_name + " | " + org_site;
  document.title = title;

  // Naviation buttons
  jQuery(".nav_link a").live("click", function(e){
    e.preventDefault();
    nav_ont(this);
  });

  // Set up the JS version of the active content section
  jQuery.bioportal.ont_pages[content_section].manuelRetrieve(jQuery("#ont_" + content_section + "_content").html());
  jQuery.bioportal.ont_pages[content_section].published = true;
  if (typeof jQuery.bioportal.ont_pages[content_section].init === 'function') {
    jQuery.bioportal.ont_pages[content_section].init(jQuery.bioportal.ont_pages[content_section]);
  }

  // Retrieve AJAX content if not already displayed
  if ($.QueryString["skip_ajax_tabs"] != 'true') {
    if (content_section !== "classes" && metadata_only != true) {
      jQuery.bioportal.ont_pages["classes"].retrieve();
    }

    if (content_section !== "properties" && metadata_only !== true) {
      jQuery.bioportal.ont_pages["properties"].retrieve();
    }

    if (content_section !== "summary") {
      jQuery.bioportal.ont_pages["summary"].retrieve();
    }

    if (content_section !== "mappings") {
      jQuery.bioportal.ont_pages["mappings"].retrieve();
    }

    if (content_section !== "notes") {
      jQuery.bioportal.ont_pages["notes"].retrieve();
    }

    if (content_section !== "widgets" && metadata_only !== true) {
      jQuery.bioportal.ont_pages["widgets"].retrieve();
    }
  }
});

// Parent class to ontology pages
// We're using a monkeypatched function to setup prototyping, see bioportal.js
jQuery.bioportal.OntologyPage = function(id, location_path, error_string, page_name, nav_text, init) {
  this.id = id;
  this.location_path = location_path;
  this.error_string = error_string;
  this.page_name = page_name;
  this.error_string = error_string;
  this.nav_text = nav_text;
  this.errored = false;
  this.html;
  this.published = false;
  this.retrieved = false;
  this.init = init || null;

  this.retrieve = function(){
    jQuery.ajax({
      dataType: "html",
      url: this.location_path,
      context: this,
      success: function(data){
        this.html = data;
        this.retrieved = true;
      },
      error: function(){
        this.errored = true;
        this.retrieved = true;
      }
    });
  };

  this.manuelRetrieve = function(html) {
    this.html = html;
    this.retrieved = true;
  }

  this.retrieve_and_publish = function(){
    jQuery.ajax({
      dataType: "html",
      url: this.location_path,
      context: this,
      success: function(data){
        this.manuelRetrieve(data);
        this.publish();
      },
      error: function(){
        this.errored = true;
        this.manuelRetrieve(null);
        this.publish();
      }
    });
  };

  this.publishAction = function() {
    jQuery("#ont_" + this.id + "_content").html("");
    jQuery("#ont_" + this.id + "_content").html(this.html);
    document.title = jQuery.bioportal.ont_pages["classes"].page_name + " | " + jQuery(document).data().bp.ont_viewer.org_site;
    if (typeof this.init === 'function') {
      this.init(this);
    }
    jQuery.unblockUI();
    this.published = true;
  }

  this.publish = function(){
    if (this.errored === false) {
      if (this.published) { return; }
      if (this.retrieved) {
        this.publishAction();
      } else {
        var _this = this;
        var publishRetry = setInterval(function() {
          console.log("retrying!!! " + _this.retrieved)
          if (_this.retrieved) {
            console.log("publishing!!!")
            _this.publishAction();
            clearInterval(publishRetry);
          }
        }, 100);
      }
    } else {
      jQuery("#ont_" + this.id + "_content").html("");
      jQuery("#ont_" + this.id + "_content").html("<div style='padding: 1em;'>" + this.error_string + "</div>");
      jQuery.unblockUI();
    }
  };
};

(function(window,undefined) {
  // Setup AJAX page objects
  jQuery.bioportal.ont_pages = [];

  jQuery.bioportal.ont_pages["classes"] = new jQuery.bioportal.OntologyPage("classes", "/ontologies/" + jQuery(document).data().bp.ont_viewer.ontology_id + "?p=classes&ajax=true" + jQuery(document).data().bp.ont_viewer.concept_param, "Problem retrieving classes", jQuery(document).data().bp.ont_viewer.ontology_name + jQuery(document).data().bp.ont_viewer.concept_name_title + " - Classes", "Classes", function() {
    jQuery(document).data().bp.classesTab.classes_init();
    jQuery(document).data().bp.classesTab.search_box_init();
    setupNotesFacebox();
  });

  jQuery.bioportal.ont_pages["properties"] = new jQuery.bioportal.OntologyPage("properties", "/ontologies/" + jQuery(document).data().bp.ont_viewer.ontology_id + "?p=properties&ajax=true", "Problem retrieving properties", jQuery(document).data().bp.ont_viewer.ontology_name + " - Properties", "Properties", function() {
    jQuery(document).data().bp.ontPropertiesTab.init();
  });

  jQuery.bioportal.ont_pages["summary"] = new jQuery.bioportal.OntologyPage("summary", "/ontologies/" + jQuery(document).data().bp.ont_viewer.ontology_id + "?p=summary&ajax=true", "Problem retrieving summary", jQuery(document).data().bp.ont_viewer.ontology_name + " - Summary", "Summary", function() {
    try {
      jQuery(document).data().bp.ontChart.init();
    } catch (err) {
      console.log("No ontology visits data to display");
    }
  });

  jQuery.bioportal.ont_pages["mappings"] = new jQuery.bioportal.OntologyPage("mappings", "/ontologies/" + jQuery(document).data().bp.ont_viewer.ontology_id + "?p=mappings&ajax=true", "Problem retrieving mappings", jQuery(document).data().bp.ont_viewer.ontology_name + " - Mappings", "Mappings", function() {
    jQuery(".facebox").facebox();
  });

  jQuery.bioportal.ont_pages["notes"] = new jQuery.bioportal.OntologyPage("notes", "/ontologies/" + jQuery(document).data().bp.ont_viewer.ontology_id + "?p=notes&ajax=true", "Problem retrieving notes", jQuery(document).data().bp.ont_viewer.ontology_name + " - Notes", "Notes", function() {
    setupNotesFacebox();
    jQuery("#ont_notes_content .link_button").button();
  });

  jQuery.bioportal.ont_pages["widgets"] = new jQuery.bioportal.OntologyPage("widgets", "/ontologies/" + jQuery(document).data().bp.ont_viewer.ontology_id + "?p=widgets&ajax=true", "Problem retrieving widgets", jQuery(document).data().bp.ont_viewer.ontology_name + " - Widgets", "Widgets");
})(window);