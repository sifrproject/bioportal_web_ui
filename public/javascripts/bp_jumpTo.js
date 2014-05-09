var jumpToObj = function(pSearchBoxSelector = "#search_box", pClsSelector = "#concept_id", pOntSelector = "#ontology_id") { {


    // requires globals:
    // BP_SEARCH_SERVER

    // requires libs:
    // jQuery
    // bioportal_autocomplete from bp_crossdomain_autocomplete.js


    // defaults can be overriden in search_box_init.
    var _searchBox = jQuery(pSearchBoxSelector);

    var _cls = jQuery(pClsSelector);
    var _ont = jQuery(pOntSelector);


    // Called when the "Go" button on the Jump To form is clicked
    var _jumpToValue = function(li) {
        if (_cls != null && _ont != null) {
            var cls_id = _cls.val();
            var ont_id = _ont.val();
            document.location = BP_SEARCH_SERVER + "/ontologies/" + ont_id + "/?p=classes&conceptid=" + encodeURIComponent(cls_id);
            return;
        } else {
            var search = confirm("Class could not be found or is not browsable in " + BP_SITE + ".\n\nPress OK to go to the " + BP_SITE + " Search page or Cancel to try again");
            if (search) {
                document.location = BP_SEARCH_SERVER + "/search/";
                return;
            }
        }
    }

    // Sets a hidden form value that records the concept id when a concept is chosen in the jump to
    // This is a workaround because the default autocomplete search method cannot distinguish between two
    // concepts that have the same preferred name but different ids.
    var _jumpToSelect = function(li) {
        _cls.val(li.extra[0]);
        _ont.val(li.extra[2]);
        _jumpToValue(li);
    }


    // Formats the Jump To search results
    // This is closely related to the data returned from search_controller::json_search.
    var _formatItem = function(row) {
        var specials = new RegExp("[.*+?|()\\[\\]{}\\\\]", "g"); // .*+?|()[]{}\
        var keywords = _searchBox.val().trim().replace(specials, "\\$&").split(' ').join('|');
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


    var _autocomplete_options = {
        selectFirst: true,
        lineSeparator: "~!~",
        matchSubset: 0,
        minChars: 2,
        maxItemsToShow: 25,
        width: "400px",
        onFindValue: _jumpToValue,
        onItemSelect: _jumpToSelect,
        footer: "",
        formatItem: _formatItem
    };
    

    // Override defaults with this init method
    this.search_box_init = function(searchURL, params) {
        if (params.extraParams !== undefined) {
            _autocomplete_options.extraParams = params.extraParams;
        }
        if (params.footer !== undefined) {
            _autocomplete_options.footer = params.footer;
        }
        // params.formatItem should be a function
        if (params.formatItem !== undefined) {
            _autocomplete_options.formatItem = params.formatItem;
        }
        // params.onFindValue should be a function
        if (params.onFindValue !== undefined) {
            _autocomplete_options.onFindValue = params.onFindValue;
        }
        // params.onItemSelect should be a function
        if (params.onItemSelect !== undefined) {
            _autocomplete_options.onItemSelect = params.onItemSelect;
        }
        // params.width should be a CSS width spec
        if (params.width !== undefined) {
            _autocomplete_options.width = params.width;
        }
        // params.searchBoxSelector should be a jQuery selector
        if (params.searchBoxSelector !== undefined) {
            _searchBox = jQuery(params.searchBoxSelector);
        }
        // params.clsSelector should be a jQuery selector
        if (params.clsSelector !== undefined) {
            _cls = jQuery(params.clsSelector);
        }
        // params.ontSelector should be a jQuery selector
        if (params.ontSelector !== undefined) {
            _ont = jQuery(params.ontSelector);
        }
        _searchBox.bioportal_autocomplete(searchURL, _autocomplete_options);
    }


    this.truncateText = function(text, max_length) {
        if (typeof max_length === 'undefined' || max_length == "") {
            max_length = 70;
        }
        var more = '...';
        var content_length = $.trim(text).length;
        if (content_length <= max_length)
            return text; // bail early if not overlong
        var actual_max_length = max_length - more.length;
        var truncated_node = jQuery("<div>");
        var full_node = jQuery("<div>").html(text).hide();
        text = text.replace(/^ /, ''); // node had trailing whitespace.
        var text_short = text.slice(0, max_length);
        // Ensure HTML entities are encoded
        // http://debuggable.com/posts/encode-html-entities-with-jquery:480f4dd6-13cc-4ce9-8071-4710cbdd56cb
        text_short = jQuery('<div>').text(text_short).html();
        var other_text = text.slice(max_length, text.length);
        text_short += "<span class='expand_icon'><b>" + more + "</b></span>";
        text_short += "<span class='long_text'>" + other_text + "</span>";
        return text_short;
    }

}
