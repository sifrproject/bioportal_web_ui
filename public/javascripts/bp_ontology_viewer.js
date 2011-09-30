// History and navigation management
(function(window,undefined) {
  // Establish Variables
  var History = window.History;
  // History.debug.enable = true;
  
  // Bind to State Change
  History.Adapter.bind(window, 'statechange', function() {
    var hashParams = null;
    var queryStringParams = null;
    var params = {};
    var state = History.getState();
    
    if (typeof state.data.p !== 'undefined') {
      if (state.data.p == "terms") {
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
        document.title = jQuery.bioportal.ont_pages[params["p"]].page_name + " | " + org_site;
        
        // We need to get everything using AJAX
        content_section = null;
      } else {
        showOntologyContent(content_section);
        document.title = jQuery.bioportal.ont_pages[content_section].page_name + " | " + org_site;
      }
    }
  });
})(window);

// Handles display of the tree depending on parameters
function displayTree(data) {
  var new_concept_id = data.conceptid;

  var new_concept_link = getConceptLinkEl(new_concept_id);

  var concept_label;
  
  // Check to see if we're actually loading a new concept or just displaying the one we already loaded previously
  if (typeof new_concept_id === 'undefined' || new_concept_id == concept_id) {
    if (concept_id !== "") {
      History.replaceState({p:"terms", conceptid:concept_id}, jQuery.bioportal.ont_pages["terms"].page_name + " | " + org_site, "?p=terms" + "&conceptid=" + concept_id);
    }
    
    jQuery.unblockUI();
    
    return;
  } else {
    var new_concept_param = (typeof new_concept_id === 'undefined') ? "" : "&conceptid=" + new_concept_id;

    if (typeof new_concept_id !== 'undefined') {
      // Get label for new title
      concept_label = (new_concept_link.html() == null) ? "" : " - " + new_concept_link.html().trim();

      // Retrieve new concept and display tree
      jQuery.bioportal.ont_pages["terms"] = new jQuery.bioportal.OntologyPage("terms", "/ontologies/" + ontology_id + "?p=terms" + new_concept_param, "Problem retrieving terms", ontology_name + concept_label + " - Terms", "Terms");
      
      if (typeof data.suid !== 'undefined' && data.suid === "jump_to") {
        jQuery.blockUI({ message: '<h1><img src="/images/tree/spinner.gif" /> Loading Term...</h1>', showOverlay: false }); 
        
        if (data.flat === true) {
          // We have a flat ontology, so we'll replace existing information in the UI and add the new term to the list
          
          // Remove fake root node if it exists
          if (jQuery("li#bp_fake_root").length) {
            jQuery("li#bp_fake_root").remove();
            jQuery("#non_fake_tabs").show();
            jQuery("#fake_tabs").hide();
          }
          
          // If the concept is already visible and in cache, then just switch to it
          if (getCache(data.conceptid) == null) {
            var list = jQuery("div#sd_content ul.simpleTree li.root ul");
            jQuery(list).append('<li id="'+data.conceptid+'"><a href="/ontologies/'+ontology_id+'/?p=terms&conceptid='+data.conceptid+'">'+data.label+'</a></li>');
            
            // Configure tree
            jQuery(list).children(".line").remove();
            jQuery(list).children(".line-last").remove();
            simpleTreeCollection.get(0).setTreeNodes(list);
            
            // Simulate node click
            nodeClicked(data.conceptid);
            
            // Make "clicked" node active
            jQuery("a.active").removeClass("active");
            getConceptLinkEl(new_concept_id).addClass("active");
            
            // Clear the search box
            jQuery("#search_box").val("");
          } else {
            nodeClicked(data.conceptid);
            
            // Clear the search box
            jQuery("#search_box").val("");
          }
        } else {
          // Are we jumping into the ontology? If so, get the whole tree
          jQuery.bioportal.ont_pages["terms"].retrieve_and_publish();
          getConceptLinkEl(new_concept_id)
        }
      } else {
        jQuery.blockUI({ message: '<h1><img src="/images/tree/spinner.gif" /> Loading Term...</h1>', showOverlay: false }); 
        if (document.getElementById(new_concept_id) !== null) {
          // We have a visible node that's been clicked, get the details for that node
          nodeClicked(new_concept_id);
        } else {
          // Get a new copy of the tree because our concept isn't visible
          // This could be due to using the forward/back button
          jQuery.bioportal.ont_pages["terms"].retrieve_and_publish();
        }
      }

      concept_label = (getConceptLinkEl(new_concept_id).html() == null) ? "" : " - " + getConceptLinkEl(new_concept_id).html().trim();
      jQuery.bioportal.ont_pages["terms"].page_name =  ontology_name + concept_label + " - Terms"
      document.title = jQuery.bioportal.ont_pages["terms"].page_name + " | " + org_site;
    } else {
      // Retrieve new concept and display tree
      concept_label = (getConceptLinkEl(new_concept_id).html() == null) ? "" : " - " + getConceptLinkEl(new_concept_id).html().trim();
      jQuery.bioportal.ont_pages["terms"] = new jQuery.bioportal.OntologyPage("terms", "/ontologies/" + ontology_id + "?p=terms", "Problem retrieving terms", ontology_name + concept_label + " - Terms", "Terms");
      jQuery.bioportal.ont_pages["terms"].retrieve_and_publish();
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
  jQuery(".ontology_viewer_content").addClass("hidden");
  jQuery("#ont_" + content_section + "_content").removeClass("hidden");
  jQuery("#nav_text").html(jQuery.bioportal.ont_pages[content_section].nav_text);
}

// Prevent the default behavior of clicking the ontology page links
// Instead, fire some history events
var nav_ont = function(link) {
  var page = jQuery(link).attr("data-bp_ont_page");
  History.pushState({p:page}, jQuery.bioportal.ont_pages[page].page_name + " | " + org_site, "?p=" + page);
}


jQuery(document).ready(function() {
  // Set appropriate title
  var title = (content_section == null) ? ontology_name + " | " + org_site
    : jQuery.bioportal.ont_pages[content_section].page_name + " | " + org_site;
  document.title = title;
  
  // Wire up navigation buttons
  jQuery('#ont_nav').fgmenu({ 
    content: jQuery('#ont_nav').next().html(),
    afterItemChosen: nav_ont
  });
  jQuery('#ont_admin').fgmenu({ 
    content: jQuery('#ont_admin').next().html(),
    afterItemChosen: menu_nav
  });
  
  // Retrieve AJAX content if not already displayed
  if (content_section !== "terms" && metadata_only != true) {
    jQuery.bioportal.ont_pages["terms"].retrieve_and_publish();
    
    // if (typeof concept_id !== 'undefined') {
    //   jQuery.cache.terms[concept_id] = jQuery.bioportal.ont_pages["terms"].html; 
    // } else {
    //   jQuery.cache.terms["root"] = jQuery.bioportal.ont_pages["terms"].html;
    // }
  }
    
  if (content_section !== "summary") {
    jQuery.bioportal.ont_pages["summary"].retrieve_and_publish();
  }

  if (content_section !== "mappings") {
    jQuery.bioportal.ont_pages["mappings"].retrieve_and_publish();
  }

  if (content_section !== "notes") {
    jQuery.bioportal.ont_pages["notes"].retrieve_and_publish();
  }
  
  if (content_section !== "widgets" && metadata_only != true) {
    jQuery.bioportal.ont_pages["widgets"].retrieve_and_publish();
  }
  
  // Set the proper name in the nav menu
  if (content_section !== null) {
    jQuery("#nav_text").html(jQuery.bioportal.ont_pages[content_section].nav_text);
  }
});

// Parent class to ontology pages
// We're using a monkeypatched function to setup prototypging, see bioportal.js
jQuery.bioportal.OntologyPage = function(id, location_path, error_string, page_name, nav_text, init){
  this.id = id;
  this.location_path = location_path;
  this.error_string = error_string;
  this.page_name = page_name;
  this.error_string = error_string;
  this.nav_text = nav_text;
  this.errored = false;
  this.html;
  
  this.retrieve = function(){
    jQuery.ajax({
      dataType: "html",
      url: this.location_path,
      context: this,
      success: function(data){
        this.html = data;
      },
      error: function(){
        this.errored = true;
      }
    });
  };
  
  this.retrieve_and_publish = function(){
    jQuery.ajax({
      dataType: "html",
      url: this.location_path,
      context: this,
      success: function(data){
        this.html = data;
        jQuery("#ont_" + this.id + "_content").html("");
        jQuery("#ont_" + this.id + "_content").html(this.html);
        var concept_label = (getConceptLinkEl(concept_id).html() == null) ? "" : " - " + getConceptLinkEl(concept_id).html().trim();
        jQuery.bioportal.ont_pages["terms"].page_name =  ontology_name + concept_label + " - Terms"
        document.title = jQuery.bioportal.ont_pages["terms"].page_name + " | " + org_site;
        jQuery.unblockUI();
      },
      error: function(){
        this.errored = true;
        jQuery("#ont_" + this.id + "_content").html("");
        jQuery("#ont_" + this.id + "_content").html("<div style='padding: 1em;'>" + this.error_string + "</div>");
        jQuery.unblockUI();
      }
    });
  };

  this.publish = function(){
    if (this.errored === false) {
      jQuery("#ont_" + this.id + "_content").html(this.html);
      var concept_label = (getConceptLinkEl(concept_id).html() == null) ? "" : " - " + getConceptLinkEl(concept_id).html().trim();
      jQuery.bioportal.ont_pages["terms"].page_name =  ontology_name + concept_label + " - Terms"
      document.title = jQuery.bioportal.ont_pages["terms"].page_name + " | " + org_site;
      jQuery.unblockUI(); 
    } else {
      jQuery("#ont_" + this.id + "_content").html("<div style='padding: 1em;'>" + this.error_string + "</div>");
      jQuery.unblockUI(); 
    }
  };
}

// Setup AJAX page objects
jQuery.bioportal.ont_pages = [];

jQuery.bioportal.ont_pages["terms"] = new jQuery.bioportal.OntologyPage("terms", "/ontologies/" + ontology_id + "?p=terms&ajax=true" + concept_param, "Problem retrieving terms", ontology_name + concept_name_title + " - Terms", "Terms");
jQuery.bioportal.ont_pages["summary"] = new jQuery.bioportal.OntologyPage("summary", "/ontologies/" + ontology_id + "?p=summary&ajax=true", "Problem retrieving summary", ontology_name + " - Summary", "Summary");
jQuery.bioportal.ont_pages["mappings"] = new jQuery.bioportal.OntologyPage("mappings", "/ontologies/" + ontology_id + "?p=mappings&ajax=true", "Problem retrieving mappings", ontology_name + " - Mappings", "Mappings");
jQuery.bioportal.ont_pages["notes"] = new jQuery.bioportal.OntologyPage("notes", "/ontologies/" + ontology_id + "?p=notes&ajax=true", "Problem retrieving notes", ontology_name + " - Notes", "Notes");
jQuery.bioportal.ont_pages["widgets"] = new jQuery.bioportal.OntologyPage("widgets", "/ontologies/" + ontology_id + "?p=widgets&ajax=true", "Problem retrieving widgets", ontology_name + " - Widgets", "Widgets");
