// BioPortal jQuery Namespace
jQuery.bioportal = {};

// Backport function name
jQuery.curCSS = jQuery.css;

// CSRF protection support
$(document).ajaxSend(function(e, xhr, options) {
  var token = $("meta[name='csrf-token']").attr('content');
  xhr.setRequestHeader('X-CSRF-Token', token);
});

// Cache Implementation
var cache = new Object();
var que= new Array();
var queIndex = 0;
var thread=0;
var currentOntology;
var currentConcept;

    function setOntology(ontology){
        currentOntology = ontology;
    }
    function setConcept(concept){
        currentConcept = concept;
    }

    function getOntology(){
        return currentOntology;
    }
    function getConcept(){
        return currentConcept;
    }

// Invalidate and Refetch
  function refreshCache(nodeID){
    cache[nodeID]=null
    queData([nodeID],currentOntology)
  }


// Cache Getter
  function getCache(nodeID){
    if(cache[nodeID]!=null){
      return cache[nodeID]
    }else{
      return null;
    }
  }
// Cache Setter
  function setCache(nodeID,content){
    cache[nodeID]=content
  }

// Starts the prefetching
  function queData(nodes,ontology){
    currentOntology = ontology
    // Disables Cache
    return false;

    que = nodes.concat(que)
    // set how many threads you want fetching data
    queIndex = 0
    thread++
    preFetchData(que[queIndex],ontology,thread);
    //preFetchData(que[1],ontology)

  }

// The prefetching function
  function preFetchData(node_id,ontology,threadNumber) {


      var responseSuccess = function(o)
      {
        var respTxt = o.responseText;
        tabData = respTxt.split("|||")
        setCache(node_id,tabData)
        queIndex++

        // makes sure the que isnt complete and makes sure that this thread shouldnt die

        if(queIndex < que.length && thread == threadNumber){
        preFetchData(que[queIndex],ontology,threadNumber)
        }else if(queIndex >= que.length){
          que = new Array();
        }

      }

      var responseFailure = function(o){

      }

      var callback =
      {
        success:responseSuccess,
        failure:responseFailure
      };


    // see's if item is already in cache, if not it makes the ajax call
    if(getCache(node_id)==null){
      YAHOO.util.Connect.asyncRequest('GET','/'+ontology+'/'+node_id+"?callback=load",callback);
    }else{
      queIndex++
      if(queIndex < que.length && thread == threadNumber){
        preFetchData(que[queIndex],ontology,threadNumber)
        }else if(queIndex >= que.length){
          que = new Array();
        }
    }

    }




//-------------------------------


function toggleHide(id,name_to_hide){
  toggle = true;
  element = document.getElementById(id);
  if(element.style.display==""){
    toggle = false;
  }

  if(name_to_hide !=null && name_to_hide != ""){
    elements = document.getElementsByName(name_to_hide);
    for( var x = 0; x<elements.length; x++){
      elements[x].style.display="none";
    }
  }

  if(toggle){
    if (element.style.display=="none"){
      element.style.display="";
    }
  }else{
      element.style.display="none";
    }

}


//helper function for demo only
function newProposal(string){
  document.getElementById('subject').value="Proposal For Change";
  document.getElementById('comment').value=string;

  selectBox = document.getElementById('margin_note_note_type');
  for(var x =0; x<selectBox.options.length;x++){
    option = selectBox.options[x]
    if(option.value!=5){
      option.disabled=true;
    }
    if(option.value==5){
      option.selected=true;
    }
  }
}

  function newNote(){
    toggleHide("commentForm","forms")
  }




  function compare(note_id){
    oldValue = document.getElementById("oldValue").innerHTML;
    element = document.getElementById("note_value"+note_id)
    target = document.getElementById("note_text"+note_id)
    var d = dmp.diff_main(oldValue, element.value);
      dmp.diff_cleanupSemantic(d);
      target.innerHTML=dmp.diff_prettyHtml(d)
  }

  function hide(id){
    document.getElementById(id).style.display="none";
  }
  function unhide(id){
    document.getElementById(id).style.display="";
  }



function buildWait(){
   YAHOO.namespace("wait.container");
  // Initialize the temporary Panel to display while waiting for external content to load
  YAHOO.wait.container.wait = new YAHOO.widget.Panel("wait",
        { width:"240px",
          fixedcenter:true,
          close:false,
          draggable:false,
          zindex:4,
          modal:true,
          visible:false
        }
      );

  YAHOO.wait.container.wait.setHeader("Loading, please wait...");
  YAHOO.wait.container.wait.setBody('<img src="http://us.i1.yimg.com/us.yimg.com/i/us/per/gr/gp/rel_interstitial_loading.gif" />');
  YAHOO.wait.container.wait.render(document.body);



}

function buildTabWait(){
   YAHOO.namespace("tabwait.container");
  // Initialize the temporary Panel to display while waiting for external content to load
  YAHOO.tabwait.container.wait = new YAHOO.widget.Panel("tabwait",
        { width:"240px",
          fixedcenter:true,
          close:false,
          draggable:false,
          zindex:4,
          modal:true,
          visible:false
        }
      );

  YAHOO.tabwait.container.wait.setHeader("Building Tree, please wait...");
  YAHOO.tabwait.container.wait.setBody('<img src="http://us.i1.yimg.com/us.yimg.com/i/us/per/gr/gp/rel_interstitial_loading.gif" />');
  YAHOO.tabwait.container.wait.render(document.body);



}



function buildSearchWait(){
   YAHOO.namespace("wait.container");
  // Initialize the temporary Panel to display while waiting for external content to load
  YAHOO.wait.container.wait = new YAHOO.widget.Panel("wait",
        { width:"240px",
          fixedcenter:true,
          close:false,
          draggable:false,
          zindex:4,
          modal:true,
          visible:false
        }
      );

  YAHOO.wait.container.wait.setHeader("Searching, please wait...");
  YAHOO.wait.container.wait.setBody('<img src="http://us.i1.yimg.com/us.yimg.com/i/us/per/gr/gp/rel_interstitial_loading.gif" />');
  YAHOO.wait.container.wait.render(document.body);



}



// Selects the current clicked node.
function toggleSelected(node){

  var index=1;

  // can get in endless loop if you jump to a node that is free floating.
  nullCount = 0;
  while (nullCount < 20){
    if(tree.getNodeByIndex(index)!=null){
      if (tree.getNodeByIndex(index).labelStyle=='ygtvlabel-selected'){
        tree.getNodeByIndex(index).labelStyle='ygtvlabel'
        break;
      }
    }else{
      nullCount ++;
    }
  index++;
  }
  node.labelStyle="ygtvlabel-selected";

}
var tabs=null;
  function buildTabs(){
      tabs = new YAHOO.widget.TabView('tabframe');

    //YAHOO.namespace("feed");
    //YAHOO.feed.feed = new YAHOO.widget.Panel("feedPanel", { context:["feed","tr","br"], width:"320px", visible:false,draggable:false,constraintoviewport:true  } );
    //YAHOO.feed.feed.render();
    //YAHOO.util.Event.addListener("feed", "click", YAHOO.feed.feed.show, YAHOO.feed.feed, true);

    var split = new Ext.SplitBar("dragSpot", "leftbar",
                     Ext.SplitBar.HORIZONTAL, Ext.SplitBar.LEFT);
      split.setAdapter(new Ext.SplitBar.AbsoluteLayoutAdapter("container"));
      split.minSize = 100;
      split.maxSize = 400;
      split.animate = true;
      split.on('moved', splitterMoved);
  }

  function splitterMoved(splitbar,newSize){
    var rightSide = Ext.get('centerContent');
    var tabFrame = Ext.get('tabframe');
    var leftSide = Ext.get('leftbar');

  }

  function resetNoteForm(uniq){
    document.getElementById("note_subject"+uniq).value=""
    document.getElementById("note_comment"+uniq).value=""
    document.getElementById('noteParent'+uniq).value="";
  }


var myEditor;



function buildEditor(uniq){



  var Dom = YAHOO.util.Dom,
        Event = YAHOO.util.Event;

  myEditor = new YAHOO.widget.SimpleEditor('note_comment'+uniq, {
    height: '300px',
    width: '522px',
    dompath: false //Turns on the bar at the bottom
});
myEditor.render();
}

function saveNote(){
  myEditor.saveHTML();
  myEditor.destroy();

}

function destroyEditor(){
    myEditor.clearEditorDoc();
    myEditor.destroy();

}




function updateOntologyList(ontology){
    list = document.getElementById("ontologieslist")
    if(ontology.checked){
        var s= document.createElement("LI");
        var v= document.createElement("INPUT");
        v.type="hidden"
        v.value=1
        v.name=ontology.name
        v.id="hid_"+ontology.nextSibling.nodeValue;
        s.id="id_"+ontology.nextSibling.nodeValue;
        s.innerHTML= ontology.nextSibling.nodeValue
        list.appendChild(s);
        list.appendChild(v);
        ontology.parentNode.innerHTML = ontology.parentNode.innerHTML.replace(">","checked >")
    }else{
        list.removeChild(document.getElementById("id_"+ontology.nextSibling.nodeValue))
        list.removeChild(document.getElementById("hid_"+ontology.nextSibling.nodeValue))
        ontology.parentNode.innerHTML = ontology.parentNode.innerHTML.replace("checked","")
    }


}

function hover_on_BG(cell){
    if(!cell.firstChild.checked){
        cell.style.background="#DFDFDF";
    }
}

function hover_off_BG(cell){
    if(!cell.firstChild.checked){
        cell.style.background="white";
    }
}

var dialog;

function toggleBG(cell,bgcolor){

    if(cell.firstChild.checked){
        cell.style.backgroundColor=bgcolor;
    }else{
        cell.style.backgroundColor=bgcolor;
    }


}

function updateContent(){
    document.getElementById('ontologies').innerHTML = Dialog.dialog.getContent().innerHTML
}

//------------------------------------- JQuery Rewrite Functions ---------------------------------

function ajaxForm(form, target, callback) {
  // let's start the jQuery while I wait.
  // step 1: onload - capture the submit event on the form.

  // now we're going to capture *all* the fields in the
  // form and submit it via ajax.

  // :input is a macro that grabs all input types, select boxes
  // textarea, etc.  Then I'm using the context of the form from
  // the initial '#contactForm' to narrow down our selector
  var inputs = [];

  jQuery(form).find(':input').each(function() {
    if (this.type == "checkbox" || this.type == "radio" && this.checked) {
      inputs.push(this.name + '=' + escape(this.value));
    } else if (this.type != "checkbox" && this.type != "radio") {
      inputs.push(this.name + '=' + escape(this.value));
    }
  });

  // now if I join our inputs using '&' we'll have a query string
  jQuery.post(form.action, inputs.join('&'), function(data) {
    jQuery(target).html(data);

    if (callback) {
      callback();
    }

    tb_init('a.thickbox, area.thickbox, input.thickbox');
  });

  // by default - we'll always return false so it doesn't redirect the user.
  return false;
}

function update_tab(ontology,concept){


          jQuery.get("/tab/update/"+ontology+"/"+concept)


}


function remove_tab(link,ontology,redirect){

      jQuery.get("/tab/remove/"+ontology,function(){
            if(redirect){
              window.location="/ontologies"
            }else{
              jQuery("#tab"+ontology).remove()

            }

      })

}

function selectTab(id,tab){
    nav = document.getElementById(id);
    for(var x=0; x<nav.childNodes.length; x++){
        nav.childNodes[x].className="";
    }

    document.getElementById(tab).className="selected";

}


// Method for getting parameters from the query string of a URL
(function($) {
    $.QueryString = (function(a) {
        if (a == "") return {};
        var b = {};
        for (var i = 0; i < a.length; ++i)
        {
            var p=a[i].split('=');
            if (p.length != 2) continue;
            b[p[0]] = decodeURIComponent(p[1].replace(/\+/g, " "));
        }
        return b;
    })(window.location.search.substr(1).split('&'))
})(jQuery);

function BP_queryString() {
  var a = window.location.search.substr(1).split('&');
  var b = {};
  for (var i = 0; i < a.length; ++i)
  {
      var p=a[i].split('=');
      if (p.length != 2) continue;
      b[p[0]] = decodeURIComponent(p[1].replace(/\+/g, " "));
  }
  return b;
}

