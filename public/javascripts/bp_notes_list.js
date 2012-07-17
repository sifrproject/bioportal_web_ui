/**
 * @author palexander
 */

var BP_NOTES_LIST_LOADED = true;
var columns = { archived: 3, date: 6, subjectSort: 2 };

jQuery(document).ready(function(){
	jQuery(".notes_list_link").live('click', function(event){
		event.preventDefault();
		var link = this;
		var row_id = jQuery(this).attr("id");
		var note_id = jQuery(this).attr("id").substring(4);

		if (jQuery(this).parent().hasClass("highlighted_row")) {
			jQuery(this).parent().parent().removeClass("highlighted_row");
			jQuery(this).parent().parent().children().removeClass("highlighted_row");
			// Store changes in the cache
			jQuery.data(document.body, row_id, jQuery("#row_thread_" + note_id).html());
			// Remove the element
			jQuery("#row_expanded_" + note_id).remove();
		} else {
			jQuery(this).parent().parent().addClass("highlighted_row");
			jQuery(this).parent().parent().children().addClass("highlighted_row");
			jQuery(this).parent().parent().after("<tr id='row_expanded_" + note_id + "' class='highlighted_border'><td colspan='" + jQuery.data(document.body, "note_colspan") + "' class='highlighted_border' id='row_thread_" + note_id + "'><span class='ajax_message'><img src='/images/spinners/spinner_000000_16px.gif' style='vertical-align: text-bottom;'> loading...</span></td></tr>");

			// Check cache for result, make call if it isn't found
			if (jQuery.data(document.body, row_id) === undefined || jQuery.data(document.body, row_id) === null) {
				jQuery.ajax({
					type: "GET",
					url: "/notes/virtual/" + jQuery.data(document.body, "ontology_id") + "/?noteid=" + note_id,
					success: function(html){
						jQuery.data(document.body, row_id, html);
						insert_note(link, note_id);
					},
					error: function(){
						jQuery("#row_thread_" + note_id).html("Error retreiving note, please try again");
					}
				});
			} else {
				insert_note(link, note_id);
			}
		}
	});
});

function insert_note(link, note_id) {
	var html = jQuery.data(document.body, jQuery(link).attr("id").toString());
	jQuery("#row_thread_" + note_id).html(html);
}

// This will wire up a table with the dataTables config.
function wireTableWithData(notesTableNew, aData) {
	// Wire up table if it hasn't been done yet
	notesTable = notesTableNew;
  notesTable.dataTable({
		"aaData": aData,
		"iDisplayLength": 50,
		"sPaginationType": "full_numbers",
		"aaSorting": [[columns.date, 'desc']],
		"aoColumns": [
      { "bVisible": false }, // Delete
			{ "iDataSort": columns.subjectSort }, // Subject link
			{ "bVisible": false }, // Subject for sort
			{ "bVisible": false }, // Archive for filter
			null, // Author
			null, // Type
			{ "bVisible": false }, // Date for sort
			null // Created
		],
		"fnDrawCallback": function(){
			jQuery(".highlighted_row").removeClass("highlighted_row");
      showDeleteInfo();
		},
    "fnInitComplete": function(){
      showDeleteInfo();
    }
	});
}

// This will wire up a table with the dataTables config.
// Needs to stay inline because IE won't recognize it in an external file.
function wireTable(notesTableNew) {
  // Wire up table if it hasn't been done yet
  notesTable = notesTableNew;
  notesTable.dataTable({
  	"bDestroy": true,
    "iDisplayLength": 50,
    "sPaginationType": "full_numbers",
    "aaSorting": [[columns.date, 'desc']],
    "aoColumns": [
       { "bVisible": false }, // Delete
       { "iDataSort": columns.subjectSort }, // Subject link
       { "bVisible": false }, // Subject for sort
       { "bVisible": false }, // Archived for filter
       null, // Author
       null, // Type
       target, // Target
       null // Created
    ],
    "fnDrawCallback": function(){
      jQuery(".highlighted_row").removeClass("highlighted_row");
      showDeleteInfo();
    },
    "fnInitComplete": function(){
      showDeleteInfo();
    }
  });

  // Important! Table is somehow getting set to zero width. Reset here.$
  jQuery(notesTable).css("width", "100%");
}

function hideOrUnhideArchivedNotes() {
    if (jQuery("#hide_archived:checked").val() !== undefined) {
      // Checked
      notesTable.fnFilter('false', columns.archived);
    } else {
      // Unchecked
      notesTable.fnFilter('', columns.archived, true, false);
    }
}

var init_notes = function(){
  var tempTable = jQuery("#" + jQuery.data(document.body, "semi_uuid") + "_notes_list");
  wireTable(tempTable);

  jQuery('#filter_menu').superfish({
    delay: 1200,              // 1.2 second delay on mouseout);
    dropShadows: false,
    speed: 'fast'
  });

  jQuery("#hide_archived").click(function(){
    hideOrUnhideArchivedNotes();
  });

  // Notes subscriptions button
  jQuery("a.subscribe_to_notes").button();
}

// Make sure to initialize the notes UI when the tree changes
jQuery(document).bind("tree_changed", init_notes);
jQuery(document).bind("tree_changed", wireNotesAddButton);


