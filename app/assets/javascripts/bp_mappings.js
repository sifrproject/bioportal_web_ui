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