function bpPopWindow(e) {
  e.preventDefault();
  var url = jQuery(e.currentTarget).attr("href");
  var pop = (url.match(/\?/) != null) ? "&pop=true" : "?pop=true";

  // Make sure to insert the query string before the hash
  url = (url.match(/#/) != null) ? [url.slice(0, url.indexOf("#")), pop, url.slice(url.indexOf("#"))].join('') : url + pop;

  newwindow = window.open(url,'bp_popup_window','height=700,width=800,resizable=yes,scrollbars=yes,toolbar=no,status=no');
  if (window.focus) {newwindow.focus()};
}
jQuery("#top_right_menu").on("click", "a.pop_window", { link: this }, bpPopWindow)

/**************************************************************
 * Standardized BP modal popups
 **************************************************************/

// Methods for working with standardized BP popups
var bp_popup_init = function(e) {
  bp_popup_cleanup();
  e.preventDefault();
  e.stopPropagation()

  var popup = jQuery(e.currentTarget).parents(".popup_container");
  var popup_list = popup.children(".bp_popup_list");

  popup.children(".bp_popup_link_container").addClass("bp_popup_shadow");
  popup.find("a.bp_popup_link").css("z-index", "5000").addClass("bp_popup_link_active");

  popup.children(".bp_popup_list").show();

  // Check for dropping off edge of screen
  if (popup_list.width() + popup_list.offset().left > jQuery(window).width()) {
    popup_list.css("left", "-250px");
  }

}

var bp_popup_cleanup = function() {
  jQuery(".bp_popup_link_container").removeClass("bp_popup_shadow");
  jQuery(".bp_popup_link").css("z-index", "").removeClass("bp_popup_link_active");
  jQuery(".bp_popup_list").hide();
}

// Sample object for working with pop-ups
/**
var filter_matched = {
  init: function() {
    jQuery("#filter_matched").bind("click", function(e){bp_popup_init(e)});
    jQuery(".match_filter").bind("click", function(e){filter_matched.filterMatched(e)});
    this.cleanup();
  },

  cleanup: function() {
    jQuery("html").click(bp_popup_cleanup);
    jQuery(document).keyup(function(e) {
      if (e.keyCode == 27) { bp_popup_cleanup(); } // esc
    });
  },

  filterMatched: function(e) {
    e.preventDefault();
    e.stopPropagation();

    var matchToFilter = jQuery(e.currentTarget);
    var filterText = matchToFilter.attr("data-bp_filter_match");

    resultsTable.fnFilter(filterText, 1);

    jQuery("#result_stats").html(jQuery(resultsTable).find("tr").length - 1 + " results");
    bp_popup_cleanup();
  }
}
**/



jQuery(window).ready(function(){
  // Helper text for advanced search filter
  jQuery("input[type=text].help_text, textarea.help_text").each(function(){
    if (jQuery(this).val() == "") {
      jQuery(this).val(jQuery(this).attr("title"));
      jQuery(this).addClass("help_text_font");
    } else {
      jQuery(this).removeClass("help_text_font");
    }
  });

  jQuery("input[type=text].help_text, textarea.help_text").live("focus", (function(){
    var input = jQuery(this);
    if (input.attr("title") == input.val()) {
      input.val("");
      input.removeClass("help_text_font");
    }
  }));

  jQuery("input[type=text].help_text, textarea.help_text").live("blur", (function(){
    var input = jQuery(this);
    if (input.val() == "") {
      input.val(input.attr("title"));
      input.addClass("help_text_font");
    }
  }));
});



// Initialize all link buttons using jQuery UI button widget
jQuery(document).ready(function(){
  jQuery("a.link_button, input.link_button").button();
});

// Truncate more/less show and hide
jQuery(document).ready(function(){
  jQuery("a.truncated_more").live("click", function(){
    var link = jQuery(this);
    link.parents("span.more_less_container").find(".truncated_more").hide();
    link.parents("span.more_less_container").find(".truncated_less").show();
  })
  jQuery("a.truncated_less").live("click", function(){
    var link = jQuery(this);
    link.parents("span.more_less_container").find(".truncated_less").hide();
    link.parents("span.more_less_container").find(".truncated_more").show();
  })
})

// Invoke a loading animation where dots are added to some load text
// Call this like: var loadAni = loadingAnimation("#loading");
// Where: <span id="loading">loading</span>
// To kill the animation, call clearInterval(loadAni);
function loadingAnimation(loadId) {
  var originalText = jQuery(loadId).text(), i = 0;
  return setInterval(function() {
    jQuery(loadId).append(".");
    i++;
    if(i == 4) {
        $(loadId).html(originalText);
        i = 0;
    }
  }, 500);
}

// Enable this to see errors in jQuery(document).ready() code
// var oldReady = jQuery.ready;
// jQuery.ready = function(){
//   try{
//     return oldReady.apply(this, arguments);
//   }catch(e){
//     console.log("ERROR *************************************")
//     console.log(e)
//   }
// };


// Automatically get ajax content
jQuery(document).ready(function(){
  // We do this with a delay to avoid queuing ahead of other async requests
  setTimeout(getAjaxContent, 1000);
});

function getAjaxContent() {
  // Look for anchors with a get_via_ajax class and replace the parent with the resulting ajax call
  $(".get_via_ajax").each(function(){
    if (typeof $(this).attr("getting_content") === 'undefined') {
      $(this).parent().load($(this).attr("href"));
      $(this).attr("getting_content", true);
    }
  });
  setTimeout(getAjaxContent, 500);
}

// Handle will_paginate using ajax
jQuery(".pagination a").live("click", function(e){
  var link = jQuery(this);
  var replaceDiv = link.closest(".paginate_ajax");
  e.preventDefault();
  if (replaceDiv.length > 0) {
    replaceDiv.load(link.attr("href"));
  } else {
    link.closest("div.pagination").parent().load(link.attr("href"));
  }
});

// Facebox settings
jQuery.facebox.settings.closeImage = "/assets/facebox/closelabel-3792a485ee43385b7848dd725ae759c70fa7acd82328ffced4ab269ef3e5bb76.png";
jQuery.facebox.settings.loadingImage = "/assets/facebox/loading-81ea81be1d862d36c34b6dc4f12aefb87b656e319003263d8274974b48ccf869.gif";

// Cookie handling
var BP_setCookie = function(key, value, options) {
  if (typeof options === "undefined") options = {};
  var days = options["days"] || null;
  var seconds = options["seconds"] || null;
  var expdate = new Date();
  var expires = "";

  if (seconds !== null) {
    expdate.setSeconds(expdate.getSeconds() + seconds);
    expires = " expires=" + expdate.toGMTString();
  }

  if (days !== null) {
    expdate.setDate(expdate.getDate() + days);
    expires = " expires=" + expdate.toGMTString();
  }

  document.cookie=key + "=" + value + ";" + expires;
}

var BP_getCookies = function(){
  var pairs = document.cookie.split(";");
  var cookies = {};
  for (var i=0; i<pairs.length; i++){
    var pair = pairs[i].split("=");
    cookies[jQuery.trim(pair[0])] = unescape(jQuery.trim(pair[1]));
  }
  return cookies;
}

var BP_getCookie = function(cookie) {
  return BP_getCookies()[cookie];
}

var currentPathArray = function() {
  var path, cleanPath = [];
  path = window.location.pathname.split('/');
  for (var i = 0; i < path.length; i++) {
    if (path[i].length > 0)
      cleanPath.push(path[i]);
  }
  return cleanPath;
}
;
function wrapupTabChange(selectedTab) {
  jQuery.unblockUI();
  tb_init('a.thickbox, area.thickbox, input.thickbox');
  jQuery(document).trigger("visualize_tab_change", [{tabType: selectedTab}]);
  jQuery(document).trigger("tree_changed");
}

function setCacheCurrent() {
  var currentData = [];

  // Store notes table data
  if (typeof notesTable !== 'undefined' && notesTable !== null && notesTable.length !== 0) {
    currentData["notes_table_data"] = notesTable.fnGetData();
  }

  // Reset the table
  resetNotesTable();

  currentData[0] = jQuery('#visualization_content').html();
  currentData[1] = jQuery('#details_content').html();
  currentData[2] = jQuery('#notes_content').html();
  currentData[3] = jQuery('#mappings_content').html();
  currentData[5] = jQuery('#note_count').html();
  currentData[6] = jQuery('#mapping_count').html();
  setCache(getConcept(), currentData);
}

function resetNotesTable() {
  jQuery(".notes_table_container div[class^=dataTables_]").remove();
}

function insertNotesTable(aData) {
  jQuery(".notes_table_container").append(jQuery("#notes_list_table_clone").clone());
  jQuery(".notes_table_container #notes_list_table_clone").attr("id", "notes_list_table");
  wireTableWithData(jQuery("#notes_list_table"), aData);
}

var simpleTreeCollection;
function initClassTree() {
  simpleTreeCollection = jQuery('.simpleTree').simpleTree({
    autoclose: false,
    drag: false,
    animate: true,
    timeout: 20000,
    afterClick:function(node){
      History.pushState({p:"classes", conceptid:jQuery(node).children("a").attr("id")}, jQuery.bioportal.ont_pages["classes"].page_name + " | " + jQuery(document).data().bp.ont_viewer.org_site, jQuery(node).children("a").attr("href"));
    },
    afterAjaxError: function(node){
      simpleTreeCollection[0].option.animate = false;
      simpleTreeCollection.get(0).nodeToggle(node.parent()[0]);
      if (node.parent().children(".expansion_error").length == 0) {
        node.parent().append("<span class='expansion_error'>Error, please try again");
      }
      simpleTreeCollection[0].option.animate = true;
    },
    beforeAjax: function(node){
      node.parent().children(".expansion_error").remove();
    }
  });

  setConcept(jQuery(document).data().bp.ont_viewer.concept_id);
  setOntology(jQuery(document).data().bp.ont_viewer.ontology_id);
  jQuery("#sd_content").scrollTo(jQuery('a.active'));

  // Set the cache for the first concept we retrieved
  setCacheCurrent();

  // Setup the "Get all classes" link for times when the children is greater than our max
  jQuery(".too_many_children_override").live('click', function(event) {
    event.preventDefault();
    var result = jQuery(this).closest("ul");
    result.html("<img src='/images/tree/spinner.gif'>");
    jQuery.ajax({
      url: jQuery(this).attr('href'),
      context: result,
      success: function(data){
        this.html(data);
        // This sets up the returned content with SimpleTree functionality
        simpleTreeCollection.get(0).setTreeNodes(this);
      },
      error: function(){
        this.html("<div style='background: #eeeeee; padding: 5px; width: 80%;'>Problem getting children. <a href='" + jQuery(this).attr('href') + "' class='too_many_children_override'>Try again</a></div>");
      }
    });
  });
};


function nodeClicked(node_id) {
  // Get current html and store data in cache (to account for changes since the cache was retrieved)
  setCacheCurrent();

  // Reset notesTable for next node
  notesTable = null;

  if(node_id == 0){
    alert("Sorry, we cannot display all the classes at this level in the hierarchy because there are too many of them. Please select another class or use the Search to find a specific concept in this ontology");
    return;
  }

  setConcept(node_id);

  // Deal with permalink
  jQuery("#purl_link_container").hide();
  var concept_uri = (node_id.indexOf("http://") == 0 || node_id.indexOf(encodeURIComponent("http://")) == 0 );
  var purl_anchor = concept_uri ? "?conceptid="+node_id : "/"+node_id;
  var selectedTab = jQuery("#bd_content div.tabs li.selected a").attr("href").slice(1);
  jQuery("#purl_input").val(jQuery(document).data().bp.ont_viewer.purl_prefix + purl_anchor);

  if (getCache(node_id) != null) {
    var tabData = getCache(node_id);
    var loc;

    // Make the clicked node active
    jQuery("a.active").removeClass("active");
    jQuery(document.getElementById(node_id)).addClass("active");

    jQuery('#visualization_content').html(tabData[0]);
    jQuery('#details_content').html(tabData[1]);
    jQuery('#notes_content').html(tabData[2]);
    jQuery('#mappings_content').html(tabData[3]);
    jQuery('#note_count').html(tabData[5]);
    jQuery('#mapping_count').html(tabData[6]);

    // Insert notes table
    insertNotesTable(tabData["notes_table_data"]);

    wrapupTabChange(selectedTab);
  } else {
    jQuery.blockUI({ message: '<h1><img src="/images/tree/spinner.gif" /> Loading Class...</h1>', showOverlay: false });
    jQuery.get('/ajax_concepts/'+jQuery(document).data().bp.ont_viewer.ontology_id+'/?conceptid='+node_id+'&callback=load',
      function(data){
        var tabData = data.split("|||");
        var loc;

        // the tabs
        jQuery('#visualization_content').html(tabData[0]);
        jQuery('#details_content').html(tabData[1]);
        jQuery('#notes_content').html(tabData[2]);
        jQuery('#mappings_content').html(tabData[3]);
        jQuery('#note_count').html(tabData[5]);
        jQuery('#mapping_count').html(tabData[6]);

        // Load the resource index
        if (selectedTab == "resource_index") {
          callTab('resource_index', '/resource_index/resources_table?conceptids='+jQuery(document).data().bp.ont_viewer.ontology_id+'/'+encodeURIComponent(getConcept()));
        }

        setCache(node_id,tabData);
        wrapupTabChange(selectedTab);
      }
    );
  }

}

// Keep trying to put the tree view content in place (looks for #sd_content)
function placeTreeView(treeHTML) {
  if (jQuery("#sd_content").length == 0) {
    setTimeout(function(){placeTreeView(treeHTML)}, 500);
  } else {
    document.getElementById("sd_content").innerHTML = treeHTML;
    initClassTree();
  }
}

// Retrieve the tree view using ajax
function getTreeView() {
  jQuery.ajax({
    url: "/ajax/classes/treeview?ontology="+jQuery(document).data().bp.ont_viewer.ontology_id+"&conceptid="+encodeURIComponent(jQuery(document).data().bp.ont_viewer.concept_id),
    success: function(data) {
      placeTreeView(data);
    },
    error: function(data) {
      jQuery.get("/ajax/classes/treeview?ontology="+jQuery(document).data().bp.ont_viewer.ontology_id+"&conceptid=root", function(data){
        var rootTree = "<div class='tree_error'>Displaying the path to this class has taken too long. You can browse classes below.</div>" + data;
        placeTreeView(rootTree);
      });
    },
    timeout: 15000
  });
}

// Get the treeview using ajax
// We do this right after writing #sd_content to the dom to make sure it loads before other async portions of the page
jQuery(document).ready(function(){
  // Abort it not right page
  var path = currentPathArray();
  if (path[0] !== "ontologies" || (path[0] === "ontologies" && path.length !== 2)) {
    return;
  }

  getTreeView();
});

"use strict";

// Note similar code in concepts_helper.rb mirrors the following code:
function bp_ont_link(ont_acronym){
  return "/ontologies/" + ont_acronym;
}
function bp_cls_link(cls_id, ont_acronym){
  return bp_ont_link(ont_acronym) + "?p=classes&conceptid=" + encodeURIComponent(cls_id);
}
function get_link_for_cls_ajax(cls_id, ont_acronym) {
  // ajax call will replace the class label using data attributes (triggered by class='cls4ajax')
  var data_cls = " data-cls='" + cls_id + "' ";
  var data_ont = " data-ont='" + ont_acronym + "' ";
  return "<a class='cls4ajax'" + data_cls + data_ont + "href='" + bp_cls_link(cls_id, ont_acronym) + "'>" + cls_id + "</a>";
}
function get_link_for_ont_ajax(ont_acronym) {
  var data_ont = " data-ont='" + ont_acronym + "' ";
  return "<a class='ont4ajax'" + data_ont + "href='" + bp_ont_link(ont_acronym) + "'>" + ont_acronym + "</a>";
}

var
  ajax_process_cls_interval = null,
  ajax_process_ont_interval = null,
  ajax_process_timeout = 20, // Timeout after 20 sec.
  ajax_process_timing = 250; // It takes about 250 msec to resolve a class ID to a prefLabel

var ajax_process_init = function () {
  ajax_process_cls_init();
  ajax_process_ont_init();
};
var ajax_process_halt = function () {
  ajax_process_cls_halt();
  ajax_process_ont_halt();
};


// **************************************************************************************
// ONTOLOGY NAMES

// Note: If we don't query every time, using the array should be faster; it
//       means the ajax_ont_init must be called after all the elements
//       are created because they will not be detected in a dynamic iteration.
var ajax_ont_array = [];
var ajax_process_ont_init = function() {
  ajax_ont_array = jQuery("a.ont4ajax").toArray();
  ajax_process_ont_interval = window.setInterval(ajax_process_ont, ajax_process_timing);
};
var ajax_process_ont_halt = function () {
  ajax_ont_array = [];
  window.clearInterval(ajax_process_ont_interval); // stop the ajax process
  // Note: might leave faulty href links, but it usually means moving on to entirely different content
  //       so it's not likely those links will be available for interaction.
  // clear all the classes and ontologies to be resolved by ajax
  //jQuery("a.ont4ajax").removeClass('ont4ajax');
  //jQuery("a.ajax-modified-ont").removeClass('ajax-modified-ont');
};
var ajax_process_ont = function() {
  if( ajax_ont_array.length === 0 ){
    ajax_process_ont_halt();
    return true;
  }
  // Note: If we don't query every time, using the array should be faster; it
  //       means the ajax_ont_init must be called after all the elements
  //       are created because they will not be detected in a dynamic iteration.
  //var linkA = jQuery("a.ont4ajax").first();
  var linkA = ajax_ont_array.shift();
  if(linkA === undefined){
    return true;
  }
  linkA = jQuery(linkA);
  if(linkA.hasClass('ajax-modified-ont') ){
    // How did we get here? It should not have the ont4ajax class!
    linkA.removeClass('ont4ajax');
    return true; // processed this one already.
  }
  linkA.removeClass('ont4ajax'); // processing this one.
  var ont_acronym = linkA.attr('data-ont');
  var ajax_uri = "/ajax/json_ontology/?ontology=" + encodeURIComponent(ont_acronym);
  jQuery.ajax({
    url: ajax_uri,
    timeout: ajax_process_timeout * 1000,
    success: function(data){
      if(typeof data !== "undefined" && data.hasOwnProperty('name')){
        var ont_name = data.name;
        linkA.text(ont_name);
        linkA.addClass('ajax-modified-ont'); // processed this one.
        // find and process any identical ontologies
        jQuery( 'a[href="/ontologies/' + ontAcronym + '"]').each(function(i,e){
          var link = jQuery(this);
          if(! link.hasClass('ajax-modified-ont') ){
            link.removeClass('ont4ajax');   // processing this one.
            link.text(ont_name);
            link.addClass('ajax-modified-ont'); // processed this one.
          }
        });
      }
    },
    error: function(data){
      linkA.addClass('ajax-error'); // processed this one.
    }
  });
};


// **************************************************************************************
// CLASS LABELS

// Note: If we don't query every time, using the array should be faster; it
//       means the ajax_process_init must be called after all the elements
//       are created because they will not be detected in a dynamic iteration.
var ajax_cls_array = [];

var ajax_process_cls_init = function() {
  ajax_cls_array = jQuery("a.cls4ajax").toArray();
  ajax_process_cls_interval = window.setInterval(ajax_process_cls, ajax_process_timing);
};

var ajax_process_cls_halt = function () {
  ajax_cls_array = [];
  window.clearInterval(ajax_process_cls_interval); // stop the ajax process
  // Note: might leave faulty href links, but it usually means moving on to entirely different content
  //       so it's not likely those links will be available for interaction.
  // clear all the classes and ontologies to be resolved by ajax
  //jQuery("a.cls4ajax").removeClass('cls4ajax');
  //jQuery("a.ajax-modified-cls").removeClass('ajax-modified-cls');
};

var ajax_process_cls = function() {
  // Check on whether to stop the ajax process
  if( ajax_cls_array.length === 0 ){
    ajax_process_cls_halt();
    return true;
  }
  // Note: If we don't query every time, using the array should be faster; it
  //       means the ajax_process_init must be called after all the elements
  //       are created because they will not be detected in a dynamic iteration.
  //var linkA = jQuery("a.cls4ajax").first();
  var linkA = ajax_cls_array.shift();
  if(linkA === undefined){
    return true;
  }
  linkA = jQuery(linkA);
  if(linkA.hasClass('ajax-modified-cls') ){
    // How did we get here? It should not have the cls4ajax class!
    linkA.removeClass('cls4ajax');
    return true; // processing or processed this one already.
  }
  linkA.removeClass('cls4ajax'); // processing this one.
  var unique_id = linkA.attr('href');


  // TODO: retrieve 'data-cls' and 'data-ont' attributes.

  var cls_id = linkA.attr('data-cls');
  var ont_acronym = linkA.attr('data-ont');
  var ont_uri = "/ontologies/" + ont_acronym;
  var cls_uri = ont_uri + "?p=classes&conceptid=" + encodeURIComponent(cls_id);
  var ajax_uri = "/ajax/classes/label?ontology=" + ont_acronym + "&concept=" + encodeURIComponent(cls_id);
  jQuery.ajax({
    url: ajax_uri,
    timeout: ajax_process_timeout * 1000,
    success: function(data){
      data = data.trim();
      if (typeof data !== "undefined" && data.length > 0 && data.indexOf("http") !== 0) {
        var cls_name = data;
        linkA.html(cls_name);
        linkA.attr('href', cls_uri);
        linkA.addClass('ajax-modified-cls');
        // find and process any identical classes (low probability)
        jQuery( 'a[href="' + unique_id + '"]').each(function(i,e){
          var link = jQuery(this);
          if(! link.hasClass('ajax-modified-cls') ){
            link.removeClass('cls4ajax');   // processing this one.
            link.html(cls_name);
            link.attr('href', cls_uri);
            link.addClass('ajax-modified-cls'); // processed this one.
          }
        });
      } else {
        // remove the unique_id separator and the ontology acronym from the href
        linkA.attr('href', cls_id);  // it may not be an ontology class, don't use the cls_uri
        linkA.addClass('ajax-modified-cls');
      }
    },
    error: function(data){
      linkA.addClass('ajax-error'); // processed this one.
    }
  });
};

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
        jQuery.blockUI({ message: '<h1><img src="/assets/jquery.simple.tree/spinner-d3e3944d4649450dee66a55c69eeced2d825b6ca1a349f72c75fd3780ae3f006.gif" /> Loading Class...</h1>', showOverlay: false });

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
        jQuery.blockUI({ message: '<h1><img src="/assets/jquery.simple.tree/spinner-d3e3944d4649450dee66a55c69eeced2d825b6ca1a349f72c75fd3780ae3f006.gif" /> Loading Class...</h1>', showOverlay: false });
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
    jQuery(document).data().bp.ontChart.init();
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
function setupReviewFacebox() {
  jQuery("a.create_review").attr("rel", "facebox[.facebox_review]");
  jQuery("a.create_review").facebox();
}

function setupReviewFaceboxSizing() {
  jQuery(document).bind('afterReveal.facebox', function() {
    jQuery("div.facebox_review").parents("div#facebox").width('850px');
    jQuery("div.facebox_review").width('820px');
    jQuery("div.facebox_review").parents("div#facebox").css("max-height", jQuery(window).height() - (jQuery("#facebox").offset().top - jQuery(window).scrollTop()) * 2 + "px");
    jQuery("div.facebox_review").parents("div#facebox").centerElement();
  });
}

jQuery(document).on("ajax:success", ".facebox_review form", function() {
  location.reload();
});
jQuery(document).ready(function(){
  setupNotesFaceboxSizing();
  bindAddCommentClick();
  bindAddProposalClick();
  bindProposalChange();
  bindReplyClick();
  bindReplyCancelClick();
  bindReplySaveClick();
  // Wire up subscriptions button activity
  jQuery("a.subscribe_to_notes").live("click", function(){
    subscribeToNotes(this);
  });
});

NOTES_PROPOSAL_TYPES = {
  "ProposalNewClass": "New Class Proposal",
  "ProposalChangeHierarchy": "New Relationship Proposal",
  "ProposalChangeProperty": "Change Property Value Proposal"
}

function getUser() {
  return jQuery(document).data().bp.user;
}

function setupNotesFacebox() {
  jQuery("a.notes_list_link").attr("rel", "facebox[.facebox_note]");
  jQuery("a.notes_list_link").each(function() {
    if (!jQuery(this).data().faceboxInit) {
      jQuery(this).facebox();
      jQuery(this).data().faceboxInit = true;
    }
  });;
}

function setupNotesFaceboxSizing() {
  jQuery(document).bind('afterReveal.facebox', function() {
    jQuery("div.facebox_note").parents("div#facebox").width('850px');
    jQuery("div.facebox_note").width('820px');
    jQuery("div.facebox_note").parents("div#facebox").css("max-height", jQuery(window).height() - (jQuery("#facebox").offset().top - jQuery(window).scrollTop()) * 2 + "px");
    jQuery("div.facebox_note").parents("div#facebox").centerElement();
  });
}

function bindAddCommentClick() {
  jQuery("a.add_comment").live('click', function(){
    var id = jQuery(this).attr("data-parent_id");
    var type = jQuery(this).attr("data-parent_type");
    addCommentBox(id, type, this);
  });
}

function bindAddProposalClick() {
  jQuery("a.add_proposal").live('click', function(){
    var id = jQuery(this).attr("data-parent_id");
    var type = jQuery(this).attr("data-parent_type");
    addProposalBox(id, type, this);
  });
}

function bindReplyClick() {
  jQuery("a.reply_reply").live('click', function(){
    addReplyBox(this);
    jQuery(this).hide();
  });
}

function bindReplyCancelClick() {
  jQuery(".reply .cancel, .create_note_form .cancel").live('click', function(){
    removeReplyBox(this);
  });
}

function bindProposalChange() {
  jQuery(".create_note_form .proposal_type").live('change', function(){
    var selector = jQuery(this);
    proposalFields(selector.val(), selector.parent().children(".proposal_container"));
  });
}

function bindReplySaveClick() {
  jQuery(".reply .save, .create_note_form .save").live('click', function(){
    var user = getUser();
    var id = jQuery(this).data("parent_id");
    var type = jQuery(this).data("parent_type");
    var button = this;
    var body = jQuery(this).closest(".reply_box").children(".reply_body").val();
    var subject = subjectForNote(button);
    var ontology_id = jQuery(document).data().bp.ont_viewer.ontology_id;
    jQuery(button).parent().children(".reply_status").html("");
    if (type === "class") {
      id = {class: id, ontology: ontology_id};
    }
    jQuery.ajax({
      type: "POST",
      url: "/notes",
      data: {parent: id, type: type, subject: subject, body: body, proposal: proposalMap(button), creator: user["id"]},
      success: function(data){
        var note = data;
        var status = data[1];
        if (status && status >= 400) {
          displayError(button);
        } else {
          addNoteOrReply(button, note);
          removeReplyBox(button);
        }
      },
      error: function(){displayError(button);}
    });
  });
}

function validateReply(button) {

}

function validateNote(button) {

}

function validateProposal(button) {

}

var displayError = function(button) {
  jQuery(button).parent().children(".reply_status").html("Error, please try again");
}

function addCommentBox(id, type, button) {
  var formContainer = jQuery(button).parents(".notes_list_container").children(".create_note_form");
  var commentSubject = jQuery("<input>")
    .attr("type", "text")
    .attr("placeholder", "Subject")
    .addClass("comment_subject")
    .add("<br>");
  var commentFields = commentSubject.add(commentForm(id,type));
  var commentWrapper = jQuery("<div>").addClass("reply_box").append(commentFields);
  formContainer.html(commentWrapper);
  formContainer.show();
}

function addProposalBox(id, type, button) {
  var formContainer = jQuery(button).parents(".notes_list_container").children(".create_note_form");
  var proposalForm = jQuery("<div>").addClass("reply_box");
  var select = jQuery("<select>").addClass("proposal_type");
  var proposalContainer;
  for (var proposalType in NOTES_PROPOSAL_TYPES) {
    select.append(jQuery("<option>").attr("value", proposalType).html(NOTES_PROPOSAL_TYPES[[proposalType]]));
  }
  proposalForm.html("Proposal type: ");
  proposalForm.append(select);
  proposalForm.append("<br/>");

  proposalContainer = jQuery("<div>").addClass("proposal_container");

  // Proposal-specific fields
  proposalFields(Object.keys(NOTES_PROPOSAL_TYPES).shift(), proposalContainer);

  proposalForm.append(proposalContainer);
  proposalForm.append(jQuery("<div>").addClass("proposal_buttons").append(commentButtons(id, type)));
  formContainer.html(proposalForm);
  formContainer.show();
}

function addNoteOrReply(button, note) {
  if (note["type"] === "http://data.bioontology.org/metadata/Note") {
    // Create a new note in the note table
    addNote(button, note);
  } else if (note["type"] === "http://data.bioontology.org/metadata/Reply") {
    // Create a new reply in the thread
    addReply(button, note);
  }
}

function addNote(button, note) {
  var user = getUser();
  var id = note["id"].split("/").pop();
  var noteLink = generateNoteLink(id, note);
  var noteLinkHTML = jQuery("<div>").append(noteLink).html();
  var created = note["created"].split("T")[0];
  // TODO_REV: Add column for note delete checkbox
  var deleteBox = "";
  var noteType = getNoteType(note);
  var noteRow = [deleteBox, noteLinkHTML, note["subject"], "false", user["username"], noteType, "", created];
  // Add note to concept table (if we're on a concept page)
  if (jQuery(button).closest("#notes_content").length > 0) {
    var jRow = jQuery("<tr>");
    jRow.append(jQuery("<td>").html(generateNoteLink("concept_"+id, note)));
    jRow.append(jQuery("<td>").html(user["username"]));
    jRow.append(jQuery("<td>").html(noteType));
    jRow.append(jQuery("<td>").html(created));
    jQuery("table.concept_notes_list").prepend(jRow);
    jQuery("#note_count").html(parseInt(jQuery("#note_count").html()) + 1);
    jQuery("a#concept_"+id).facebox();
  }
  // Add note to main table
  if (typeof ontNotesTable !== "undefined") {
    ontNotesTable.fnAddData(noteRow);
  }
  jQuery("a#"+id).facebox();
}

function addReply(button, note) {
  var user = getUser();
  var reply = jQuery("<div>").addClass("reply");
  var replyAuthor = jQuery("<div>").addClass("reply_author").html("<b>"+user["username"]+"</b> seconds ago");
  var replyBody = jQuery("<div>").addClass("reply_body").html(note.body);
  var replyMeta = jQuery("<div>").addClass("reply_meta");
  replyMeta.append(jQuery("<a>").addClass("reply_reply").attr("data-parent_id", note["id"]).attr("href", "#reply").html("reply"));
  reply.append(replyAuthor).append(replyBody).append(replyMeta);
  jQuery(button).closest("div.reply").children(".discussion").children(".discussion_container").prepend(reply);
}

function addReplyBox(button) {
  var id = jQuery(button).attr("data-parent_id");
  var type = jQuery(button).attr("data-parent_type");
  var formHTML = commentForm(id, type);
  jQuery(button).closest("div.reply").children("div.reply_meta").append(jQuery("<div>").addClass("reply_box").html(formHTML));
}

function removeReplyBox(button) {
  jQuery(button).closest("div.reply").children(".reply_meta").children("a.reply_reply").show();
  jQuery(button).closest("div.reply").children(".reply_meta").children(".reply_box").remove();
  jQuery(button).closest(".create_note_form").html("");
}

function commentForm(id, type) {
  return commentTextArea().add(commentButtons(id, type));
}

function commentTextArea() {
  return jQuery("<textarea>")
    .addClass("reply_body")
    .attr("rows","1")
    .attr("cols","1")
    .attr("name","text")
    .attr("tabindex","0")
    .attr("placeholder","Comment")
    .css({"width": "500px", "height": "100px"})
    .add("<br>");
}

function commentButtons(id, type) {
  var button_submit = jQuery("<button>")
    .attr("type","submit")
    .attr("onclick","")
    .data("parent_id", id)
    .data("parent_type", type)
    .addClass("save")
    .html("save");
  var button_cancel = jQuery("<button>")
    .attr("type","button")
    .attr("onclick","")
    .addClass("cancel")
    .html("cancel");
  var span_status = jQuery("<span>")
    .addClass("reply_status")
    .css({"color": "red", "paddingLeft": "5px"});
  return button_submit.add(button_cancel).add(span_status);
}

function appendField(id, text, div) {
  if (jQuery.browser.msie && parseInt(jQuery.browser.version) < 10) {
    div.append(jQuery("<span>").css("font-weight", "bold").html(text));
    div.append("<br/>");
  }
  div.append(jQuery("<input>").attr("type", "text").attr("id", id).attr("placeholder", text));
  div.append("<br/>");
}

function proposalFields(type, container) {
  container.html("");
  appendField("reasonForChange", "Reason for change", container);
  if (type === "ProposalChangeHierarchy") {
    appendField("newTarget", "New target", container);
    appendField("oldTarget", "Old target", container);
    appendField("newRelationshipType", "Relationship type", container);
  } else if (type === "ProposalChangeProperty") {
    appendField("propertyId", "Property id", container);
    appendField("newValue", "New value", container);
    appendField("oldValue", "Old Value", container);
  } else if (type === "ProposalNewClass") {
    appendField("classId", "Class id", container);
    appendField("label", "Label", container);
    appendField("synonym", "Synonym", container);
    appendField("definition", "Definition", container);
    appendField("parent", "Parent", container);
  }
}

function proposalMap(button) {
  var formContainer = jQuery(button).parents(".notes_list_container").children(".create_note_form");
  var lists = ["synonym", "definition", "newRelationshipType"];
  var map = {};
  map["type"] = formContainer.find(".proposal_type").val();
  console.log(formContainer.find(".proposal_container input"))
  formContainer.find(".proposal_container input").each(function(){
    var input = jQuery(this);
    var id = input.attr("id");
    var val = (jQuery.inArray(id, lists) >= 0) ? input.val().split(",") : input.val();
    map[id] = val;
  });
  return map;
}

function subjectForNote(button) {
  var subject = jQuery(button).closest(".reply_box").children(".comment_subject").val();
  var reasonForChange = jQuery("input#reasonForChange");
  if (typeof subject === "undefined" || (subject.length === 0 && reasonForChange.length > 0)) {
    subject = NOTES_PROPOSAL_TYPES[$(".proposal_type").val()] + ": " + reasonForChange.val();
  }
  return subject;
}

function generateNoteLink(id, note) {
  return jQuery("<a>")
    .addClass("ont_notes_list_link")
    .addClass("notes_list_link")
    .attr("href", "/ontologies/"+jQuery(document).data().bp.ont_viewer.ontology_id+"/notes/"+encodeURIComponent(note["id"]))
    .attr("id", id)
    .html(note["subject"]);
}

function getNoteType(note) {
  if (typeof note["proposal"] !== "undefined") {
    return NOTES_PROPOSAL_TYPES[note["proposal"][0]];
  } else {
    return "Comment";
  }
}

function subscribeToNotes(button) {
  var ontologyId = jQuery(button).attr("data-bp_ontology_id");
  var isSubbed = jQuery(button).attr("data-bp_is_subbed");
  var userId = jQuery(button).attr("data-bp_user_id");

  jQuery(".notes_sub_error").html("");
  jQuery(".notes_subscribe_spinner").show();

  jQuery.ajax({
    type: "POST",
    url: "/subscriptions?user_id="+userId+"&ontology_id="+ontologyId+"&subbed="+isSubbed,
    dataType: "json",
    success: function(data) {
      jQuery(".notes_subscribe_spinner").hide();

      // Change subbed value on a element
      var subbedVal = (isSubbed == "true") ? "false" : "true";
      jQuery("a.subscribe_to_notes").attr("data-bp_is_subbed", subbedVal);

      // Change button text
      var txt = jQuery("a.subscribe_to_notes span.ui-button-text").html();
      var newButtonText = txt.match("Unsubscribe") ? txt.replace("Unsubscribe", "Subscribe") : txt.replace("Subscribe", "Unsubscribe");
      jQuery("a.subscribe_to_notes span.ui-button-text").html(newButtonText);
    },
    error: function(data) {
      jQuery(".notes_subscribe_spinner").hide();
      jQuery(".notes_sub_error").html("Problem subscribing to emails, please try again");
    }
  });
}


;
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


;
jQuery(document).ready(function() {
  jQuery(".ontology_picker_single").live("change", function(){
    var current_side = jQuery(this).attr("id").replace("_picker", "");
    jQuery("#" + current_side)[0].autocompleter.flushCache();
    jQuery("#" + current_side)[0].autocompleter.getOptions().width = 450;

    // Set the autocompleter ontology value
    jQuery("#" + current_side)[0].autocompleter.getExtraParams()["id"] = jQuery(this).val();

    if (jQuery(this).val() == "") {
      jQuery("#" + current_side + "_bioportal_ontology_id").val("");
    }
  });

  jQuery("input.search_autocomplete").live("autocomplete_selected", function(){
    var input = jQuery(this);
    if (input.val() != input.attr("title") && input.val() !== "") {
      getClassDetails(this);
    }
  });

  jQuery("input.search_autocomplete").blur(function(){
    var input = jQuery(this);
    setTimeout(function() {
      if (input.val() == "" || input.val() == input.attr("title")) {
        jQuery("#" + input.attr("id") + "_concept_details").hide();
      }
    }, 1);
  });

  jQuery("input.search_autocomplete").each(function(){
    var input = jQuery(this);
    if (input.val() != input.attr("title") && input.val() != "") {
      getClassDetails(this);
    }
  });

  // Reset mapping UI when tree changes or loaded from ajax
  jQuery(document).live("tree_changed", resetMappingUIWithFacebox);
  jQuery(document).live("classes_tab_visible", resetMappingUI);

  // Details/visualize link to show details pane and visualize flexviz
  jQuery.facebox.settings.closeImage = "/assets/facebox/closelabel-3792a485ee43385b7848dd725ae759c70fa7acd82328ffced4ab269ef3e5bb76.png";
  jQuery.facebox.settings.loadingImage = "/assets/facebox/loading-81ea81be1d862d36c34b6dc4f12aefb87b656e319003263d8274974b48ccf869.gif";

  jQuery('#mappings_content a[rel*=facebox]').facebox();

  // Wire up popup for advanced options
  create_mapping_advanced_options.init();

  jQuery("#create_mapping_button").live("click", bp_createMapping.create);
});

// Also in bp_mappings.js
function updateMappingDeletePermissions() {
  var mapping_permission_checkbox = jQuery("#delete_mappings_permission");
  if (mapping_permission_checkbox.length === 0){
    //console.error("Failed to select #delete_mappings_permission");
    jQuery("#delete_mappings_button").hide();
    jQuery(".delete_mappings_column").hide();
    jQuery("input[name='delete_mapping_checkbox']").prop('disabled', true);
  } else {
    // Ensure the permission checkbox is hidden.
    mapping_permission_checkbox.hide();
    if (mapping_permission_checkbox.is(':checked')) {
      jQuery("#delete_mappings_button").show();
      jQuery(".delete_mappings_column").show();
      jQuery("input[name='delete_mapping_checkbox']").prop('disabled', false);
    } else {
      jQuery("#delete_mappings_button").hide();
      jQuery(".delete_mappings_column").hide();
      jQuery("input[name='delete_mapping_checkbox']").prop('disabled', true);
    }
  }
  jQuery("input[name='delete_mapping_checkbox']").prop('checked', false);
}


function getClassDetails(input) {
  var current_id = jQuery(input).attr("id");
  var current_ont_id = jQuery("#" + current_id + "_bioportal_ontology_id").val();
  var current_concept_id = jQuery("#" + current_id + "_bioportal_full_id").val();
  jQuery("#" + current_id + "_concept_details_table").html('<img style="padding: 5px;" src="/assets/spinners/spinner_000000_16px-4f45a5c270658c15e01139159c3bfca130a7db43c921af9fe77dc0cce05132bf.gif" alt="Spinner 000000 16px 4f45a5c270658c15e01139159c3bfca130a7db43c921af9fe77dc0cce05132bf" />');
  jQuery("#" + current_id + "_concept_details_table").load("/ajax/class_details?ontology=" + encodeURIComponent(current_ont_id) + "&styled=false&conceptid=" + encodeURIComponent(current_concept_id));
  jQuery("#" + current_id + "_concept_details").show();
}

function resetMappingUIWithFacebox() {
  jQuery('#mappings_content a[rel*=facebox]').facebox();
  resetMappingUI();
}

function resetMappingUI() {
  // Set the map from side to the new class from the tree
  jQuery("#map_from").val(jQuery.trim(jQuery("#sd_content a.active").text()));
  jQuery("#map_from_bioportal_full_id").val(jQuery("#sd_content a.active").attr("id"));
  getClassDetails(document.getElementById("map_from"));
  // Clear the map to side
  jQuery("#map_to_concept_details").hide();
  // Clear mapping created messages
  jQuery("#create_mapping_success_messages").html("");
  jQuery("a.link_button, input.link_button").button();
  updateMappingDeletePermissions();
}

var bp_createMapping = {
  create: function() {
    bp_createMapping.reset();
    jQuery("#create_mapping_spinner").show();
    var errored = bp_createMapping.validate();

    if (errored) {
      jQuery("#create_mapping_spinner").hide();
      return false;
    }

    var ontology_from = jQuery("#map_from_bioportal_ontology_id");
    var ontology_to = jQuery("#map_to_bioportal_ontology_id");
    var concept_from_id = jQuery("#map_from_bioportal_full_id");
    var concept_to_id = jQuery("#map_to_bioportal_full_id");
    var mapping_comment = jQuery("#mapping_comment");
    var mapping_relation = jQuery("#mapping_relation");
    var mapping_bidirectional = jQuery("#mapping_bidirectional").is(":checked");

    var params = {
      map_from_bioportal_ontology_id: ontology_from.val(),
      map_to_bioportal_ontology_id: ontology_to.val(),
      map_from_bioportal_full_id: concept_from_id.val(),
      map_to_bioportal_full_id: concept_to_id.val(),
      mapping_comment: mapping_comment.val(),
      mapping_relation: mapping_relation.val(),
      mapping_bidirectional: mapping_bidirectional
    };

    jQuery.ajax({
        url: "/mappings",
        type: "POST",
        data: params,
        success: bp_createMapping.success,
        error: bp_createMapping.error
    });
  },

  success: function(data) {
    jQuery("#create_mapping_spinner").hide();
    jQuery("#create_mapping_success_messages").prepend(jQuery("<div/>").addClass("success_message").html(
        "Mapping from <b>" + jQuery("#map_from").val() + "</b> to <b>" + jQuery("#map_to").val() + "</b> was created"
    ));

    // If we have a concept mapping table, update it with new mappings
    if (document.getElementById("concept_mappings_table") != null) {
      var url = "/ajax/mappings/get_concept_table?ontologyid=" + ontology_id + "&conceptid=" + encodeURIComponent(currentConcept);
      jQuery("#concept_mappings_table").load(url, function(){
        jQuery("#mapping_count").html(jQuery("#mapping_details tbody tr:visible").size());
      });
    }

    // Clear the map to side
    jQuery("#map_to_concept_details").hide();

    jQuery.bioportal.ont_pages["mappings"].retrieve_and_publish();
    updateMappingDeletePermissions();
  },

  error: function() {
    jQuery("#create_mapping_spinner").hide();
    jQuery("#create_mapping_error").html("There was a problem creating the mapping, please try again");
  },

  validate: function() {
    var concept_from_input = jQuery("#map_from");
    var concept_to_input = jQuery("#map_to");
    var error = jQuery("#create_mapping_error");
    var errors = ["<b>Problem creating mapping:</b>"];
    var errored = false;

    if (concept_from_input.val() == "" || concept_from_input.val() == concept_from_input.attr("title")) {
      errors.push("Please select class to map from");
      errored = true;
    }

    if (concept_to_input.val() == "" || concept_to_input.val() == concept_to_input.attr("title")) {
      errors.push("Please select class to map to");
      errored = true;
    }

    if (errors.length > 1)
      jQuery("#create_mapping_error").html(errors.join("<br/>"));

    return errored;
  },

  reset: function() {
    jQuery("#create_mapping_error").html("");
  }
}

// Popup for advanced options
var create_mapping_advanced_options = {
  init: function() {
    jQuery("#create_mapping_advanced").live("click", function(e){bp_popup_init(e)});
    jQuery("#create_mapping_advanced_options").click(function(e){e.stopPropagation()});
    this.cleanup();
  },

  cleanup: function() {
    jQuery("html").click(bp_popup_cleanup);
    jQuery(document).keyup(function(e) {
      if (e.keyCode == 27) { bp_popup_cleanup(); } // esc
    });
  }

}

;
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

;
function UserIntentionSurvey(options) {
  if (typeof options === 'undefined') {return;};

  var self                    = this;
  self.surveyName         = options.surveyName;
  self.forwardOnSubmit    = options.forwardOnSubmit == true ? true : false;
  self.forwardToUrl       = options.forwardToUrl;
  self.submitForAnalytics = options.submitForAnalytics == false ? false : true;
  self.tempDisableLength  = options.tempDisableLength || 7;
  self.surveyEnabled      = self.surveyName == "" ? false : true;
  self.timeoutKey         = "user_survey_timeout_" + self.surveyName;

  self.bindTracker = function() {
    if (BP_getCookie(self.timeoutKey) === "true" || !self.surveyEnabled) {
      return false;
    }

    var path = window.location.pathname.split("/");
    if (path.length > 2) return false;

    jQuery.get("/home/user_intention_survey", function(data){
      jQuery.facebox(data, "user_intention_survey");
    });

    jQuery(document).live("afterClose.facebox", function(){
      if (jQuery("#dont_show_again").is(":checked")) {
        self.disablePermanently();
      } else {
        self.disableTemporarily();
      }
      if (self.submitForAnalytics) {
        self.submitSurvey();
      }
    });

    jQuery("#intention_submit").live("click", function(){
      if (self.forwardToUrl) {
        self.disablePermanentlyAndForward(self.forwardToUrl);
      } else {
        self.closeDialog();
      }
    });

    jQuery("#intention_remind").live("click", function(){
      self.closeDialog();
    });

    jQuery("#intention_close").live("click", function(){
      self.closeDialog();
    });
  };

  self.disablePermanentlyAndForward = function(url) {
    BP_setCookie(self.timeoutKey, true, {days: 365});
    setTimeout(function() {
      document.location = url;
    }, 500);
  };

  self.disablePermanently = function() {
    BP_setCookie(self.timeoutKey, true, {days: 365});
  };

  self.disableTemporarily = function() {
    BP_setCookie(self.timeoutKey, true, {days: self.tempDisableLength});
  };

  self.closeDialog = function() {
    jQuery(document).trigger('close.facebox');
  };

  self.submitSurvey = function() {
    var params = self.surveyInformation();
    new Analytics().track("users", "intention_survey", params);
  };

  self.surveyInformation = function() {
    var info = {};
    info.intention_response = jQuery("#intention_response").val();
    info.contest_email = jQuery("#intention_email").val();
    info.page = window.location.href;
    return info;
  };
}
;
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
    jQuery.facebox.settings.closeImage = "/assets/facebox/closelabel-3792a485ee43385b7848dd725ae759c70fa7acd82328ffced4ab269ef3e5bb76.png";
    jQuery.facebox.settings.loadingImage = "/assets/facebox/loading-81ea81be1d862d36c34b6dc4f12aefb87b656e319003263d8274974b48ccf869.gif";

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
        jQuery("#biomixer").html('<iframe src="/ajax/biomixer/?ontology=' + acronym + '&conceptid=' + encodeURIComponent(conceptid) + '" frameborder=0 height="500px" width="500px" scrolling="no"></iframe>').show();
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
;
var
  bp_last_params = null,
  annotationsTable = null,
  annotator_ontologies = null;

// Note: the configuration is in config/bioportal_config.rb.
var BP_CONFIG = jQuery(document).data().bp.config;

var BP_COLUMNS = {
  classes: 0,
  ontologies: 1,
  types: 2,
  sem_types: 3,
  matched_classes: 5,
  matched_ontologies: 6
};

var CONCEPT_MAP = {
  "mapping": "mappedConcept",
  "mgrep": "concept",
  "closure": "concept"
};

function set_last_params(params) {
  bp_last_params = params;
  bp_last_params.apikey = BP_CONFIG.apikey; // TODO: get the user apikey?
  //console.log(bp_last_params);
}

function insertSampleText() {
  "use strict";
  var text = "Melanoma is a malignant tumor of melanocytes which are found predominantly in skin but also in the bowel and the eye.";
  jQuery("#annotation_text").focus();
  jQuery("#annotation_text").val(text);
}

function get_annotations() {
    jQuery("#results_error").html("");
    jQuery("#annotator_error").html("");

    // Validation
    if (jQuery("#annotation_text").val() === jQuery("#annotation_text").attr("title")) {
      jQuery("#annotator_error").html("Please enter text to annotate");
      return;
    }

    // Really dumb, basic word counter.
    if (jQuery("#annotation_text").val().split(' ').length > 500) {
      jQuery("#annotator_error").html("Please use less than 500 words. If you need to annotate larger pieces of text you can use the <a href='http://www.bioontology.org/wiki/index.php/Annotator_User_Guide' target='_blank'>Annotator Web Service</a>");
      return;
    }

    jQuery("#annotations_container").hide();
    jQuery(".annotator_spinner").show();
    ajax_process_halt();

    var params = {},
      ont_select = jQuery("#ontology_ontologyId"),
      mappings = [];

    params.text = jQuery("#annotation_text").val();
    params.ontologies = (ont_select.val() === null) ? [] : ont_select.val();
    params.longest_only = jQuery("#longest_only").is(':checked');
    params.exclude_numbers = jQuery("#exclude_numbers").is(':checked');
    params.whole_word_only = jQuery("#whole_word_only").is(':checked');
    params.exclude_synonyms = jQuery("#exclude_synonyms").is(':checked');

    var maxLevel = parseInt(jQuery("#class_hierarchy_max_level").val());
    if (maxLevel > 0) {
      params.expand_class_hierarchy = "true";
      params.class_hierarchy_max_level = maxLevel.toString();
    }

    // UI checkbox to control using the batch call in the controller.
    params.raw = true; // do not use batch call to resolve class prefLabel and ontology names.
    //if( jQuery("#use_ajax").length > 0 ) {
    //  params.raw = jQuery("#use_ajax").is(':checked');
    //}

    // Use the annotator default for wholeWordOnly = true.
    //if (jQuery("#wholeWordOnly:checked").val() !== undefined) {
    //  params.wholeWordOnly = jQuery("#wholeWordOnly:checked").val();
    //}

    jQuery("[name='mappings']:checked").each(function() {
      mappings.push(jQuery(this).val());
    });
    params.mappings = mappings;

    if (jQuery("#semantic_types").val() !== null) {
      params.semantic_types = jQuery("#semantic_types").val();
      annotationsTable.fnSetColumnVis(BP_COLUMNS.sem_types, true);
      jQuery("#results_error").html("Only results from ontologies with semantic types available are displayed.");
    } else {
      annotationsTable.fnSetColumnVis(BP_COLUMNS.sem_types, false);
    }

    params["recognizer"] = jQuery("#recognizer").val();

    jQuery.ajax({
      type: "POST",
      url: "/annotator", // Call back to the UI annotation_controller::create method
      data: params,
      dataType: "json",
      success: function(data) {
        set_last_params(params);
        display_annotations(data, bp_last_params);
        jQuery(".annotator_spinner").hide(200);
        jQuery("#annotations_container").show(300);
      },
      error: function(data) {
        set_last_params(params);
        jQuery(".annotator_spinner").hide(200);
        jQuery("#annotations_container").hide();
        jQuery("#annotator_error").html(" Problem getting annotations, please try again");
      }
    });

  } // get_annotations



var displayFilteredColumnNames = function() {
  "use strict";
  var column_names = [];
  jQuery(".bp_popup_list input:checked").closest("th").each(function() {
    column_names.push(jQuery(this).attr("title"));
  });
  jQuery("#filter_names").html(column_names.join(", "));
  if (column_names.length > 0) {
    jQuery("#filter_list").show();
  } else {
    jQuery("#filter_list").hide();
  }
};

function createFilterCheckboxes(filter_items, checkbox_class, checkbox_location) {
  "use strict";
  var for_sort = [],
    sorted = [];

  // Sort ontologies by number of results
  jQuery.each(filter_items, function(k, v) {
    for_sort.push({
      label: k + " (" + v + ")",
      count: v,
      value: k,
      value_encoded: encodeURIComponent(k)
    });
  });
  for_sort.sort(function(a, b) {
    return jQuery.trim(a.label) > jQuery.trim(b.label)
  });

  // Create checkboxes for ontology filter
  jQuery.each(for_sort, function() {
    var checkbox = jQuery("<input/>").attr("class", checkbox_class).attr("type", "checkbox").attr("value", this.value).attr("id", checkbox_class + this.value_encoded);
    var label = jQuery("<label/>").attr("for", checkbox_class + this.value_encoded).html(" " + this.label);
    sorted.push(jQuery("<span/>").append(checkbox).append(label).html());
  });
  jQuery("#" + checkbox_location).html(sorted.join("<br/>"));
}

var filter_ontologies = {
  init: function() {
    "use strict";
    jQuery("#filter_ontologies").bind("click", function(e) {
      bp_popup_init(e)
    });
    // Need to use bind to avoid "live" propogation issues
    jQuery(".filter_ontology_checkboxes").bind("click", function(e) {
      filter_ontologies.filterOntology(e)
    });
    jQuery("#ontology_filter_list").click(function(e) {
      e.stopPropagation()
    });
    this.cleanup();
  },

  cleanup: function() {
    "use strict";
    jQuery("html").click(bp_popup_cleanup);
    jQuery(document).keyup(function(e) {
      if (e.keyCode == 27) {
        bp_popup_cleanup();
      } // esc
    });
  },

  filterOntology: function(e) {
    "use strict";
    e.stopPropagation();
    var search_regex = [];
    jQuery(".filter_ontology_checkboxes:checked").each(function() {
      search_regex.push(jQuery(this).val());
    });
    displayFilteredColumnNames();
    if (search_regex.length === 0) {
      annotationsTable.fnFilter("", BP_COLUMNS.ontologies);
    } else {
      annotationsTable.fnFilter(search_regex.join("|"), BP_COLUMNS.ontologies, true, false);
    }
  }
};

var filter_classes = {
  init: function() {
    "use strict";
    jQuery("#filter_classes").bind("click", function(e) {
      bp_popup_init(e)
    });
    // Need to use bind to avoid "live" propogation issues
    jQuery(".filter_classes_checkboxes").bind("click", function(e) {
      filter_classes.filterClasses(e)
    });
    jQuery("#classes_filter_list").click(function(e) {
      e.stopPropagation()
    });
    this.cleanup();
  },

  cleanup: function() {
    "use strict";
    jQuery("html").click(bp_popup_cleanup);
    jQuery(document).keyup(function(e) {
      if (e.keyCode == 27) {
        bp_popup_cleanup();
      } // esc
    });
  },

  filterClasses: function(e) {
    "use strict";
    e.stopPropagation();
    var search_regex = [];
    jQuery(".filter_classes_checkboxes:checked").each(function() {
      // Escape characters used in regex
      search_regex.push(jQuery(this).val().replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"));
    });
    displayFilteredColumnNames();
    if (search_regex.length === 0) {
      annotationsTable.fnFilter("", BP_COLUMNS.classes);
    } else {
      annotationsTable.fnFilter("^" + search_regex.join("(?!.)|^") + "(?!.)", BP_COLUMNS.classes, true, false);
    }
  }
};

var filter_matched_ontologies = {
  init: function() {
    "use strict";
    jQuery("#filter_matched_ontologies").bind("click", function(e) {
      bp_popup_init(e);
    });
    // Need to use bind to avoid "live" propogation issues
    jQuery(".filter_matched_ontology_checkboxes").bind("click", function(e) {
      filter_matched_ontologies.filter(e);
    });
    jQuery("#ontology_matched_filter_list").click(function(e) {
      e.stopPropagation();
    });
    this.cleanup();
  },

  cleanup: function() {
    "use strict";
    jQuery("html").click(bp_popup_cleanup);
    jQuery(document).keyup(function(e) {
      if (e.keyCode == 27) {
        bp_popup_cleanup();
      } // esc
    });
  },

  filter: function(e) {
    "use strict";
    e.stopPropagation();
    var search_regex = [];
    jQuery(".filter_matched_ontology_checkboxes:checked").each(function() {
      search_regex.push(jQuery(this).val());
    });
    displayFilteredColumnNames();
    if (search_regex.length === 0) {
      annotationsTable.fnFilter("", BP_COLUMNS.matched_ontologies);
    } else {
      annotationsTable.fnFilter(search_regex.join("|"), BP_COLUMNS.matched_ontologies, true, false);
    }
  }
};

var filter_matched_classes = {
  init: function() {
    "use strict";
    jQuery("#filter_matched_classes").bind("click", function(e) {
      bp_popup_init(e)
    });
    // Need to use bind to avoid "live" propogation issues
    jQuery(".filter_matched_classes_checkboxes").bind("click", function(e) {
      filter_matched_classes.filter(e)
    });
    jQuery("#matched_classes_filter_list").click(function(e) {
      e.stopPropagation()
    });
    this.cleanup();
  },

  cleanup: function() {
    "use strict";
    jQuery("html").click(bp_popup_cleanup);
    jQuery(document).keyup(function(e) {
      if (e.keyCode == 27) {
        bp_popup_cleanup();
      } // esc
    });
  },

  filter: function(e) {
    "use strict";
    e.stopPropagation();
    var search_regex = [];
    jQuery(".filter_matched_classes_checkboxes:checked").each(function() {
      // Escape characters used in regex
      search_regex.push(jQuery(this).val().replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"));
    });
    displayFilteredColumnNames();
    if (search_regex.length === 0) {
      annotationsTable.fnFilter("", BP_COLUMNS.matched_classes);
    } else {
      annotationsTable.fnFilter("^" + search_regex.join("(?!.)|^") + "(?!.)", BP_COLUMNS.matched_classes, true, false);
    }
  }
};

var filter_match_type = {
  init: function() {
    "use strict";
    jQuery("#filter_match_type").bind("click", function(e) {
      bp_popup_init(e)
    });
    // Need to use bind to avoid "live" propogation issues
    jQuery(".filter_match_type_checkboxes").bind("click", function(e) {
      filter_match_type.filterMatchType(e)
    });
    jQuery("#match_type_filter_list").click(function(e) {
      e.stopPropagation()
    });
    this.cleanup();
  },

  cleanup: function() {
    "use strict";
    jQuery("html").click(bp_popup_cleanup);
    jQuery(document).keyup(function(e) {
      if (e.keyCode == 27) {
        bp_popup_cleanup();
      } // esc
    });
  },

  filterMatchType: function(e) {
    "use strict";
    e.stopPropagation();
    var search_regex = [];
    jQuery(".filter_match_type_checkboxes:checked").each(function() {
      // Escape characters used in regex
      search_regex.push(jQuery(this).val().replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"));
    });
    displayFilteredColumnNames();
    if (search_regex.length === 0) {
      annotationsTable.fnFilter("", BP_COLUMNS.types);
    } else {
      annotationsTable.fnFilter("^" + search_regex.join("(?!.)|^") + "(?!.)", BP_COLUMNS.types, true, false);
    }
  }
};

var removeFilters = function() {
  "use strict";
  jQuery(".filter_ontology_checkboxes").attr("checked", false);
  jQuery(".filter_classes_checkboxes").attr("checked", false);
  jQuery(".filter_match_type_checkboxes").attr("checked", false);
  jQuery(".filter_matched_classes_checkboxes").attr("checked", false);
  jQuery(".filter_matched_ontologies_checkboxes").attr("checked", false);
  annotationsTable.fnFilter("", BP_COLUMNS.classes);
  annotationsTable.fnFilter("", BP_COLUMNS.ontologies);
  annotationsTable.fnFilter("", BP_COLUMNS.types);
  annotationsTable.fnFilter("", BP_COLUMNS.matched_classes);
  annotationsTable.fnFilter("", BP_COLUMNS.matched_ontologies);
  jQuery("#filter_list").hide();
};

// Datatables reset sort extension
jQuery.fn.dataTableExt.oApi.fnSortNeutral = function(oSettings) {
  "use strict";
  /* Remove any current sorting */
  oSettings.aaSorting = [];
  /* Sort display arrays so we get them in numerical order */
  oSettings.aiDisplay.sort(function(x, y) {
    return x - y;
  });
  oSettings.aiDisplayMaster.sort(function(x, y) {
    return x - y;
  });
  /* Redraw */
  oSettings.oApi._fnReDraw(oSettings);
};


function annotatorFormatLink(param_string, format) {
  "use strict";
  // TODO: Check whether 'text' and 'tabDelimited' could work.
  // For now, assume that json and xml will work or should work.
  var format_map = {
    "json": "JSON",
    "xml": "XML",
    "text": "Text",
    "tabDelimited": "CSV"
  };
  var query = BP_CONFIG.rest_url + "/annotator?apikey=" + BP_CONFIG.apikey + "&" + param_string;
  if (format !== 'json') {
    query += "&format=" + format;
  }
  var link = "<a href='" + encodeURI(query) + "' target='_blank'>" + format_map[format] + "</a>";
  jQuery("#download_links_" + format.toLowerCase()).html(link);
}

function generateParameters() {
  "use strict";
  var params = [];
  var new_params = jQuery.extend(true, {}, bp_last_params); // deep copy
  delete new_params["apikey"];
  delete new_params["format"];
  delete new_params["raw"];
  //console.log(new_params);
  jQuery.each(new_params, function(k, v) {
    if (v !== null && v !== undefined) {
      if (typeof v == "boolean") {
        params.push(k + "=" + v);
      } else if (typeof v == "string" && v.length > 0) {
        params.push(k + "=" + v);
      } else if (typeof v == "array" && v.length > 0) {
        params.push(k + "=" + v.join(','));
      } else if (typeof v == "object" && v.length > 0) {
        params.push(k + "=" + v.join(','));
      }
    }
  });
  return params.join("&");
}

jQuery(document).ready(function() {
  "use strict";
  jQuery("#annotator_button").click(get_annotations);
  jQuery("#semantic_types").chosen({
    search_contains: true
  });
  jQuery("#insert_text_link").click(insertSampleText);
  // Init annotation table
  annotationsTable = jQuery("#annotations").dataTable({
    bPaginate: false,
    bAutoWidth: false,
    aaSorting: [],
    oLanguage: {
      sZeroRecords: "No annotations found"
    },
    "aoColumns": [{
      "sWidth": "15%"
    }, {
      "sWidth": "15%"
    }, {
      "sWidth": "5%"
    }, {
      "sWidth": "5%",
      "bVisible": false
    }, {
      "sWidth": "30%"
    }, {
      "sWidth": "15%"
    }, {
      "sWidth": "15%"
    }]
  });
  filter_ontologies.init();
  filter_classes.init();
  filter_match_type.init();
  filter_matched_ontologies.init();
  filter_matched_classes.init();
}); // doc ready


function get_link(uri, label) {
  "use strict";
  return '<a href="' + uri + '">' + label + '</a>';
}

function get_class_details(cls) {
  var
    cls_rel_ui = cls.ui.replace(/^.*\/\/[^\/]+/, ''),
    ont_rel_ui = cls_rel_ui.replace(/\?p=classes.*$/, '?p=summary');
  return class_details = {
    cls_rel_ui: cls_rel_ui,
    ont_rel_ui: ont_rel_ui,
    cls_link: get_link(cls_rel_ui, cls.prefLabel),
    ont_link: get_link(ont_rel_ui, cls.ontology.name),
    semantic_types: cls.semantic_types.join('; ') // test with 'abscess' text and sem type = T046,T020
  }
}

function get_class_details_from_raw(cls) {
  var
    ont_acronym = cls.links.ontology.replace(/.*\//, ''),
    ont_name = annotator_ontologies[cls.links.ontology].name,
    ont_rel_ui = '/ontologies/' + ont_acronym,
    ont_link = null;
  if (ont_name === undefined) {
    ont_link = get_link_for_ont_ajax(ont_acronym);
  } else {
    ont_link = get_link(ont_rel_ui, ont_name); // no ajax required!
  }
  var
    cls_rel_ui = cls.links.ui.replace(/^.*\/\/[^\/]+/, ''),
    cls_label = cls.prefLabel,
    cls_link = null;
  if (cls_label === undefined) {
    cls_link = get_link_for_cls_ajax(cls['@id'], ont_acronym);
  } else {
    cls_link = get_link(cls_rel_ui, cls_label); // no ajax required!
  }
  return class_details = {
    cls_rel_ui: cls_rel_ui,
    ont_rel_ui: ont_rel_ui,
    cls_link: cls_link,
    ont_link: ont_link,
    //
    // TODO: Get semantic types from raw data, currently provided by controller.
    //semantic_types: cls.semantic_types.join('; ') // test with 'abscess' text and sem type = T046,T020
    semantic_types: ''
  }
}

function get_text_markup(text, from, to) {
  var
    text_match = text.substring(from - 1, to),
    // remove everything prior to the preceding three words (using space delimiters):
    text_prefix = text.substring(0, from - 1).replace(/.* ((?:[^ ]* ){2}[^ ]*$)/, "... $1"),
    // remove the fourth space and everything following it
    text_suffix = text.substring(to).replace(/^((?:[^ ]* ){3}[^ ]*) [\S\s]*/, "$1 ..."),
    match_span = '<span style="color: rgb(153,153,153);">',
    match_markup_span = '<span style="color: rgb(35, 73, 121); font-weight: bold; padding: 2px 0px;">',
    text_markup = match_markup_span + text_match + "</span>";
  //console.log('text markup: ' + text_markup);
  return match_span + text_prefix + text_markup + text_suffix + "</span>";
}

function get_annotation_rows(annotation, params) {
  "use strict";
  // data independent var declarations
  var
    rows = [],
    cells = [],
    text_markup = '',
    match_type = '',
    match_type_translation = {
      "mgrep": "direct",
      "mapping": "mapping",
      "closure": "ancestor"
    };
  // data dependent var declarations
  var cls = get_class_details(annotation.annotatedClass);
  jQuery.each(annotation.annotations, function(i, a) {
    text_markup = get_text_markup(params.text, a.from, a.to);
    match_type = match_type_translation[a.matchType.toLowerCase()] || 'direct';
    cells = [cls.cls_link, cls.ont_link, match_type, cls.semantic_types, text_markup, cls.cls_link, cls.ont_link];
    rows.push(cells);
    // Add rows for any classes in the hierarchy.
    match_type = 'ancestor';
    var h_c = null;
    jQuery.each(annotation.hierarchy, function(i, h) {
      h_c = get_class_details(h.annotatedClass);
      cells = [h_c.cls_link, h_c.ont_link, match_type, cls.semantic_types, text_markup, cls.cls_link, cls.ont_link];
      rows.push(cells);
    }); // hierarchy loop
    // Add rows for any classes in the mappings. Note the ont_link will be different.
    match_type = 'mapping';
    var m_c = null;
    jQuery.each(annotation.mappings, function(i, m) {
      m_c = get_class_details(m.annotatedClass);
      cells = [m_c.cls_link, m_c.ont_link, match_type, cls.semantic_types, text_markup, cls.cls_link, cls.ont_link];
      rows.push(cells);
    }); // mappings loop
  }); // annotations loop
  return rows;
}

function get_annotation_rows_from_raw(annotation, params) {
  "use strict";
  // data independent var declarations
  var
    rows = [],
    cells = [],
    text_markup = '',
    match_type = '',
    match_type_translation = {
      "mgrep": "direct",
      "mapping": "mapping",
      "closure": "ancestor"
    };
  // data dependent var declarations
  var cls = get_class_details_from_raw(annotation.annotatedClass);
  if (annotation.annotations.length == 0) {
    cells = [cls.cls_link, cls.ont_link, "", cls.semantic_types, "", cls.cls_link, cls.ont_link];
    rows.push(cells);
  } else {
    jQuery.each(annotation.annotations, function(i, a) {
      text_markup = get_text_markup(params.text, a.from, a.to);
      match_type = match_type_translation[a.matchType.toLowerCase()] || 'direct';
      cells = [cls.cls_link, cls.ont_link, match_type, cls.semantic_types, text_markup, cls.cls_link, cls.ont_link];
      rows.push(cells);
      // Add rows for any classes in the hierarchy.
      match_type = 'ancestor';
      var h_c = null;
      jQuery.each(annotation.hierarchy, function(i, h) {
        h_c = get_class_details_from_raw(h.annotatedClass);
        cells = [h_c.cls_link, h_c.ont_link, match_type, cls.semantic_types, text_markup, cls.cls_link, cls.ont_link];
        rows.push(cells);
      }); // hierarchy loop
      // Add rows for any classes in the mappings. Note the ont_link will be different.
      match_type = 'mapping';
      var m_c = null;
      jQuery.each(annotation.mappings, function(i, m) {
        m_c = get_class_details_from_raw(m.annotatedClass);
        cells = [m_c.cls_link, m_c.ont_link, match_type, cls.semantic_types, text_markup, cls.cls_link, cls.ont_link];
        rows.push(cells);
      }); // mappings loop
    }); // annotations loop
  }
  return rows;
}


function update_annotations_table(rowsArray) {
  "use strict";
  var ontologies = {},
    classes = {},
    match_types = {},
    matched_ontologies = {},
    matched_classes = {},
    context_count = 0;

  jQuery(rowsArray).each(function() {
    // [ cls_link, ont_link, match_type, semantic_types, text_markup, cls_link, ont_link ];
    var row = this,
      cls_link = row[0],
      ont_link = row[1],
      match_type = row[2], // direct, ancestors, mapping
      //semantic_type = row[3],
      //match_text = row[4],
      match_cls_link = row[5],
      match_ont_link = row[6];
    // Extract labels from links (using non-greedy regex).
    var cls_label = cls_link.replace(/^<a.*?>/, '').replace('</a>', '').toLowerCase(),
      ont_label = ont_link.replace(/^<a.*?>/, '').replace('</a>', ''),
      match_cls_label = match_cls_link.replace(/^<a.*?>/, '').replace('</a>', '').toLowerCase(),
      match_ont_label = match_ont_link.replace(/^<a.*?>/, '').replace('</a>', '');

    // TODO: Gather sem types for display
    //    var semantic_types = [];
    //    jQuery.each(annotation.concept.semantic_types, function () {
    //      semantic_types.push(this.description);
    //    });

    // Keep track of contexts. If there are none (IE when using mallet), hide the column
    if (row[4] !== "") context_count++;

    // Keep track of how many results are associated with each ontology
    ontologies[ont_label] = (ont_label in ontologies) ? ontologies[ont_label] + 1 : 1;
    // Keep track of how many results are associated with each class
    classes[cls_label] = (cls_label in classes) ? classes[cls_label] + 1 : 1;
    // Keep track of match types
    match_types[match_type] = (match_type in match_types) ? match_types[match_type] + 1 : 1;
    // Keep track of matched classes
    matched_classes[match_cls_label] = (match_cls_label in matched_classes) ? matched_classes[match_cls_label] + 1 : 1;
    // Keep track of matched ontologies
    matched_ontologies[match_ont_label] = (match_ont_label in matched_ontologies) ? matched_ontologies[match_ont_label] + 1 : 1;
  });

  // Add result counts
  var count_span = '<span class="result_count">'
  jQuery("#result_counts").html("total results " + count_span + rowsArray.length + "</span>&nbsp;");
  var direct_count = ("direct" in match_types) ? match_types["direct"] : 0,
    ancestor_count = ("ancestor" in match_types) ? match_types["ancestor"] : 0,
    mapping_count = ("mapping" in match_types) ? match_types["mapping"] : 0;
  jQuery("#result_counts").append("(");
  jQuery("#result_counts").append("direct " + count_span + direct_count + "</span>");
  jQuery("#result_counts").append("&nbsp;/&nbsp;" + "ancestor " + count_span + ancestor_count + "</span>");
  jQuery("#result_counts").append("&nbsp;/&nbsp;" + "mapping " + count_span + mapping_count + "</span>");
  jQuery("#result_counts").append(")");

  // Add checkboxes to filters
  createFilterCheckboxes(ontologies, "filter_ontology_checkboxes", "ontology_filter_list");
  createFilterCheckboxes(classes, "filter_classes_checkboxes", "classes_filter_list");
  createFilterCheckboxes(match_types, "filter_match_type_checkboxes", "match_type_filter_list");
  createFilterCheckboxes(matched_ontologies, "filter_matched_ontology_checkboxes", "matched_ontology_filter_list");
  createFilterCheckboxes(matched_classes, "filter_matched_classes_checkboxes", "matched_classes_filter_list");

  // Reset table
  annotationsTable.fnClearTable();
  annotationsTable.fnSortNeutral();
  removeFilters();

  // Need to re-init because we're not using "live" because of propagation issues
  filter_ontologies.init();
  filter_classes.init();
  filter_match_type.init();
  filter_matched_ontologies.init();
  filter_matched_classes.init();

  // Add data
  if (rowsArray.length > 0) {
    annotationsTable.fnAddData(rowsArray);
  }

  // Hide columns as necessary
  if (context_count == 0)
    annotationsTable.fnSetColumnVis(4, false);

  var match_keys = Object.keys(match_types);
  if (match_keys.length == 1 && match_keys[0] === "")
    annotationsTable.fnSetColumnVis(2, false);
}


function display_annotations(data, params) {
  "use strict";
  var annotations = data.annotations;
  var all_rows = [];
  if (params.raw !== undefined && params.raw === true) {
    // The annotator_controller does not 'massage' the REST data.
    // The class prefLabel and ontology name must be resolved with ajax.
    annotator_ontologies = data.ontologies;
    for (var i = 0; i < annotations.length; i++) {
      all_rows = all_rows.concat(get_annotation_rows_from_raw(annotations[i], params));
    }
  } else {
    // The annotator_controller does 'massage' the REST data.
    // The class prefLabel and ontology name get resoled with a batch all in the controller.
    for (var i = 0; i < annotations.length; i++) {
      all_rows = all_rows.concat(get_annotation_rows(annotations[i], params));
    }
  }
  update_annotations_table(all_rows);
  // Generate parameters for list at bottom of page
  var param_string = generateParameters(); // uses bp_last_param
  var query = BP_CONFIG.rest_url + "/annotator?" + param_string;
  var query_encoded = BP_CONFIG.rest_url + "/annotator?" + encodeURIComponent(param_string);
  jQuery("#annotator_parameters").html(query);
  jQuery("#annotator_parameters_encoded").html(query_encoded);
  // Add links for downloading results
  //annotatorFormatLink("tabDelimited");
  annotatorFormatLink(param_string, "json");
  annotatorFormatLink(param_string, "xml");
  if (params.raw !== undefined && params.raw === true) {
    // Initiate ajax calls to resolve class ID to prefLabel and ontology acronym to name.
    ajax_process_init(); // see bp_ajax_controller.js
  }
}



// Creates an HTML form with a button that will POST to the annotator
//function annotatorPostForm(format) {
//  "use strict";
//  // TODO: Check whether 'text' and 'tabDelimited' could work.
//  // For now, assume that json and xml will work or should work.
//  var format_map = { "json": "JSON", "xml": "XML", "text": "Text", "tabDelimited": "CSV" };
//  var params = bp_last_params;
//  params["format"] = format;
//  var form_fields = [];
//  jQuery.each(params, function (k, v) {
//    if (v != null) {
//      form_fields.push("<input type='hidden' name='" + k + "' value='" + v + "'>");
//    }
//  });
//  var action = "action='" + BP_CONFIG.rest_url + "/annotator'";
//  var form = jQuery("<form " + action + " method='post' target='_blank'/>")
//    .append(form_fields.join(""))
//    .append("<input type='submit' value='" + format_map[format] + "'>");
//  jQuery("#download_links_" + format.toLowerCase()).html(form);
//}
;
// History and navigation management
(function (window, undefined) {
  // Establish Variables
  var History = window.History;
  // History.debug.enable = true;

  // Abort it not right page
  var path = currentPathArray();
  if (path[0] !== "resource_index") {
    return;
  }

  // Bind to State Change
  History.Adapter.bind(window, 'statechange', function () {
    var state = History.getState();
    if (typeof state.data.route !== "undefined") {
      router.route(state.data.route, state.data);
    } else {
      router.route("index");
    }
  });
}(window));

var uri_split_chars = "\t::\t";
var uri_split = function(combinedURIs) {
  return combinedURIs.split(uri_split_chars);
};
var uri_combine = function(ont_uri, cls_uri) {
  return ont_uri + uri_split_chars + cls_uri;
};


var bpResourceIndexEmbedded = false;
jQuery(document).ready(function () {
  bpResourceIndexEmbedded = (jQuery("#resource_table").parents("div.resource_index_embed").length > 0);
  // Hide/Show resources
  jQuery(".resource_link").live("click", function (event) {
    event.preventDefault();
    switchResources(this);
  });

  // Show/Hide advanced options
  jQuery("#resource_index_advanced_options").on("click", function(event) {
    jQuery("#search_options").toggleClass("not_visible");
    jQuery("#hide_advanced_options").toggleClass("not_visible");
  });

  // Spinner for pagination
  jQuery(".pagination a").live("click", function () {
    jQuery(this).parents("div.pagination").append('&nbsp;&nbsp; <span style="font-size: small; font-weight: normal;">loading</span> ' + '<img style="vertical-align: text-bottom;" src="/assets/spinners/spinner_000000_16px-4f45a5c270658c15e01139159c3bfca130a7db43c921af9fe77dc0cce05132bf.gif" alt="Spinner 000000 16px 4f45a5c270658c15e01139159c3bfca130a7db43c921af9fe77dc0cce05132bf" />');
  });

  // Make chosen work via ajax
  if (jQuery("#resource_index_classes").length > 0) {
    jQuery("#resource_index_classes").ajaxChosen({
      minLength    : 3,
      queryLimit   : 10,
      delay        : 500,
      chosenOptions: {},
      searchingText: "Searching for concept ",
      noresultsText: "Concepts not found",
      initialQuery : false
    }, function (options, response, event) {
      // jQuery("#resource_index_classes_chzn .chzn-results li.active-result").remove();
      var format = 'json';
      var search_url = jQuery(document).data().bp.config.rest_url+"/search"; // direct REST API
      var search_term = jQuery.trim(options.term);
      if (/[^*]$/.test(search_term)) {
        search_term += '*';
      }
      var search_params = {};
      search_params['q'] = search_term;
      search_params['format'] = format;
      search_params['apikey'] = jQuery(document).data().bp.config.apikey;
      // NOTE: disabled ontologies selection in the UI, ensure it has no value here.
      // NOTE: ontologies are specified in resource_index_controller::search_classes
      search_params['ontologies'] = currentOntologyAcronyms().join(',');
      jQuery.ajax({
        url: search_url,
        data: search_params,
        dataType: format,
        success: function(data){
          jQuery("#search_spinner").hide();
          jQuery("#search_results").show();
          var classes = {}, classHTML = "";
          jQuery.each(data.collection, function (index, cls) {
            var cls_id = cls["@id"];
            var ont_id = cls.links.ontology;
            var ont_name = ont_id.split('/').slice(-1)[0];
            classHTML = "" +
              "<span class='search_ontology' title='" + ont_id + "'>" +
                "<span class='search_class' title='" + cls_id + "'>" +
                  markupClass(cls).prop('outerHTML') +
                  "<span class='search_ontology_acronym'>(" + ont_name + ")</span>" +
              "</span>";
            // Create a combination of ont_id and cls_id that can be split when retrieved.
            // This will be the option value in the selected drop-down list.
            var combined_uri = uri_combine(ont_id, cls_id);
            classes[combined_uri] = classHTML;
          });
          response(classes);  // Chosen plugin creates select list.
        },
        error: function(){
          jQuery("#search_spinner").hide();
          jQuery("#search_results").hide();
          jQuery("#search_messages").html("<span style='color: red'>Problem searching, please try again");
        }
      });
    });
  }

  function markupClass(cls) {
    // Wrap the class prefLabel in a span, indicating that the class is obsolete if necessary.
    var max_word_length = 60;
    var label_text = (cls.prefLabel.length > max_word_length) ? cls.prefLabel.substring(0, max_word_length) + "..." : cls.prefLabel;
    var label_html = jQuery("<span/>").addClass('prefLabel').append(label_text);
    if (cls.obsolete === true){
      label_html.removeClass('prefLabel');
      label_html.addClass('obsolete_class');
      label_html.attr('title', 'obsolete class');
    }
    return label_html; // returns a jQuery object; use .prop('outerHTML') to get markup text.
  }

  // If all classes are removed from the search, put the UI in base state
  jQuery("a.search-choice-close").live("click", function () {
    if (chosenSearchClassesArgs() === null) {
      pushIndex();
      var input = document.activeElement
      jQuery("#resource_index_classes_chzn").trigger("mousedown");
      input.blur();
      jQuery("#resource_index_classes_chzn input").data("prevVal", "");
      jQuery("#resource_index_classes_chzn .chzn-results li").remove();
    }
  });

  // Get search results
  if (jQuery("#resource_index_button").length > 0) {
    jQuery("#resource_index_button").click(function () {
      var url = "/resource_index/resources?" + chosenSearchClassesArgs();
      pushDisplayResources(url, {classes: chosenSearchClasses()});
      getSearchResults();
    });
  }

  // Show/Hide results with zero matches
  jQuery("#show_hide_no_results").live("click", function () {
    jQuery("#resource_table .zero_results").toggleClass("not_visible").effect("highlight", { color: "yellow" }, 500);
    jQuery("#show_hide_no_results .show_hide_text").toggleClass("not_visible");
  });

  jQuery(".show_element_details").live("click", function (e) {
    e.preventDefault();
    var el = jQuery(this);
    var cleanElementId = el.data().cleanElementId;
    var el_text = jQuery("#" + cleanElementId + "_text");
    el_text.toggleClass("not_visible");
    if (el_text.attr("highlighted") !== "true") {
      var element = new Element(el.data().elementId, cleanElementId, chosenSearchClasses(), el.data().resourceId);
      el.parent().append("<span id='" + element.cleanId + "_ani'class='highlighting'>highlighting... <img style='vertical-align: text-bottom;' src='/images/spinners/spinner_000000_16px.gif'></span>");
      element.highlightAnnotationPositions();
      el_text.attr("highlighted", "true");
    }
  });
});

// Get parameters from the URL
var BP_urlParams = {};
(function () {
  var match, hashParamMatch, paramHash,
    pl = /\+/g,  // Regex for replacing addition symbol with a space
    search = /([^&=]+)=?([^&]*)/g,
    decode = function (s) {
      return decodeURIComponent(s.replace(pl, " "));
    },
  query = window.location.search.substring(1);
  queryH = window.location.hash.substring(1);

  while (match = search.exec(query)) {
    if (hashParamMatch = /^(\w+)\[(.*)\]$/.exec(match[1])) {
      paramHash = BP_urlParams[hashParamMatch[1]];
      if (paramHash === undefined) {
        paramHash = {};
      }
      if (paramHash[decode(hashParamMatch[2])] === undefined) {
        paramHash[decode(hashParamMatch[2])] = [];
      }
      paramHash[decode(hashParamMatch[2])] = decode(match[2]).split(",");
      BP_urlParams[hashParamMatch[1]] = paramHash;
    } else {
      BP_urlParams[decode(match[1])] = decode(match[2]);
    }
  }

  while (match = search.exec(queryH)) {
    if (hashParamMatch = /^(\w+)\[(.*)\]$/.exec(match[1])) {
      paramHash = BP_urlParams[hashParamMatch[1]];
      if (paramHash === undefined) {
        paramHash = {};
      }
      if (paramHash[decode(hashParamMatch[2])] === undefined) {
        paramHash[decode(hashParamMatch[2])] = [];
      }
      paramHash[decode(hashParamMatch[2])] = decode(match[2]).split(",");
      BP_urlParams[hashParamMatch[1]] = paramHash;
    } else {
      BP_urlParams[decode(match[1])] = decode(match[2]);
    }
  }
})();

function pageInit() {
  var state = History.getState();
  var params = {}, paramLocations = ["root", "resources", "acronym"], route, queryString;
  route = state.hash.split("?");
  queryString = (typeof route[1] !== "undefined") ? "" : route[1];
  route = route[0].split("/").slice(1);
  for (var i = 0; i < route.length; i++) {
    params[paramLocations[i]] = route[i];
  }
  jQuery.extend(params, BP_urlParams);
  BP_urlParams = params;
  if (typeof params["acronym"] !== "undefined") {
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
    params["route"] = route;
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

// This will look up any class labels that haven't already been processed. If there are none it just exits without doing anything.
// To decrease ajax calls, we also use the bp_classes_cache. This method is used via polling.
var bp_classes_cache = {};
function lookupClassLabels() {
  jQuery("#resource_results a.ri_concept[data-applied_label='false']").each(function () {
    var link = jQuery(this);
    var params = { conceptid: decodeURIComponent(link.data("concept_id")), ontologyid: link.data("ontology_id") };
    link.attr("data-applied_label", "true");

    // Check to see if another thread is already making an ajax request and start polling
    if (bp_classes_cache[params.ontologyid + "/" + params.conceptid] === "getting") {
      return setTimeout((function () {
        return applyClassLabel(link, params);
      }), 100);
    }

    if (typeof bp_classes_cache[params.ontologyid + "/" + params.conceptid] === "undefined") {
      bp_classes_cache[params.ontologyid + "/" + params.conceptid] = "getting";
      jQuery.ajax({
        url     : "/ajax/json_class",
        data    : params,
        dataType: 'json',
        success : (function (link) {
          return function (data) {
            bp_classes_cache[params.ontologyid + "/" + params.conceptid] = data;
            if (data !== null) jQuery(link).html(data.prefLabel);
          }
        })(this)
      });
    }
  })
}

// Poll for class information
jQuery(document).ready(function () {
  setInterval((function () {
    lookupClassLabels();
  }), 1000);
});

// This function will poll to see if class information exists
function applyClassLabel(link, params, calledAgain) {
  var class_info = bp_classes_cache[params.ontologyid + "/" + params.conceptid];
  if (class_info === "getting") {
    if (typeof calledAgain !== "undefined") calledAgain = 0
    return setTimeout((function () {
      return applyClassLabel(link, params, calledAgain += 1);
    }), 100);
  }
  if (class_info !== null) jQuery(link).html(class_info.prefLabel);
}

function Router() {
  this.route = function (route, params) {
    switch (route) {
      case "index":
        this.index();
        break;
      case "resource":
        this.resource(params);
        break;
      case "resources":
        this.resources(params);
        break;
    }
  };

  this.index = function () {
    jQuery("#results").html("");
    jQuery("#results_error").html("");
    jQuery("#initial_resources").show();
    jQuery("#resource_index_classes_chzn .search-choice-close").click();
  };

  this.resource = function (params) {
    if (typeof params["classes"] === "undefined" || typeof params["acronym"] === "undefined") {
      replaceIndex();
    }
    displayResource(params);
  };

  this.resources = function (params) {
    if (typeof params["classes"] === "undefined") {
      replaceIndex();
    }
    displayResources(params["classes"]);
  };

}
router = new Router();

function displayResource(params) {
  var resource = params["acronym"];
  if (resource === undefined || resources[resource] === undefined) {
    return;
  }
  var name = resources[resource].name;
  // Only retrieve class information if this is an initial load
  if (jQuery("#resource_index_classes").val() !== null) {
    showResourceResults(resource, name);
    return;
  }
  displayClasses(params["classes"], function () {
    showResourceResults(resource, name);
  });
}

function displayResources(classes) {
  // Only retrieve class information if this is an initial load
  if (jQuery("#resource_index_classes").val() !== null) {
    showAllResources();
    return;
  }
  displayClasses(classes);
}

function displayClasses(classes, completedCallback) {
  var concept, conceptOpt, ontologyId, conceptId, ontologyName, conceptsLength, params, ontClasses, chsnValue,
      conceptRetreivedCount = 0,
      ontClassPairs = [];

  for (ontology in classes) {
    ontClasses = classes[ontology];
    for (var i = 0; i < ontClasses.length; i++) {
      ontClassPairs.push([ontology, ontClasses[i]]);
    }
  }
  conceptsLength = ontClassPairs.length;

  jQuery("#resource_index_classes").html("");
  for (var i = 0; i < ontClassPairs.length; i++) {
    ontClassPair = ontClassPairs[i];
    ontologyId = ontClassPair[0];
    ontologyAcronym = ontClassPair[0].split("/").slice(-1)[0];
    conceptId = ontClassPair[1];
    ontologyName = ont_names[ontologyId];
    params = { ontologyid: ontologyAcronym, conceptid: conceptId };
    chsnValue = ontologyId + uri_split_chars + conceptId;
    jQuery.getJSON("/ajax/json_class", params, (function (ontologyAcronym, chsnValue) {
      return function (data) {
        jQuery("#resource_index_classes")
            .append(jQuery("<option/>")
            .attr("selected", true)
            .val(chsnValue)
            .html(" " + data.prefLabel + " <span class='search_ontology_acronym'>(" + ontologyAcronym + ")</span>"));
        conceptRetreivedCount += 1;
        if (conceptRetreivedCount == conceptsLength) {
          updateChosen();
          getSearchResults(completedCallback);
        }
      }
    })(ontologyAcronym, chsnValue));
  }
}

function updateChosen() {
  jQuery("#resource_index_classes").trigger("liszt:updated");
  jQuery("#resource_index_classes").trigger("change");
}

function getSearchResults(success) {
  jQuery("#results_error").html("");
  jQuery("#resource_index_spinner").show();
  jQuery("#results.contains_search_results").hide();
  var params = {
    classes: chosenSearchClasses(), // ontologyURI: [classURI, classURI, ... ]
    boolean_operator: jQuery('input:radio[name=boolean_operator]:checked').val(),
    expand_hierarchy: jQuery('input:radio[name=expand_hierarchy]:checked').val()
  };
  jQuery.ajax({
    type    : 'POST',
    url     : "/resource_index",
    data    : params,
    dataType: 'html',
    success : function (data) {
      jQuery("#results").html(data);
      jQuery("#results").addClass("contains_search_results");
      jQuery("#results.contains_search_results").show();
      jQuery("#results_container").show();
      jQuery("#resource_index_spinner").hide();
      if (success && typeof success === "function") {
        success();
      }
      jQuery("#initial_resources").hide();
      jQuery("#resource_table table").dataTable({
        "bPaginate": false,
        "bFilter"  : false,
        "aoData"   : [
          { "sType": "html" },
          { "sType": "html-formatted-num", "asSorting": [ "desc", "asc"] },
          { "sType": "percent", "asSorting": [ "desc", "asc"] },
          { "sType": "html-formatted-num", "asSorting": [ "desc", "asc"] }
        ]
      });
      // Update result counts for resources with matches
      updateCounts();
    },
    error   : function () {
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
  jQuery("#result_counts").html("matches in " + visibleRows + " of " + totalRows + " resources")
}

jQuery("a.results_link").live("click", function (event) {
  var resource = jQuery(this).data().resourceId;
  var url = "/resource_index/resources/" + resource + "?" + chosenSearchClassesArgs();
  pushDisplayResource(url, {classes: chosenSearchClasses(), acronym: resource});
});

jQuery("a#show_all_resources").live("click", function () {
  var url = "/resource_index/resources?" + chosenSearchClassesArgs();
  pushDisplayResources(url, {classes: chosenSearchClasses()});
});

function showResourceResults(resource, name) {
  jQuery("#resource_info_" + resource).find("a.resource_results_ajax").addClass("get_via_ajax");
  jQuery(".resource_info").addClass("not_visible");
  jQuery("#resource_table").addClass("not_visible");
  jQuery("#resource_info_" + resource).removeClass("not_visible");
  jQuery("#resource_title").html(name);
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

function Element(id, cleanId, classes, resource) {
  this.positions;
  this.id = id;
  this.cleanId = cleanId;
  this.jdomId = "#" + cleanId + "_text";
  this.classes = classes;
  this.resource = resource;
  this.loadAni = null;

  this.highlightAnnotationPositions = function () {
    var element = this;
    var text_map = {};
    jQuery(this.jdomId).find(".element_text p").each(function() {
      var p = jQuery(this);
      text_map[p.data().contextName] = p.html();
    });
    jQuery.ajax({
      url     : "/resource_index/element_annotations?"+chosenSearchClassesArgs(this.classes),
      data    : {
        elementid : this.id,
        element_text: text_map,
        acronym: this.resource
      },
      dataType: "json",
      type: "POST",
      success : function (data) {
        element.positions = data;
        element.highlight();
      }
    });
  }

  this.highlight = function () {
    var element = this;
    jQuery.each(this.positions, function(contextName, positions) {
      var context = jQuery(element.jdomId + " p[data-context-name=" + contextName + "]");
      if (positions.length > 0) {
        highlighter = new PositionHighlighter();
        // Replace the current text with highlighted version
        context.html(highlighter.highlightUsingPosition(context.html(), positions));
      }
    });
    jQuery("#" + this.cleanId + "_link").find(".highlighting").remove();
    if (this.loadAni !== null) {
      clearInterval(this.loadAni);
    }
  }
}

function PositionHighlighter() {
  this.offsetPositions = [];
  this.textToHighlight = "";

  this.highlightUsingPosition = function (text, positions) {
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
      highlightType = positions[j]['type'] || "direct";
      startPosition = positions[j]['from'];
      endPosition = positions[j]['to'];

      // Add the highlight opener
      this.addText("<span class='" + highlightType + "'>", startPosition, -1);
      // Add the highlight closer
      this.addText("</span>", endPosition, 0);
    }

    return this.textToHighlight;
  }

  this.updatePositions = function (start, added_count) {
    var offset_length = this.offsetPositions.length;
    for (var i = start; i <= offset_length; i++) {
      this.offsetPositions[i] += added_count;
    }
  }

  this.addText = function (textToAdd, position, offset) {
    this.textToHighlight = [this.textToHighlight.slice(0, this.getActualPosition(position) + offset), textToAdd, this.textToHighlight.slice(this.getActualPosition(position) + offset)].join('');
    this.updatePositions(position, textToAdd.length);
  }

  this.getActualPosition = function (position) {
    return position + this.offsetPositions[position];
  }
}

function currentOntologyIds() {
  var selectedOntIds = jQuery("#ontology_ontologyId").val();
  return selectedOntIds === null || selectedOntIds === "" ? ont_ids : selectedOntIds;
}

function currentOntologyAcronyms() {
  var ont_acronyms = new Array();
  var ontologies = currentOntologyIds();
  for(var i=0; i < ontologies.length; i++){
    ont_acronyms.push( ontologies[i].split('/').slice(-1)[0] );
  }
  return ont_acronyms;
}

function chosenSearchClasses() {
  var chosenClassesMap = {};
  // get selected option values, an array of combined_uri strings.
  var combined_uris = jQuery("#resource_index_classes").val();
  if (combined_uris === null){
    return chosenClassesMap;
  } else if (typeof combined_uris === "string"){
    combined_uris = combined_uris.split(); // coerce it to an Array
  }
  for(var i=0; i < combined_uris.length; i++){
    var combined_uri = combined_uris[i];
    var split_uris = uri_split(combined_uri);
    var chosen_ont_uri = split_uris[0];
    var chosen_cls_uri = split_uris[1];
    if(! chosenClassesMap.hasOwnProperty(chosen_ont_uri)) {
      chosenClassesMap[chosen_ont_uri] = new Array();
    }
    chosenClassesMap[chosen_ont_uri].push(chosen_cls_uri);
  }
  return chosenClassesMap;
}

function chosenSearchClassesArgs(chosenClassesMap) {
  if (chosenClassesMap === undefined){
    chosenClassesMap = chosenSearchClasses();
  }
  var chosenClassesURI = "";
  for (var ont_uri in chosenClassesMap) {
    var chosenClassArr = chosenClassesMap[ont_uri];
    chosenClassesURI += "classes[" + encodeURIComponent(ont_uri) + "]=";
    chosenClassesURI += encodeURIComponent(chosenClassArr.join(','));
    chosenClassesURI += "&";
  }
  return chosenClassesURI.slice(0,-1); // remove last '&'
}

;
"use strict";

// The count returned may not match the actual number of mappings
// To get around this, we re-calculate based on the mapping table size

function updateMappingCount() {
  var rows = jQuery("#concept_mappings_table tbody tr"), mappings_count = null;
  rows.first().children("td").each(function() {
    if (this.innerHTML.indexOf("no mappings") > -1) {
      mappings_count = 0;
    }
  });
  if (mappings_count === null) {
    mappings_count = rows.length;
  }
  jQuery("#mapping_count").html(mappings_count);
}

// Also in bp_create_mappings.js
function updateMappingDeletePermissions() {
  var mapping_permission_checkbox = jQuery("#delete_mappings_permission");
  if (mapping_permission_checkbox.length === 0){
    //console.error("Failed to select #delete_mappings_permission");
    jQuery("#delete_mappings_button").hide();
    jQuery(".delete_mappings_column").hide();
    jQuery("input[name='delete_mapping_checkbox']").prop('disabled', true);
  } else {
    // Ensure the permission checkbox is hidden.
    mapping_permission_checkbox.hide();
    if (mapping_permission_checkbox.is(':checked')) {
      jQuery("#delete_mappings_button").show();
      jQuery(".delete_mappings_column").show();
      jQuery("input[name='delete_mapping_checkbox']").prop('disabled', false);
    } else {
      jQuery("#delete_mappings_button").hide();
      jQuery(".delete_mappings_column").hide();
      jQuery("input[name='delete_mapping_checkbox']").prop('disabled', true);
    }
  }
  jQuery("input[name='delete_mapping_checkbox']").prop('checked', false);
}

jQuery(document).ready(function(){
  updateMappingCount();
  updateMappingDeletePermissions();
});

jQuery(document).bind("tree_changed", updateMappingCount);

// deleteMappings() is a callback that is called by "#delete_mappings_button" created in
// /app/views/mappings/_concept_mappings.html.haml
// The appearance of that button is controlled by updateMappingDeletePermissions(), which
// relies on @delete_mapping_permission in /app/views/mappings/_mapping_table.html.haml; which,
// in turn, is set by /app/controllers/application_controller.check_delete_mapping_permission()
function deleteMappings() {
  var mappingsToDelete = [], params;

  jQuery("#delete_mappings_error").html("");
  jQuery("#delete_mappings_spinner").show();

  jQuery("input[name='delete_mapping_checkbox']:checked").each(function(){
    mappingsToDelete.push(jQuery(this).val());
  });

  params = {
    mappingids: mappingsToDelete.join(","),
    _method: "delete",
    ontologyid: ontology_id,
    conceptid: concept_id
  };

  jQuery("#delete_mappings_error").html("");

  jQuery.ajax({
    url: "/mappings/mappingids", // routed to mappings_controller::destroy
    type: "POST",
    data: params,

    success: function(data){
      var rowId;
      jQuery("#delete_mappings_spinner").hide();
      for (map_id in data.success) {
        rowId = data.success[map_id].replace(/.*\//, "");
        jQuery("#" + rowId).html("").hide();
      }
      for (map_id in data.error) {
        jQuery("#delete_mappings_error").html("There was a problem deleting, please try again");
        rowId = data.error[map_id].replace(/.*\//, "");
        jQuery("#" + rowId).css("border", "red solid");
      }
      jQuery("#mapping_count").html(jQuery("#mapping_details tbody tr:visible").size());
      jQuery.bioportal.ont_pages["mappings"].retrieve_and_publish();
      updateMappingDeletePermissions();
    },

    error: function(){
      jQuery("#delete_mappings_spinner").hide();
      jQuery("#delete_mappings_error").html("There was a problem deleting, please try again");
    }
  });
}



;
(function(window,undefined) {
  // Abort it not right page
  var path = currentPathArray();
  if (path[0] !== "ontologies" || (path[0] === "ontologies" && path.length !== 2)) {
    return;
  }

  jQuery(document).data().bp.classesTab = {};

  // Called when the "Go" button on the Jump To form is clicked
  function jumpToValue(li){
    jQuery.blockUI({ message: '<h1><img src="/assets/jquery.simple.tree/spinner-d3e3944d4649450dee66a55c69eeced2d825b6ca1a349f72c75fd3780ae3f006.gif" /> Loading Class...</h1>', showOverlay: false });

    if( li == null ){
      // User performs a search
      var search = confirm("Class could not be found.\n\nPress OK to go to the Search page or Cancel to continue browsing");

      if(search){
        jQuery("#search_keyword").val(jQuery("#search_box").val());
        jQuery("#search_form").submit();
        return
      }
    }

    // Appropriate value selected
    if( !!li.extra ){
      var sValue = jQuery("#jump_to_concept_id").val();

      // TODO_REV: Handle flat ontologies (replace `if (false)` with `if @ontology.flat?`)
      if (false) {
        History.pushState({p:"classes", conceptid:sValue, suid:"jump_to", flat:true, label:li.extra[4]}, jQuery.bioportal.ont_pages["classes"].page_name + " | " + org_site, "?p=classes&conceptid=" + sValue);
      } else {
        document.location="/ontologies/"+jQuery(document).data().bp.ontology.acronym+"/?p=classes&conceptid="+encodeURIComponent(sValue)+"&jump_to_nav=true";
        jQuery.blockUI({ message: '<h1><img src="/assets/jquery.simple.tree/spinner-d3e3944d4649450dee66a55c69eeced2d825b6ca1a349f72c75fd3780ae3f006.gif" /> Loading Class...</h1>', showOverlay: false });
        return;
      }
    }
  }

  // Sets a hidden form value that records the concept id when a concept is chosen in the jump to
  // This is a workaround because the default autocomplete search method cannot distinguish between two
  // concepts that have the same preferred name but different ids.
  function jumpToSelect(li){
    jQuery("#jump_to_concept_id").val(li.extra[0]);
    jumpToValue(li);
  }

  // Formats the Jump To search results
  function formatItem(row) {
    var specials = new RegExp("[.*+?|()\\[\\]{}\\\\]", "g"); // .*+?|()[]{}\
    var keywords = jQuery("#search_box").val().trim().replace(specials, "\\$&").split(' ').join('|');
    var regex = new RegExp( '(' + keywords + ')', 'gi' );
    var matchType = "";
    if (typeof row[2] !== "undefined" && row[2] !== "") {
      matchType = " <span style='font-size:9px;color:blue;'>(" + row[2] + ")</span>";
    }

    if (row[0].match(regex) == null) {
      var contents = row[6].split("\t");
      var synonym = contents[0] || "";
      synonym = synonym.split(";");
      if (synonym !== "") {
        var matchSynonym = jQuery.grep(synonym, function(e){
          return e.match(regex) != null;
        });
        row[0] = row[0] + " (synonym: " + matchSynonym.join(" ") + ")";
      }
    }
    // Cleanup obsolete class tag before markup for search keywords.
    if(row[0].indexOf("[obsolete]") != -1) {
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

  jQuery(document).data().bp.classesTab.classes_init = function(){
    // Override the side of the bd_content div to avoid problems with
    // the window resizing, which can sometimes cause the right-hand content div to drop down
    var bd_content_width = jQuery("#ontology_content").width();
    jQuery("#bd_content").width(bd_content_width);

    // Split bar
    if (jQuery("#bd_content").find(".vsplitbar").length == 0) {
      jQuery("#bd_content").splitter({
        sizeLeft: 400,
        resizeToWidth: true,
        cookie: "vsplitbar_position"
      });
    }
  }

  // The tab system
  jQuery(".tab").live("click", function(){
    var tabId = jQuery(this).children("a:first").attr("href").replace("#", "");
    showClassesTab(tabId);
  });

  function showClassesTab(tabId) {
    // Get the target content area
    var target = document.getElementById(tabId + "_content");

    if (target != null) {
      jQuery(".tab_container").addClass("not_visible");
      jQuery(target).removeClass("not_visible");
      jQuery(".tab").removeClass("selected");
      jQuery("#" + tabId + "_top").addClass("selected");
      jQuery(document).trigger("classes_tab_visible");
    }

    jQuery(document).trigger("visualize_tab_change", [{tabType: tabId}]);
  }

  // Only show BioMixer when tab is clicked
  jQuery(document).live("visualize_tab_change", function(event, data){
    if (data.tabType == "visualization") {
      jQuery("#biomixer_iframe").attr("src", jQuery("#biomixer_iframe").data("src"));
    }
  });

  function callTab(tab_name, url) {
      if (getCache(getConcept() + tab_name) != null) {
            document.getElementById(tab_name + "_content").innerHTML=getCache(getConcept() + tab_name);
      } else {
        jQuery("#" + tab_name + "_content").html('<h1><img src="/assets/jquery.simple.tree/spinner-d3e3944d4649450dee66a55c69eeced2d825b6ca1a349f72c75fd3780ae3f006.gif" /> Loading Resources...</h1>');
        jQuery.get(url.replace("@ontology@",getOntology()).replace("@concept@",encodeURIComponent(getConcept())),function(data){
          jQuery("#" + tab_name + "_content").html(data);
          jQuery("#" + tab_name + "_content").append(
            jQuery("<input type='hidden'/>")
              .attr("id", "resource_index_classes")
              .val([jQuery(document.body).data("ont_id")+"/"+encodeURIComponent(getConcept())])
          );
          setCache(getConcept() + tab_name,data);
          jQuery.unblockUI();
          tb_init('a.thickbox, area.thickbox, input.thickbox');
        });
      }
  }

  jQuery(document).data().bp.classesTab.search_box_init = function(){
    if (jQuery("#search_box").bioportal_autocomplete) {
      jQuery("#search_box").bioportal_autocomplete("/search/json_search/"+jQuery(document).data().bp.ontology.acronym, {
        extraParams: { objecttypes: "class" },
        width: "400px",
        selectFirst: true,
        lineSeparator: "~!~",
        matchSubset: 0,
        minChars: 1,
        maxItemsToShow: 25,
        onFindValue: jumpToValue,
        onItemSelect: jumpToSelect,
        formatItem: formatItem
      });
    }
  }

  jQuery(document).ready(function(){
    // Tab auto-select based on parameter "t"
    var url, urlFragment, paramsList, params = {}, splitParam, content;
    url = document.URL;

    if (url.indexOf("?") > 0) {
      urlFragment = url.split("?");
      paramsList = urlFragment[1].split("&");

      for (param in paramsList) {
        splitParam = paramsList[param].split("=");

        if (splitParam.length > 1)
          params[splitParam[0]] = splitParam[1].split("#")[0];
      }

      if (params !== "undefined" && "t" in params) {
        showClassesTab(params["t"]);
      }
    }

    // Javascript for the permalink box
    jQuery("#close_permalink").live("click", function(){
      jQuery("#purl_link_container").hide();
    });

    jQuery("#class_permalink").live("click", function(e){
      e.preventDefault();
      jQuery("#purl_link_container").show();
    });

    jQuery("#purl_input").live("focus", function(){
      this.select();
    });
  });
})(window);
/**
 * Created by mdorf on 3/27/15.
 */

var DUMMY_ONTOLOGY = "DUMMY_ONT";
var problemOnly = true;

function toggleShow(val) {
  problemOnly = val;
}

function millisToMinutesAndSeconds(millis) {
  var minutes = Math.floor(millis / 60000);
  var seconds = ((millis % 60000) / 1000).toFixed(0);
  return minutes + " minutes " + seconds + " seconds";
}

var AjaxAction = function(httpMethod, operation, path, isLongOperation, params) {
  params = params || {};
  this.httpMethod = httpMethod;
  this.operation = operation;
  this.path = path;
  this.isLongOperation = isLongOperation;
  this.ontologies = [DUMMY_ONTOLOGY];

  if (params["ontologies"]) {
    this.ontologies = params["ontologies"].split(",");
    delete params["ontologies"];
  }
  this.params = params;
  this.confirmMsg = "Are you sure?";
};

AjaxAction.prototype.setConfirmMsg = function(msg) {
  this.confirmMsg = msg;
};

AjaxAction.prototype.clearStatusMessages = function() {
  jQuery("#progress_message").hide();
  jQuery("#success_message").hide();
  jQuery("#error_message").hide();
  jQuery("#progress_message").html("");
  jQuery("#success_message").html("");
  jQuery("#error_message").html("");
};

AjaxAction.prototype.showProgressMessage = function() {
  this.clearStatusMessages();
  var msg = "Performing " + this.operation;

  if (this.ontologies[0] !== DUMMY_ONTOLOGY) {
    msg += " for " + this.ontologies.join(", ");
  }
  jQuery("#progress_message").text(msg).html();
  jQuery("#progress_message").show();
};

AjaxAction.prototype.showStatusMessages = function(success, errors, isAppendMode) {
  _showStatusMessages(success, errors, isAppendMode);
};

AjaxAction.prototype.getSelectedOntologiesForDisplay = function() {
  var msg = '';

  if (this.ontologies.length > 0) {
    var ontMsg = this.ontologies.join(", ");
    msg = "<br style='margin-bottom:5px;'/><span style='color:red;font-weight:bold;'>" + ontMsg + "</span><br/>";
  }

  return msg;
};

AjaxAction.prototype._ajaxCall = function() {
  var self = this;
  var errors = [];
  var success = [];
  var promises = [];
  var params = jQuery.extend(true, {}, self.params);
  self.showProgressMessage();

  // using javascript closure for passing index to asynchronous calls
  jQuery.each(self.ontologies, function(index, ontology) {
    if (ontology != DUMMY_ONTOLOGY) {
      params["ontologies"] = ontology;
    }
    var deferredObj = jQuery.Deferred();
    if (!self.isLongOperation) {
      deferredObj.resolve();
    }
    promises.push(deferredObj);

    var req = jQuery.ajax({
      method: self.httpMethod,
      url: "/admin/" + self.path,
      data: params,
      dataType: "json",
      success: function(data, msg) {
        var reg = /\s*,\s*/g;

        if (data.errors) {
          var err = data.errors.replace(reg, ',');
          errors.push.apply(errors, err.split(","));
        }

        if (data.success) {
          self.onSuccessAction(data, ontology, deferredObj);

          if (data.success) {
            var suc = data.success.replace(reg, ',');
            success.push.apply(success, suc.split(","));
          }
        }
        self.showStatusMessages(success, errors, false);
      },
      error: function(request, textStatus, errorThrown) {
        errors.push(request.status + ": " + errorThrown);
        self.showStatusMessages(success, errors, false);
      },
      complete: function(request, textStatus) {
        if (ontology != DUMMY_ONTOLOGY && !self.isLongOperation) {
          var jQueryRow = jQuery("#tr_" + ontology);
          jQueryRow.removeClass('selected');
        }
      }
    });
    promises.push(req);
  });

  // hide progress message and deselect rows after ALL operations have completed
  jQuery.when.apply(null, promises).always(function() {
    jQuery("#progress_message").hide();
    jQuery("#progress_message").html("");
  });
};

AjaxAction.prototype.ajaxCall = function() {
  var self = this;

  if (self.ontologies.length === 0) {
    alertify.alert("Please select at least one ontology from the table to perform action on.<br/>To select/de-select ontologies, simply click anywhere in the ontology row.");
    return;
  }

  if (self.confirmMsg) {
    alertify.confirm(self.confirmMsg, function(e) {
      if (e) {
        self._ajaxCall();
      }
    });
  } else {
    self._ajaxCall();
  }
};

AjaxAction.prototype.onSuccessAction = function(data, ontology, deferredObj) {
  var self = this;
  if (!self.isLongOperation) {
    return;
  }
  var processId = data["process_id"];
  var errors = [];
  var success = [];
  var done = [];
  data.success = '';
  var start = new Date().getTime();
  var timer = setInterval(function() {
    jQuery.ajax({
      url: determineHTTPS(BP_CONFIG.rest_url) + "/admin/ontologies_report/" + processId,
      data: {
        apikey: jQuery(document).data().bp.config.apikey,
        userapikey: jQuery(document).data().bp.config.userapikey,
        format: "jsonp"
      },
      dataType: "jsonp",
      timeout: 30000,
      success: function(data) {
        if (typeof data === 'string') {
          // still processing
          jQuery("#progress_message").append(".");
        } else {
          if (jQuery.inArray(ontology, done) != -1) {
            return;
          }
          done.push(ontology);
          clearInterval(timer);

          // done processing, show errors or process data
          if (data.errors && data.errors.length > 0) {
            errors[0] = data.errors[0];
          } else {
            var end = new Date().getTime();
            var tm = end - start;

            if (ontology === DUMMY_ONTOLOGY) {
              success[0] = self.operation + " completed in " + millisToMinutesAndSeconds(tm);
            } else {
              //var msgStr = self.ontologies.join(", ");
              success[0] = self.operation + " for " + ontology + " completed in " + millisToMinutesAndSeconds(tm);
            }
            self.onSuccessActionLongOperation(data, ontology);
          }
          deferredObj.resolve();
          self.showStatusMessages(success, errors, true);
        }
      },
      error: function(request, textStatus, errorThrown) {
        if (jQuery.inArray(ontology, done) != -1) {
          return;
        }
        done.push(ontology);
        clearInterval(timer);
        errors.push(request.status + ": " + errorThrown);
        deferredObj.reject();
        self.showStatusMessages(success, errors, true);
      }
    });
  }, 5000);
};

AjaxAction.prototype.onSuccessActionLongOperation = function(data, ontology) {
  // nothing to do by default
};

AjaxAction.prototype.setSelectedOntologies = function() {
  var acronyms = '';
  var ontTable = jQuery('#adminOntologies').DataTable();
  ontTable.rows('.selected').every(function() {
    var trId = this.node().id;
    acronyms += trId.substring("tr_".length) + ",";
  });

  if (acronyms.length) {
    this.ontologies = acronyms.slice(0, -1).split(",");
  } else {
    this.ontologies = [];
  }
};

AjaxAction.prototype.act = function() {
  alert("AjaxAction.act is not implemented");
};

function ResetMemcacheConnection() {
  AjaxAction.call(this, "POST", "MEMCACHE CONNECTION RESET", "resetcache", false);
  this.setConfirmMsg('');
}

ResetMemcacheConnection.prototype = Object.create(AjaxAction.prototype);
ResetMemcacheConnection.prototype.constructor = ResetMemcacheConnection;

ResetMemcacheConnection.act = function() {
  new ResetMemcacheConnection().ajaxCall();
};

function FlushMemcache() {
  AjaxAction.call(this, "POST", "FLUSHING OF MEMCACHE", "clearcache", false);
  this.setConfirmMsg('');
}

FlushMemcache.prototype = Object.create(AjaxAction.prototype);
FlushMemcache.prototype.constructor = FlushMemcache;

FlushMemcache.act = function() {
  new FlushMemcache().ajaxCall();
};

function DeleteSubmission(ontology, submissionId) {
  AjaxAction.call(this, "DELETE", "SUBMISSION DELETION", "ontologies/" + ontology + "/submissions/" + submissionId, false, {ontologies: ontology});
  this.submissionId = submissionId;
  this.setConfirmMsg("Are you sure you want to delete submission <span style='color:red;font-weight:bold;'>" + submissionId + "</span> for ontology <span style='color:red;font-weight:bold;'>" + ontology + "</span>?<br/><b>This action CAN NOT be undone!!!</b>");
}

DeleteSubmission.prototype = Object.create(AjaxAction.prototype);
DeleteSubmission.prototype.constructor = DeleteSubmission;

DeleteSubmission.prototype.onSuccessAction = function(data, ontology, deferredObj) {
  jQuery.facebox({
    ajax: BP_CONFIG.ui_url + "/admin/ontologies/" + ontology + "/submissions?time=" + new Date().getTime()
  });
};

DeleteSubmission.act = function(ontology, submissionId) {
  new DeleteSubmission(ontology, submissionId).ajaxCall();
};

function RefreshReport() {
  AjaxAction.call(this, "POST", "REFRESH OF ONTOLOGIES REPORT", "refresh_ontologies_report", true);
  var msg = "Refreshing this report takes a while...<br/>Are you sure you're ready for some coffee time?";
  this.setSelectedOntologies();

  if (this.ontologies.length > 0) {
    msg = "Ready to refresh report for ontologies:" + this.getSelectedOntologiesForDisplay() + "Proceed?";
  } else {
    this.ontologies = [DUMMY_ONTOLOGY];
  }
  this.setConfirmMsg(msg);
}

RefreshReport.prototype = Object.create(AjaxAction.prototype);
RefreshReport.prototype.constructor = RefreshReport;

RefreshReport.prototype.onSuccessActionLongOperation = function(data, ontology) {
  displayOntologies(data, ontology);
};

RefreshReport.act = function() {
  new RefreshReport().ajaxCall();
};

function DeleteOntologies() {
  AjaxAction.call(this, "DELETE", "ONTOLOGY DELETION", "ontologies", false);
  this.setSelectedOntologies();
  this.setConfirmMsg("You are about to delete the following ontologies:" + this.getSelectedOntologiesForDisplay() + "<b>This action CAN NOT be undone!!! Are you sure?</b>");
}

DeleteOntologies.prototype = Object.create(AjaxAction.prototype);
DeleteOntologies.prototype.constructor = DeleteOntologies;
DeleteOntologies.prototype.onSuccessAction = function(data, ontology, deferredObj) {
  var ontTable = jQuery('#adminOntologies').DataTable();
  // remove ontology row from the table
  ontTable.row(jQuery("#tr_" + ontology)).remove().draw();
};

DeleteOntologies.act = function() {
  new DeleteOntologies().ajaxCall();
};

function ProcessOntologies(action) {
  var actions = {
    all: "FULL ONTOLOGY RE-PROCESSING",
    process_annotator: "PROCESSING OF ONTOLOGY FOR ANNOTATOR",
    diff: "CALCULATION OF ONTOLOGY DIFFS",
    index_search: "PROCESSING OF ONTOLOGY FOR SEARCH",
    run_metrics: "CALCULATION OF ONTOLOGY METRICS"
  };
  AjaxAction.call(this, "PUT", actions[action], "ontologies", false, {actions: action});
  this.setSelectedOntologies();
  this.setConfirmMsg("You are about to perform " + actions[action] + " on the following ontologies:" + this.getSelectedOntologiesForDisplay() + "The ontologies will be added to the queue and processed on the next cron job execution.<br style='margin:10px 0;'/><b>Should I proceed?</b>");
}

ProcessOntologies.prototype = Object.create(AjaxAction.prototype);
ProcessOntologies.prototype.constructor = ProcessOntologies;

ProcessOntologies.act = function(action) {
  new ProcessOntologies(action).ajaxCall();
};

function performActionOnOntologies() {
  var action = jQuery('#admin_action').val();

  if (!action) {
    alertify.alert("Please choose an action to perform on the selected ontologies.");
    return;
  }

  switch(action) {
    case "delete":
      DeleteOntologies.act();
      break;
    default:
      ProcessOntologies.act(action);
      break;
  }
}

function populateOntologyRows(data) {
  var ontologies = data.ontologies;
  var allRows = [];
  var hideFields = ["date_updated", "errErrorStatus", "errMissingStatus", "problem", "logFilePath"];

  for (var acronym in ontologies) {
    var errorMessages = [];
    var ontology = ontologies[acronym];
    var ontLink = "<a id='link_submissions_" + acronym + "' href='javascript:;' onclick='showSubmissions(event, \"" + acronym + "\")' style='" + (ontology["problem"] === true ? "color:red" : "") + "'>" + acronym + "</a>";
    var bpLinks = '';
    var dateUpdated = ontology["date_updated"];

    if (ontology["logFilePath"] != '') {
      bpLinks += "<a href='" + BP_CONFIG.ui_url + "/admin/ontologies/" + acronym + "/log' target='_blank'>Log</a> | ";
    }
    bpLinks += "<a href='" + BP_CONFIG.rest_url + "/ontologies/" + acronym + "' target='_blank'>REST</a> | <a href='" + BP_CONFIG.ui_url + "/ontologies/" + acronym + "' target='_blank'>BioPortal</a>";
    var errStatus = ontology["errErrorStatus"] ? ontology["errErrorStatus"].join(", ") : '';
    var missingStatus = ontology["errMissingStatus"] ? ontology["errMissingStatus"].join(", ") : '';

    for (var k in ontology) {
      if (jQuery.inArray(k, hideFields) === -1) {
        errorMessages.push(ontology[k]);
      }
    }
    var row = [ontLink, dateUpdated, bpLinks, errStatus, missingStatus, errorMessages.join("<br/>"), ontology["problem"]];
    allRows.push(row);
  }
  return allRows;
}

function isDateGeneratedSet(data) {
  var dateRe = /^\d{2}\/\d{2}\/\d{4}\s\d{2}:\d{2}\w{2}$/i;
  return dateRe.test(data.date_generated);
}

function setDateGenerated(data) {
  var buttonText = "Generate";

  if (isDateGeneratedSet(data)) {
    buttonText = "Refresh";
  }
  jQuery(".date_generated").text(data.date_generated).html();
  jQuery(".date_generated_button").text(buttonText).html();
}

function _showStatusMessages(success, errors, isAppendMode) {
  if (success.length > 0) {
    if (isAppendMode) {
      var appendStr = (jQuery.trim(jQuery('#success_message').html()).length) ? ", " : "";
      jQuery("#success_message").append(appendStr + success.join(", ")).html();
    } else {
      jQuery("#success_message").text(success.join(", ")).html();
    }
    jQuery("#success_message").show();
  }

  if (errors.length > 0) {
    if (isAppendMode) {
      var appendStr = (jQuery.trim(jQuery('#error_message').html()).length) ? ", " : "";
      jQuery("#error_message").append(appendStr + errors.join(", ")).html();
    } else {
      jQuery("#error_message").text(errors.join(", ")).html();
    }
    jQuery("#error_message").show();
  }
}

function displayOntologies(data, ontology) {
  var ontTable = null;

  if (jQuery.fn.dataTable.isDataTable('#adminOntologies')) {
    ontTable = jQuery('#adminOntologies').DataTable();

    if (ontology === DUMMY_ONTOLOGY) {
      // refreshing entire table
      allRows = populateOntologyRows(data);
      ontTable.clear();
      ontTable.rows.add(allRows);
      ontTable.draw();
      setDateGenerated(data);
    } else {
      // refreshing individual row
      var jQueryRow = jQuery("#tr_" + ontology);
      var row = ontTable.row(jQueryRow);
      var rowData = {ontologies: {}};
      rowData["ontologies"][ontology] = data["ontologies"][ontology];
      allRows = populateOntologyRows(rowData);
      row.data(allRows[0]);
      row.invalidate().draw();
      jQueryRow.removeClass('selected');
    }
  } else {
    ontTable = jQuery("#adminOntologies").DataTable({
      "ajax": {
        "url": BP_CONFIG.ui_url + "/admin/ontologies_report",
        "contentType": "application/json",
        "dataSrc": function (json) {
          return populateOntologyRows(json);
        }
      },
      "rowCallback": function(row, data, index) {
        var acronym = jQuery('td:first', row).text();
        jQuery(row).attr("id", "tr_" + acronym);

        if (data[data.length - 1] === true) {
          jQuery(row).addClass("problem");
        }
      },
      "initComplete": function(settings, json) {
        if (json.errors && isDateGeneratedSet(data)) {
          _showStatusMessages([], [json.errors], false);
        }
        setDateGenerated(json);
        // Keep header at top of table even when scrolling
        new jQuery.fn.dataTable.FixedHeader(ontTable);
      },
      "columnDefs": [
        {
          "targets": 0,
          "searchable": true,
          "title": "Acronym",
          "width": "11%"
        },

        {
          "targets": 1,
          "searchable": true,
          "title": "Report Date",
          "width": "11%"
        },
        {
          "targets": 2,
          "searchable": false,
          "orderable": false,
          "title": "URL",
          "width": "11%"
        },
        {
          "targets": 3,
          "searchable": true,
          "title": "Error Status",
          "width": "12%"
        },
        {
          "targets": 4,
          "searchable": true,
          "title": "Missing Status",
          "width": "12%"
        },
        {
          "targets": 5,
          "searchable": true,
          "title": "Issues",
          "width": "43%"
        },
        {
          "targets": 6,
          "searchable": true,
          "visible": false
        }
      ],
      "autoWidth": false,
      "lengthChange": false,
      "searching": true,
      "language": {
        "search": "Filter: ",
        "emptyTable": "No ontologies available"
      },
      "info": true,
      "paging": true,
      "pageLength": 100,
      "ordering": true,
      "stripeClasses": ["", "alt"],
      "dom": '<"ontology_nav"><"top"fi>rtip'
    });
  }
  return ontTable;
}

function showSubmissions(ev, acronym) {
  ev.preventDefault();
  jQuery.facebox({ ajax: BP_CONFIG.ui_url + "/admin/ontologies/" + acronym + "/submissions" });
}

jQuery(document).ready(function() {
  // display ontologies table on load
  displayOntologies({}, DUMMY_ONTOLOGY);

  // make sure facebox window is empty before populating it
  // otherwise ajax requests stack up and you see more than
  // one ontology's submissions
  jQuery(document).bind('beforeReveal.facebox', function() {
    jQuery("#facebox .content").empty();
  });

  // remove hidden divs for submissions of previously
  // clicked ontologies
  jQuery(document).bind('reveal.facebox', function() {
    jQuery('div[id=facebox]:hidden').remove();
  });

  // convert facebox window into a modal mode
  jQuery(document).bind('loading.facebox', function() {
    jQuery(document).unbind('keydown.facebox');
    jQuery('#facebox_overlay').unbind('click');
  });

  jQuery("div.ontology_nav").html('<span class="toggle-row-display">View Ontologies:&nbsp;&nbsp;&nbsp;&nbsp;<a id="show_all_ontologies_action" href="javascript:;"">All</a> | <a id="show_problem_only_ontologies_action" href="javascript:;">Problem Only</a></span><span style="padding-left:30px;">Apply to Selected Rows:&nbsp;&nbsp;&nbsp;&nbsp;<select id="admin_action" name="admin_action"><option value="">Please Select</option><option value="delete">Delete</option><option value="all">Process</option><option value="process_annotator">Annotate</option><option value="diff">Diff</option><option value="index_search">Index</option><option value="run_metrics">Metrics</option></select>&nbsp;&nbsp;&nbsp;&nbsp;<a class="link_button ui-button ui-widget ui-state-default ui-corner-all ui-button-text-only" href="javascript:;" id="admin_action_submit"><span class="ui-button-text">Go</span></a></span>');

  // toggle between all and problem ontologies
  jQuery.fn.dataTable.ext.search.push(
    function(settings, data, dataIndex) {
      var row = settings.aoData[dataIndex].nTr;
      if (!problemOnly || row.classList.contains("problem") || data[data.length - 1] === "true") {
        return true;
      }
      return false;
    }
  );

  // for toggling between all and problem ontologies
  jQuery(".toggle-row-display a").live("click", function() {
    jQuery("#adminOntologies").DataTable().draw();
    return false;
  });

  // allow selecting of rows
  jQuery('#adminOntologies tbody').on('click', 'tr', function() {
    jQuery(this).toggleClass('selected');
  });

  // BUTTON onclick actions ---------------------------------------

  // onclick action for "Go" button for performing an action on a set of ontologies
  jQuery("#admin_action_submit").click(function() {
    performActionOnOntologies();
  });

  // onclick action for "Flush Memcache" button
  jQuery("#flush_memcache_action").click(function() {
    FlushMemcache.act();
  });

  // onclick action for "Reset Memcache Connection" button
  jQuery("#reset_memcache_connection_action").click(function() {
    ResetMemcacheConnection.act();
  });

  // onclick action for "Show All Ontologies" link
  jQuery("#show_all_ontologies_action").click(function() {
    toggleShow(false);
  });

  // onclick action for "Show Problem Only Ontologies" link
  jQuery("#show_problem_only_ontologies_action").click(function() {
    toggleShow(true);
  });

  // onclick action for "Refresh Report" link
  jQuery("#refresh_report_action").click(function() {
    RefreshReport.act();
  });

  // end: BUTTON onclick actions -----------------------------------
});
// Namespace for global variables and functions
var rec = { }
rec.maxInputWords = 500;

rec.showOrHideAdvancedOptions = function() {
    $("#advancedOptions").toggle();
}

rec.insertInput = function() {
    rec.prepareForRealInput();
    if ($("#radioItText").is(":checked")) {
        rec.insertSampleText()
    }
    else {
        rec.insertSampleKeywords()
    }
}

rec.defaultMessage = true;
rec.prepareForRealInput = function() {
    $("#inputText").removeClass()
    rec.emptyInput = false;
    if (rec.defaultMessage == true) {
        $("#inputText").val('');
        rec.defaultMessage = false;
    }
}

rec.enableEdition = function() {
    $("#inputText").show();
    $("#inputTextHighlighted").hide();
    $("#resultsHeader").empty();
    $("#results").empty();
    $("#editButton").hide();
    $("#recommenderButton").show();
    $("input[name=input_type]").attr("disabled",false);
}

rec.insertSampleText = function() {
    rec.enableEdition();
    var text = 'Primary treatment of DCIS now includes 3 options: lumpectomy without lymph node surgery plus whole breast radiation (category 1); total mastectomy with or without sentinel node biopsy with or without reconstruction (category 2A); lumpectomy without lymph node surgery without radiation (category 2B). Workup for patients with clinical stage l, llA, llB, or T3,N1,M0 disease was reorganized to distinguish optional additional studies from those recommended for all of these patients. Recommendation for locoregional treatment for patients with clinical stage l, llA, llB, or T3,N1,M0 disease with 1-3 positive axillary nodes following total mastectomy was changed from "Consider" to "Strongly consider" postmastectomy radiation therapy. ';
    jQuery("#inputText").focus();
    jQuery("#inputText").val(text);
    $(".notTextError").hide();
    $("#radioItText").prop("checked", true);
}

rec.insertSampleKeywords = function() {
    rec.enableEdition();
    var text = "Backpain, White blood cell, Carcinoma, Cavity of stomach, Ductal Carcinoma in Situ, Adjuvant chemotherapy, Axillary lymph node staging, Mastectomy, tamoxifen, serotonin reuptake inhibitors, Invasive Breast Cancer, hormone receptor positive breast cancer, ovarian ablation, premenopausal women, surgical management, biopsy of breast tumor, Fine needle aspiration, entinel lymph node, breast preservation, adjuvant radiation therapy, prechemotherapy, Inflammatory Breast Cancer, ovarian failure, Bone scan, lumpectomy, brain metastases, pericardial effusion, aromatase inhibitor, postmenopausal, Palliative care, Guidelines, Stage IV breast cancer disease, Trastuzumab, Breast MRI examination";
    jQuery("#inputText").focus();
    jQuery("#inputText").val(text);
    $(".notTextError").hide();
    $("#radioItKeywords").prop("checked", true);
}

rec.colors = ["#234979" , "#cc0000", "#339900", "#ff9900"];
rec.getHighlightedTerms = function(data, rowNumber) {
    var inputText = document.getElementById("inputText").value;
    var newText = '';
    var lastPosition = 0;
    var ontologyIds = [ ];
    for (var k = 0; k < data[rowNumber].ontologies.length; k++) {
        ontologyIds[k] = data[rowNumber].ontologies[k]["@id"];
    }
    for (var j = 0; j < data[rowNumber].coverageResult.annotations.length; j++) {
        var from = data[rowNumber].coverageResult.annotations[j].from-1;
        var to = data[rowNumber].coverageResult.annotations[j].to;
        var link = data[rowNumber].coverageResult.annotations[j].annotatedClass.links.ui;
        var term = inputText.substring(from, to);
        // Color selection - Single ontology
        if (data[rowNumber].ontologies.length == 1) {
            var color = rec.colors[0];
        }
        // Color selection - Set of ontologies
        else {
            var ontologyId = data[rowNumber].coverageResult.annotations[j].annotatedClass.links.ontology;
            var index = ontologyIds.indexOf(ontologyId);
            var color = rec.colors[index];
        }

        var replacement = '<a style="font-weight: bold; color:' + color + '" target="_blank" href=' + link + '>' + term + '</a>';

        if (from>lastPosition) {
            newText+=inputText.substring(lastPosition, from);
        }
        newText += replacement;
        lastPosition = to;
    }

    if (lastPosition < inputText.length) {
        newText += inputText.substring(lastPosition, inputText.length);
    }
    return newText;
}

rec.hideErrorMessages = function() {
    $(".generalError").hide();
    $(".inputSizeError").hide();
    $(".invalidWeightsError").hide();
    $(".rangeWeightsError").hide();
    $(".sumWeightsError").hide();
    $(".maxOntologiesError").hide();
    $(".invalidMaxOntError").hide();
    $(".notTextError").hide();
    $("#noResults").hide();
    $("#noResultsSets").hide();
}

rec.getRecommendations = function() {
    rec.hideErrorMessages();
    var errors = false;
    // Checks if the input text field is empty
    if (($("#inputText").val().length == 0) || (rec.emptyInput==true))  {
        $(".notTextError").show();
        errors = true;
    }
    // Checks the input size using a basic word counter
    if ($("#inputText").val().split(' ').length > rec.maxInputWords) {
        $(".inputSizeError").show();
        errors = true;
    }
    var wc = parseFloat($("#input_wc").val());
    var wa = parseFloat($("#input_wa").val());
    var wd = parseFloat($("#input_wd").val());
    var ws = parseFloat($("#input_ws").val());
    // Parameters validation
    if (isNaN(wc)||isNaN(wa)||isNaN(wd)||isNaN(ws)) {
        $(".invalidWeightsError").show();
        errors = true;
    }

    if ((wc < 0)||(wa < 0)||(wd < 0)||(ws < 0)) {
        $(".rangeWeightsError").show();
        errors = true;
    }

    if (wc + wa + wd + ws <= 0) {
        $(".sumWeightsError").show();
        errors = true;
    }

    var maxOntologies = parseInt($('#input_max_ontologies').val());

    if (isNaN(maxOntologies)||(maxOntologies%1!=0)) {
        $(".invalidMaxOntError").show();
        errors = true;
    }

    if ((maxOntologies < 2)||(maxOntologies > 4)) {
        $(".maxOntologiesError").show();
        errors = true;
    }

    if (!errors) {
        rec.hideErrorMessages();
        $(".recommenderSpinner").show();
        var params = {};
        var ont_select = jQuery("#ontology_ontologyId");
        params.input = $("#inputText").val();
        params.ontologies = (ont_select.val() === null) ? [] : ont_select.val();
        // Input type (text or keywords)
        if ($("#radioItText").is(":checked"))
            params.input_type = 1; //text
        else
            params.input_type = 2; //keywords
        // Output type (ontologies or ontology sets)
        if ($("#radioOtSingle").is(":checked"))
            params.output_type = 1; //ontologies
        else
            params.output_type = 2; //ontology sets
        // Weights
        params.wc = $("#input_wc").val();
        params.wa = $("#input_wa").val();
        params.wd = $("#input_wd").val();
        params.ws = $("#input_ws").val();
        // Maximum number of ontologies per set (only for the "ontology sets" output)
        params.max_elements_set = $('#input_max_ontologies').val();
        $.ajax({
            type: "POST",
            url: "/recommender",
            data: params,
            dataType: "json",
            success: function(data) {
                $('.recommenderSpinner').hide();
                if (data) {
                    if (data.length > 0) {
                        $("#results").empty();
                        $("#resultsHeader").text("Recommended ontologies");

                        if (params.output_type == 1) {
                            var ontologyHeader = "Ontology";
                        }
                        else {
                            ontologyHeader = "Ontologies";
                        }
                        var table = $('<table id="recommendations" class="zebra" border="1" style="display: inline-block; padding:0px" ></table>'); //create table
                        var header = $("<tr><th>POS.</th>"
                        + "<th>" + ontologyHeader +"</th>"
                        + "<th>Final score</th>"
                        + "<th>Coverage <br>score</th>"
                        + "<th>Acceptance <br>score</th>"
                        + "<th>Detail <br>score</th>"
                        + "<th>Specialization <br>score</th>"
                        + "<th>Annotations</th>"
                        + "<th>Highlight <br>annotations</th>"
                        + "</th>");
                        table.append(header);

                        for (var i = 0; i < data.length; i++) {
                            var position = i + 1;
                            // Terms covered
                            var terms = '';
                            for (var j = 0; j < data[i].coverageResult.annotations.length; j++) {
                                terms += ('<a target="_blank" href=' + data[i].coverageResult.annotations[j].annotatedClass.links.ui + '>' + data[i].coverageResult.annotations[j].text + '</a>, ');
                            }
                            // Remove last comma and white
                            terms = terms.substring(0, terms.length - 2);

                            var finalScore = data[i].evaluationScore * 100;
                            var coverageScore = data[i].coverageResult.normalizedScore * 100;
                            var acceptanceScore = data[i].acceptanceResult.normalizedScore * 100;
                            var detailScore = data[i].detailResult.normalizedScore * 100;
                            var specializationScore = data[i].specializationResult.normalizedScore * 100;

                            var row = '<tr class="row"><td>' + position + '</td><td>';

                            $.each(data[i].ontologies, function (j, item) {
                                var ontologyLinkStyle = 1
                                if (params.output_type == 2) {
                                    ontologyLinkStyle = 'style="color: ' + rec.colors[j] + '"';
                                }
                                row += '<a ' + ontologyLinkStyle + /*'title= "' + data[i].ontologies[j].name +*/ '" target="_blank" href=' + data[i].ontologies[j].links.ui + '>'
                                + data[i].ontologies[j].acronym + '</a><br />'});

                            row += "</td>";
                            row += '<td><div style="width:120px"><div style="text-align:left;width:' + finalScore.toFixed(0) + '%;color:#ccc;background-color:#234979;border-style:solid;border-width:1px;border-color:#234979">' + finalScore.toFixed(1) + '</div></div>' + '</td>'
                            + '<td><div style="width:120px"><div style="text-align:left;width:' + coverageScore.toFixed(0) + '%;background-color:#8cabd6;border-style:solid;border-width:1px;border-color:#3e76b6">' + coverageScore.toFixed(1) + '</div></div>' + '</td>'
                            + '<td><div style="width:120px"><div style="text-align:left;width:' + acceptanceScore.toFixed(0) + '%;background-color:#8cabd6;border-style:solid;border-width:1px;border-color:#3e76b6">' + acceptanceScore.toFixed(1) + '</div></div>' + '</td>'
                            + '<td><div style="width:120px"><div style="text-align:left;width:' + detailScore.toFixed(0) + '%;background-color:#8cabd6;border-style:solid;border-width:1px;border-color:#3e76b6">' + detailScore.toFixed(1) + '</div></div>' + '</td>'
                            + '<td><div style="width:120px"><div style="text-align:left;width:' + specializationScore.toFixed(0) + '%;background-color:#8cabd6;border-style:solid;border-width:1px;border-color:#3e76b6">' + specializationScore.toFixed(1) + '</div></div>' + '</td>'
                            + '<td>' + data[i].coverageResult.annotations.length + '</td>'
                            + '<td>' + '<div style="text-align:center"><input style="vertical-align:middle" id="chk' + i + '" type="checkbox"/></div>'
                            + '</tr>';
                            table.append(row); // Append row to table
                        }
                        $("#results").append(table); // Append table to your dom wherever you want

                        // Hide get recommentations button
                        $("#recommenderButton").hide();
                        // Show edit button
                        $("#editButton").show();

                        // Check first checkbox and highlight annotations
                        rec.checkFirst(data);

                        // Checkboxes listeners
                        for (var i = 0; i < data.length; i++) {
                            $("#chk" + i).click( function(){
                                var $this = $(this);
                                var $rowNumber = $this.attr("id").substring(3);
                                if ($this.is(':checked')) {
                                    // Deselect all the rest checkboxes
                                    for (var j = 0; j < data.length; j++) {
                                        if (j!=$rowNumber) {
                                            $("#chk" + j).prop('checked', false);
                                            $("#chk" + j).parents(".row:first").css("background-color", "white");
                                        }
                                    }
                                    // Terms covered
                                    var terms = rec.getHighlightedTerms(data, $rowNumber);
                                    $("#inputTextHighlighted").empty();
                                    $("#inputTextHighlighted").append(terms);
                                    $("#inputTextHighlighted").show();
                                    $(this).parents(".row:first").css("background-color", "#e2ebf0");
                                }
                                // Avoids to uncheck the selected row
                                else {
                                    $this.prop('checked', true);
                                }
                            });
                        }
                        // Edit input
                        $("#editButton").click( function(){
                            rec.enableEdition()
                        });
                    }
                    else { // No results
                        if ($("#radioOtSets").is(":checked"))
                            $("#noResultsSets").show();
                        else
                            $("#noResults").show();
                    }
                }
            },
            error: function(errorData) {
                $(".recommenderSpinner").hide();
                $(".generalError").show();
                console.log("error", errorData);
            }
        });
    }
}

// Check first checkbox and highlight annotations
rec.checkFirst = function(data) {
    var terms = rec.getHighlightedTerms(data, 0);
    $("#chk0").prop("checked", true);
    $("#inputText").hide();
    $("#inputTextHighlighted").empty();
    $("#inputTextHighlighted").append(terms);
    $("#inputTextHighlighted").show();
    $("#chk0").parents(".row:first").css("background-color", "#e2ebf0");
}

jQuery(document).ready(function() {
    // Abort it not right page
    var path = currentPathArray();
    if (path[0] !== "recommender") {
      return;
    }

    rec.emptyInput = true;
    $("#recommenderButton").click(rec.getRecommendations);
    $("#insertInputLink").click(rec.insertInput);
    $("input[name=input_type]:radio").change(function () {
        rec.enableEdition()});
    $("input[name=output_type]:radio").change(function () {
        rec.enableEdition()});
    $("#ontologyPicker").click(rec.enableEdition);
    $("#input_wc").click(rec.enableEdition);
    $("#input_wa").click(rec.enableEdition);
    $("#input_wd").click(rec.enableEdition);
    $("#input_ws").click(rec.enableEdition);
    $("#input_max_ontologies").click(rec.enableEdition);
    $("#input_wc").focus(rec.enableEdition);
    $("#input_wa").focus(rec.enableEdition);
    $("#input_wd").focus(rec.enableEdition);
    $("#input_ws").focus(rec.enableEdition);
    $("#input_max_ontologies").focus(rec.enableEdition);
    $("#inputText").click(rec.prepareForRealInput);
    $("#advancedOptionsLink").click(rec.showOrHideAdvancedOptions);
    $("#advancedOptions").hide();
    $(".recommenderSpinner").hide();
    $("#editButton").hide();
    rec.hideErrorMessages();
});
/*
* jQuery SimpleTree Drag&Drop plugin
* Update on 22th May 2008
* Version 0.3
*
* Licensed under BSD <http://en.wikipedia.org/wiki/BSD_License>
* Copyright (c) 2008, Peter Panov <panov@elcat.kg>, IKEEN Group http://www.ikeen.com
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
*     * Redistributions of source code must retain the above copyright
*       notice, this list of conditions and the following disclaimer.
*     * Redistributions in binary form must reproduce the above copyright
*       notice, this list of conditions and the following disclaimer in the
*       documentation and/or other materials provided with the distribution.
*     * Neither the name of the Peter Panov, IKEEN Group nor the
*       names of its contributors may be used to endorse or promote products
*       derived from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY Peter Panov, IKEEN Group ``AS IS'' AND ANY
* EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
* DISCLAIMED. IN NO EVENT SHALL Peter Panov, IKEEN Group BE LIABLE FOR ANY
* DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
* LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
* ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


(function($) {
  var NCBOPropertyTree = function(element, opt) {
    var obj = this;
    var OPTIONS;
    var ROOT_ID = "roots";

    OPTIONS = {
      autoclose:         false,
      beforeExpand:      false,
      afterExpand:       false,
      afterExpandError:  false,
      afterSelect:       false,
      afterJumpToClass:  false,
      timeout:           999999,
      treeClass:         "ncboTree",
      width:             350,
      ncboUIURL:         "http://bioportal.bioontology.org",
      apikey:            null,
      ontology:          null
    };

    OPTIONS = $.extend(OPTIONS, opt);

    // Required options
    if (OPTIONS.ontology == null)
      throw new Error("You must provide an ontology id for NCBO Property Tree Widget to operate");

    var $TREE_CONTAINER = element;
    var TREE = $("<ul>").append($("<li>").addClass("root"));
    var ROOT = $('.root', TREE);
    var mousePressed = false;
    TREE.css("width", OPTIONS.width);

    // Empty out the tree container
    $TREE_CONTAINER.html("");

    // Add the actual tree
    $TREE_CONTAINER.append(TREE);

    // Add provided class
    TREE.addClass(OPTIONS.treeClass);

    // format the nodes to match what simpleTree is expecting
    this.formatNodes = function(nodes) {
      var holder = $("<span>");
      var ul = $("<ul>");

      // Sort by prefLabel
      nodes.sort(function(a, b){
        var aName = a.prefLabel.toLowerCase();
        var bName = b.prefLabel.toLowerCase();
        return ((aName < bName) ? -1 : ((aName > bName) ? 1 : 0));
      });

      $.each(nodes, function(index, node){
        var li = $("<li>");
        var a = $("<a>").attr("href", obj.determineHTTPS(node["@id"])).html(node.prefLabel);
        a.attr("data-id", encodeURIComponent(node.id))
         .attr("data-label", node.label)
         .attr("data-definition", node.definition)
         .attr("data-parents", node.parents)
         .attr("data-prefLabel", node.prefLabel);

        ul.append(li.append(a));

        var hasChildrenNotExpanded = typeof node.children !== 'undefined' && node.hasChildren && node.children.length == 0;
        if (node.hasChildren && typeof node.children === 'undefined' || hasChildrenNotExpanded) {
          var ajax_ul = $("<ul>").addClass("ajax");
          var ajax_li = $("<li>");
          var ajax_a = $("<a>").attr("href", node.links.children);
          li.append(ajax_ul.append(ajax_li.append(ajax_a)));
        } else if (typeof node.children !== 'undefined' && node.children.length > 0) {
          var child_ul = obj.formatNodes(node.children);
          li.append(child_ul);
        }
      });

      holder.append(ul)
      return holder.html();
    }

    this.selectClass = function(cls){
      var foundClass = $(TREE.find("a[data-id='" + cls + "']"));
      $(TREE.find("a.active")[0]).removeClass("active");
      foundClass.addClass("active");
    }

    this.selectedClass = function(){
      var cls = $(TREE.find("a.active")[0]);
      if (cls.length == 0) {
        return null;
      } else {
        return {
          id: decodeURIComponent(cls.data("id")),
          prefLabel: cls.html(),
          URL: cls.attr("href")
        };
      }
    }

    this.closeNearby = function(obj) {
      $(obj).siblings().filter('.folder-open, .folder-open-last').each(function(){
        var childUl = $('>ul',this);
        var className = this.className;
        this.className = className.replace('open', 'close');
        childUl.hide();
      });
    };

    this.nodeToggle = function(obj) {
      var childUl = $('>ul',obj);
      if (childUl.is(':visible')) {
        obj.className = obj.className.replace('open','close');
        childUl.hide();
      } else {
        obj.className = obj.className.replace('close','open');
        childUl.show();
        if (OPTIONS.autoclose)
          obj.closeNearby(obj);
        if (childUl.is('.ajax'))
          obj.setAjaxNodes(childUl, obj.id);
      }
    };

    this.setAjaxNodes = function(node, parentId, successCallback, errorCallback) {
      if (typeof OPTIONS.beforeExpand == 'function') {
        OPTIONS.beforeExpand(node);
      }
      $TREE_CONTAINER.trigger("beforeExpand", node);

      var url = $.trim($('a', node).attr("href"));
      if (url) {
        $.ajax({
          type: "GET",
          url: url,
          data: {apikey: OPTIONS.apikey, include: "prefLabel,hasChildren", no_context: true},
          crossDomain: true,
          contentType: 'json',
          timeout: OPTIONS.timeout,
          success: function(response) {
            var nodes = obj.formatNodes(response.collection)
            node.removeAttr('class');
            node.html(nodes);
            $.extend(node, {url:url});
            obj.setTreeNodes(node, true);
            if (typeof OPTIONS.afterExpand == 'function') {
              OPTIONS.afterExpand(node);
            }
            $TREE_CONTAINER.trigger("afterExpand", node);
            if (typeof successCallback == 'function') {
              successCallback(node);
            }
          },
          error: function(response) {
            if (typeof OPTIONS.afterExpandError == 'function') {
              OPTIONS.afterExpandError(node);
            }
            if (typeof errorCallback == 'function') {
              errorCallback(node);
            }
            $TREE_CONTAINER.trigger("afterExpandError", node);
          }
        });
      }
    };

    this.setTreeNodes = function(target, useParent) {
      target = useParent ? target.parent() : target;
      $('li>a', target).addClass('text').bind('selectstart', function() {
        return false;
      }).click(function(){
        var parent = $(this).parent();
        var selectedNode = $(this);
        $('.active', TREE).attr('class', 'text');
        if (this.className == 'text') {
          this.className = 'active';
        }
        if (typeof OPTIONS.afterSelect == 'function') {
          OPTIONS.afterSelect(decodeURIComponent(selectedNode.data("id")), selectedNode.text(), selectedNode);
        }
        $TREE_CONTAINER.trigger("afterSelect", [decodeURIComponent(selectedNode.data("id")), selectedNode.text(), selectedNode]);
        return false;
      }).bind("contextmenu",function(){
        $('.active', TREE).attr('class', 'text');
        if (this.className == 'text') {
          this.className = 'active';
        }
        if (typeof OPTIONS.afterContextMenu == 'function') {
          OPTIONS.afterContextMenu(parent);
        }
        return false;
      }).mousedown(function(event) {
        mousePressed = true;
        cloneNode = $(this).parent().clone();
        var LI = $(this).parent();
        return false;
      });

      $('li', target).each(function(i) {
        var className = this.className;
        var open = false;
        var cloneNode=false;
        var LI = this;
        var childNode = $('>ul',this);
        if (childNode.size() > 0){
          var setClassName = 'folder-';
          if (className && className.indexOf('open') >= 0) {
            setClassName = setClassName + 'open';
            open = true;
          } else {
            setClassName = setClassName+'close';
          }
          this.className = setClassName + ($(this).is(':last-child') ? '-last' : '');

          if (!open || className.indexOf('ajax') >= 0)
            childNode.hide();

          obj.setTrigger(this);
        } else {
          var setClassName = 'doc';
          this.className = setClassName + ($(this).is(':last-child') ? '-last' : '');
        }
      }).before('<li class="line">&nbsp;</li>')
        .filter(':last-child')
        .after('<li class="line-last"></li>');
    };

    this.setTrigger = function(node) {
      $('>a',node).before('<img class="trigger" src="data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==" border=0>');
      var trigger = $('>.trigger', node);
      trigger.click(function(event){
        obj.nodeToggle(node);
      });
      // TODO: $.browser was removed in jQuery 1.9, check IE compatability
      // if (!$.browser.msie) {
      //   trigger.css('float','left');
      // }
    };

    this.determineHTTPS = function(url) {
      if (typeof url === 'undefined') { return url; }
      return url.replace("http:", ('https:' == document.location.protocol ? 'https:' : 'http:'));
    }

    // Populate roots and init tree
    this.init = function() {
      ROOT.html($("<span>").html("Loading...").css("font-size", "smaller"));
      $.ajax({
        url: obj.determineHTTPS(OPTIONS.ncboUIURL) + "/ajax/properties/tree",
        data: {apikey: OPTIONS.apikey, ontology: OPTIONS.ontology, no_context: true},
        contentType: 'json',
        crossDomain: true,
        success: function(roots) {
          if (roots.length > 0) {
            // Flatten potentially nested arrays
            roots = $.map([roots], function(n){
              return n;
            });
            ROOT.html(obj.formatNodes(roots));
            obj.setTreeNodes(ROOT, false);
          } else {
            ROOT.html("No properties exist for this ontology");
            ROOT.css("font-size", "14px").css("margin", "5px");
          }

          if (typeof OPTIONS.onInit === 'function') { OPTIONS.onInit(); }
        }
      });
    };
  }

  $.fn.NCBOPropertyTree = function(options) {
    // Returns the original object(s) so they can be chained
    return this.each(function() {
      var $this = $(this);

      // Return early if this element already has a plugin instance
      if ($this.data('NCBOPropertyTree')) return;

      // pass options to plugin constructor
      var ncboPropertyTree = new NCBOPropertyTree($this, options);
      ncboPropertyTree.init();

      // Store plugin object in this element's data
      $this.data('NCBOPropertyTree', ncboPropertyTree);
    });
  }

}(jQuery));
// Note duplicated code in _visits.html.haml due to Ajax loading
jQuery(document).data().bp.ontChart = {};

jQuery(document).data().bp.ontChart.init = function() {
  Chart.defaults.global.scaleLabel = jQuery(document).data().bp.ont_chart.scaleLabel;
  var data = {
    labels: jQuery(document).data().bp.ont_chart.visitsLabels,
    datasets: [
      {
        label: "Visits",
        fillColor: "rgba(151,187,205,0.2)",
        strokeColor: "rgba(151,187,205,1)",
        pointColor: "rgba(151,187,205,1)",
        pointStrokeColor: "#fff",
        pointHighlightFill: "#fff",
        pointHighlightStroke: "rgba(151,187,205,1)",
        data: jQuery(document).data().bp.ont_chart.visitsData
      }
    ]
  };

  var width = (jQuery("#visits_content").width() || 600).toString();
  var visits_chart = document.getElementById("visits_chart");
  var ctx = visits_chart.getContext("2d");
  visits_chart.width = visits_chart.style.width = width;
  visits_chart.height = visits_chart.style.height = "323";

  var myLineChart = new Chart(ctx).Line(data, { responsive: true });

  // Something funky with Chart.js makes this not always work the first time.
  // The width ends up set to 0 when using responsive mode. So, we try again until it works.
  setTimeout(function() {
    while (visits_chart.width == 0) {
      visits_chart.width = visits_chart.style.width = width;
      visits_chart.height = visits_chart.style.height = "323";
      var myLineChart = new Chart(ctx).Line(data, { responsive: true });
    }
  }, 100);
}
;
// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//




















