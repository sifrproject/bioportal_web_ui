/**
 * @author palexander
 */

var BP_NOTES_LOADED = true;

// Make sure that notes table is 100% width when switching tabs
jQuery(document).bind("terms_tab_visible", function(){
  jQuery("table.notes_list_table").css("width", "100%");
});

jQuery(document).ready(function(){
  // Init notes
  wireNotesAddButton();
  wireNotesAddClicks();

  // Wire up subscriptions button activity
  jQuery("a.subscribe_to_notes").live("click", function(){
    subscribeToNotes(this);
  });

  // Wire up submit note functionality
  jQuery(".create_note_submit").live('click', function(event) {
    submitNote(event, this);
  });

  // Hide the notes create form whenever we change ont views
  jQuery(document).live("ont_view_change", function(){
    jQuery("h2.add_reply_button").each(function(){
      hideNoteForm(this);
    });
  });
});

function showDeleteInfo() {
  if (bp_notesDeletable) {
    if (typeof notesTable !== "undefined") notesTable.fnSetColumnVis(0, true);
    if (typeof ontNotesTable !== "undefined") ontNotesTable.fnSetColumnVis(0, true);
    jQuery(".notes_delete").show();
  }
}

function Comment(prefix, ONT) {
  this.form_fields = {
    subject: { element: jQuery("#" + prefix + "create_comment_subject"),
      errorMessage: "Please enter a subject",
      errorLocation: jQuery("#" + prefix + "create_comment_subject").attr("id") + "_error"
    },
    body: { element: jQuery("#" + prefix + "create_comment_body"),
      errorMessage: "Please enter a message in the body",
      errorLocation: jQuery("#" + prefix + "create_comment_body").attr("id") + "_error"
    }
  };

  this.required = [ "subject", "body" ];

  this.failedValidation;

  // Contains the values that we want to submit
  this.member_variables = {
    ontology_virtual_id: ONT,
    appliesTo: jQuery("#" + prefix + "create_comment_appliesTo").val(),
    appliesToType: jQuery("#" + prefix + "create_comment_appliesToType").val(),
    type: jQuery("#" + prefix + "create_comment_noteType").val(),
    author: jQuery("#" + prefix + "create_comment_author").val(),
    subject: jQuery("#" + prefix + "create_comment_subject").val(),
    body: jQuery("#" + prefix + "create_comment_body").val()
  };

  this.validate = function() {
    validateForm(this);
  };

  this.reset = function() {
    for (field in this.form_fields) {
      this.form_fields[field].element.val("");
      jQuery("#" + this.form_fields[field].errorLocation).html("");
    }
  }
}

function ProposalForCreateEntity(prefix, ONT) {
  this.form_fields = {
    reasonForChange: { element: jQuery("#" + prefix + "create_new_term_reasonForChange"),
      errorMessage: "Please enter the rationale for this proposal",
      errorLocation: jQuery("#" + prefix + "create_new_term_reasonForChange").attr("id") + "_error"
    },
    contactInfo: { element: jQuery("#" + prefix + "create_new_term_contactInfo") },
    termDefinition: { element: jQuery("#" + prefix + "termDefinition"),
      errorMessage: "Please enter a definition",
      errorLocation: jQuery("#" + prefix + "termDefinition").attr("id") + "_error"
    },
    termId: { element: jQuery("#" + prefix + "termId") },
    termParent: { element: jQuery("#" + prefix + "termParent"),
      errorMessage: "Please select a parent term",
      errorLocation: jQuery("#" + prefix + "termParent").attr("id") + "_error"
    },
    termPreferredName: { element: jQuery("#" + prefix + "termPreferredName"),
      errorMessage: "Please enter a preferred name",
      errorLocation: jQuery("#" + prefix + "termPreferredName").attr("id") + "_error"
    },
    termSynonyms: { element: jQuery("#" + prefix + "termSynonyms") }
  };

  this.required = [ "reasonForChange", "termDefinition", "termParent", "termPreferredName" ];

  this.failedValidation;

  // Contains the values that we want to submit
  this.member_variables = {
    ontology_virtual_id: ONT,
    appliesTo: jQuery("#" + prefix + "create_new_term_appliesTo").val(),
    appliesToType: jQuery("#" + prefix + "create_new_term_appliesToType").val(),
    type: jQuery("#" + prefix + "create_new_term_noteType").val(),
    author: jQuery("#" + prefix + "create_new_term_author").val(),
    subject: getNoteTypeText(jQuery("#" + prefix + "create_new_term_noteType").val()) + ": " + jQuery("#" + prefix + "termPreferredName").val(), // Special text plus preferred name
    body: jQuery("#" + prefix + "create_new_term_body").val(),
    reasonForChange: jQuery("#" + prefix + "create_new_term_reasonForChange").val(),
    contactInfo: jQuery("#" + prefix + "create_new_term_contactInfo").val(),
    termDefinition: jQuery("#" + prefix + "termDefinition").val(),
    termId: jQuery("#" + prefix + "termId").val(),
    termParent: jQuery("#" + prefix + "termParent").val(),
    termPreferredName: jQuery("#" + prefix + "termPreferredName").val(),
    termSynonyms: jQuery("#" + prefix + "termSynonyms").val()
  };

  this.validate = function() {
    validateForm(this);
  };

  this.reset = function() {
    for (field in this.form_fields) {
      this.form_fields[field].element.val("");
      jQuery("#" + this.form_fields[field].errorLocation).html("");
    }
  }
}

function ProposalForChangeHierarchy(prefix, ONT) {
  this.form_fields = {
    reasonForChange: { element: jQuery("#" + prefix + "create_change_hierarchy_reasonForChange"),
      errorMessage: "Please enter the rationale for this proposal",
      errorLocation: jQuery("#" + prefix + "create_change_hierarchy_reasonForChange").attr("id") + "_error"
    },
    contactInfo: { element: jQuery("#" + prefix + "create_change_hierarchy_contactInfo") },
    oldRelationshipTarget: { element: jQuery("#" + prefix + "oldRelationshipTarget") },
    relationshipTarget: { element: jQuery("#" + prefix + "relationshipTarget"),
      errorMessage: "Please enter the target term for this relationship",
      errorLocation: jQuery("#" + prefix + "relationshipTarget").attr("id") + "_error"
    },
    relationshipType: { element: jQuery("#" + prefix + "relationshipType"),
      errorMessage: "Please enter the relationship type",
      errorLocation: jQuery("#" + prefix + "relationshipType").attr("id") + "_error"
    }
  };

  this.required = [ "reasonForChange", "relationshipTarget", "relationshipType" ];

  this.failedValidation;

  // Contains the values that we want to submit
  this.member_variables = {
    ontology_virtual_id: ONT,
    appliesTo: jQuery("#" + prefix + "create_change_hierarchy_appliesTo").val(),
    appliesToType: jQuery("#" + prefix + "create_change_hierarchy_appliesToType").val(),
    type: jQuery("#" + prefix + "create_change_hierarchy_noteType").val(),
    author: jQuery("#" + prefix + "create_change_hierarchy_author").val(),
    subject: getNoteTypeText(jQuery("#" + prefix + "create_change_hierarchy_noteType").val()) + ": " + jQuery("#" + prefix + "relationshipType").val(), // Special text plus preferred name
    body: jQuery("#" + prefix + "create_change_hierarchy_body").val(),
    reasonForChange: jQuery("#" + prefix + "create_change_hierarchy_reasonForChange").val(),
    contactInfo: jQuery("#" + prefix + "create_change_hierarchy_contactInfo").val(),
    oldRelationshipTarget: jQuery("#" + prefix + "oldRelationshipTarget").val(),
    relationshipTarget: jQuery("#" + prefix + "relationshipTarget").val(),
    relationshipType: jQuery("#" + prefix + "relationshipType").val()
  };

  this.validate = function() {
    validateForm(this);
  };

  this.reset = function() {
    for (field in this.form_fields) {
      this.form_fields[field].element.val("");
      jQuery("#" + this.form_fields[field].errorLocation).html("");
    }
  }
}

function ProposalForChangePropertyValue(prefix, ONT) {
  this.form_fields = {
    reasonForChange: { element: jQuery("#" + prefix + "create_change_prop_value_reasonForChange"),
      errorMessage: "Please enter the rationale for this proposal",
      errorLocation: jQuery("#" + prefix + "create_change_prop_value_reasonForChange").attr("id") + "_error"
    },
    contactInfo: { element: jQuery("#" + prefix + "create_change_prop_value_contactInfo") },
    propertyId: { element: jQuery("#" + prefix + "propertyId"),
      errorMessage: "Please enter the id of the property you would like to change",
      errorLocation: jQuery("#" + prefix + "propertyId").attr("id") + "_error"
    },
    newPropertyValue: { element: jQuery("#" + prefix + "newPropertyValue"),
      errorMessage: "Please enter the new property value",
      errorLocation: jQuery("#" + prefix + "newPropertyValue").attr("id") + "_error"
    },
    oldPropertyValue: { element: jQuery("#" + prefix + "oldPropertyValue") }
  };

  this.required = [ "reasonForChange", "newPropertyValue", "propertyId" ];

  this.failedValidation;

  // Contains the values that we want to submit
  this.member_variables = {
    ontology_virtual_id: ONT,
    appliesTo: jQuery("#" + prefix + "create_change_prop_value_appliesTo").val(),
    appliesToType: jQuery("#" + prefix + "create_change_prop_value_appliesToType").val(),
    type: jQuery("#" + prefix + "create_change_prop_value_noteType").val(),
    author: jQuery("#" + prefix + "create_change_prop_value_author").val(),
    subject: getNoteTypeText(jQuery("#" + prefix + "create_change_prop_value_noteType").val()) + ": " + jQuery("#" + prefix + "propertyId").val(), // Special text plus preferred name
    body: jQuery("#" + prefix + "create_change_prop_value_body").val(),
    reasonForChange: jQuery("#" + prefix + "create_change_prop_value_reasonForChange").val(),
    contactInfo: jQuery("#" + prefix + "create_change_prop_value_contactInfo").val(),
    propertyId: jQuery("#" + prefix + "propertyId").val(),
    newPropertyValue: jQuery("#" + prefix + "newPropertyValue").val(),
    oldPropertyValue: jQuery("#" + prefix + "oldPropertyValue").val()
  };

  this.validate = function() {
    validateForm(this);
  };

  this.reset = function() {
    for (field in this.form_fields) {
      this.form_fields[field].element.val("");
      jQuery("#" + this.form_fields[field].errorLocation).html("");
    }
  }
}

function wireNotesAddButton(options) {
  // Wire up the add/hide note form buttons
  if (options === undefined || options["prefix"] === undefined) {
    prefix = jQuery.data(document.body, "semi_uuid") + "_";
  }

  jQuery("#" + prefix + "create_note_container").hide();
  jQuery('.' + prefix + 'add_reply').addClass("add_reply_button");
}

function wireNotesAddClicks() {
  // Wire up the "Add Reply" link
  jQuery('.add_reply_button').live("click", function(){
    if (jQuery(this).parent().children(".create_note_container").is(':visible')) {
      hideNoteForm(this);
    } else {
      showNoteForm(this);
    }
  });

  // Wire up the tabs in the 'Add Note' form box
  jQuery(".note_action").live("click", function(){
    var spanId = jQuery(this).attr("id");
    var noteTypeId = jQuery(this).attr("note_type");
    var buttons_div = jQuery(this).parent(".create_note_buttons");
    jQuery(buttons_div).parent().children('.create_note_options').children('.note_options').hide();
    jQuery('#' + noteTypeId).show();
    jQuery(buttons_div).children('.note_action').removeClass("create_note_selected");
    buttons_div.parent().find("#"+prefix+"note_submit").attr("note_type", jQuery(this).data("bp_note_type"));
    jQuery(this).addClass("create_note_selected");
  });

}

function hideNoteForm(button) {
  jQuery(button).text(jQuery.data(document.body, "add_text"));
  jQuery(button).parent().children(".create_note_container").hide();
}

function showNoteForm(button) {
  var prefix = jQuery(button).data("bp_prefix");
  newCaptcha(jQuery(document.body).data("recaptcha_key"), prefix+"recaptcha_container");
  jQuery(button).text("Hide");
  jQuery(button).parent().children(".create_note_container").show();
}

function submitNote(event, target) {
  event.preventDefault();

  var button = target;
  var note;
  var note_type = jQuery(target).attr("note_type");
  var prefix = jQuery(target).data("prefix") === null ? "" : jQuery(target).data("prefix");
  var action = jQuery(target).data("action");
  var ONT = jQuery(target).data("ont_id");
  var NOTES_URL = "/notes/";
  var noteParams;
  var recaptcha_challenge_field = jQuery("#"+prefix+"submit_container").find("[name='recaptcha_challenge_field']").val();
  var recaptcha_response_field = jQuery("#"+prefix+"submit_container").find("[name='recaptcha_response_field']").val();

  // Should this note be anonymous?
  var anonymous = jQuery(target).parent().find(".anonymous_note").val();
  if (typeof anonymous === "undefined") {
    anonymous = jQuery(target).parent().find(".anonymous_note_logged_in:checked").val();
  }

  // Disable button, activate spinner and text
  button_loading(button, prefix);

  // Clear existing error messages
  jQuery(".error_input").html("");

  switch (note_type) {
  case "create_comment":
    note = new Comment(prefix, ONT);
    note.validate();
    break;
  case "create_new_term":
    note = new ProposalForCreateEntity(prefix, ONT);
    note.validate();
    break;
  case "create_change_hierarchy":
    note = new ProposalForChangeHierarchy(prefix, ONT);
    note.validate();
    break;
  case "create_change_prop_value":
    note = new ProposalForChangePropertyValue(prefix, ONT);
    note.validate();
  }

  if (note.failedValidation === true) {
    button_reset(button);
    jQuery("#" + prefix + "_submit_container").find("span.error_message").html(' Invalid entries, please fix and try again');
  } else {
    noteParams = note.member_variables;
    noteParams["anonymous"] = anonymous;
    noteParams["recaptcha_challenge_field"] = recaptcha_challenge_field;
    noteParams["recaptcha_response_field"] = recaptcha_response_field;

    jQuery.ajax({
        type: "POST",
        url: NOTES_URL,
        data: note.member_variables,
        dataType: "json",
        success: function(data) {
          // What do we do with the returned data?
          if (action == "root") {
            jQuery.get("/notes/ajax/single/" + data.ontologyId + "?noteid=" + data.id,
                function(html) {
                  // Show the response container
                  jQuery("#" + data.appliesTo.id + "_responses_container").show();
                  jQuery("#" + data.appliesTo.id + "_responses_container").append(html);

                  button_reset(button);
                }
            );
          } else if (action == "thread") {
            jQuery.get("/notes/ajax/single/" + data.ontologyId + "?noteid=" + data.id,
                function(html) {
                  jQuery("#" + data.appliesTo.id + "_children").append(html);

                  // Hide all reply containers, show all reply links
                  jQuery(".reply_form_container").each(function() {
                    jQuery(this).html("");
                    jQuery(this).parent().hide();
                    jQuery(".create_reply_container").show();
                  });

                  button_reset(button);
                }
            );
          } else {
            // Get JSON response for new row and add if successful
            jQuery.get("/notes/ajax/single_list/" + data.ontologyId + "?noteid=" + data.id,
                function(json) {
                  var state = History.getState();

                  // Handling for tree view
                  if (state.cleanUrl.match("p=terms") !== null) {
                    // Check for "No notes" message and delete
                    var no_notes_check = document.getElementById("no_notes");
                    if (no_notes_check !== null) {
                      notesTable.fnDeleteRow(notesTable.fnGetPosition(document.getElementById("no_notes")));
                    }

                    // We add the (+ "") statement to "cast" to a string
                    notesTable.fnAddData([
                                '<input type="checkbox" id="delete_'+json.id+'" class="delete_note_checkbox" data-note_id="'+json.id+'">',
                                json.subject_link + "",
                                json.subject + "",
                                "false", // archived should be false since we just created the note
                                json.author + "",
                                json.type + "",
                                json.appliesTo + "",
                                json.created + ""
                            ]);

                    notesTable.fnFilter("");
                  }

                  // Check for "No notes" message and delete
                  var ont_no_notes_check = document.getElementById("ont_no_notes");
                  if (ont_no_notes_check !== null) {
                    ontNotesTable.fnDeleteRow(ontNotesTable.fnGetPosition(document.getElementById("ont_no_notes")));
                  }

                  try {
                    Recaptcha.reload();
                  } catch (err) {
                    // ignore if not present
                  }

                  // We add the (+ "") statement to "cast" to a string
                  ontNotesTable.fnAddData([
                              '<input type="checkbox" id="delete_'+json.id+'" class="delete_note_checkbox" data-note_id="'+json.id+'">',
                              json.subject_link + "",
                              json.subject + "",
                              "false", // archived should be false since we just created the note
                              json.author + "",
                              json.type + "",
                              json.appliesTo + "",
                              json.created + ""
                          ]);

                  // Redraw table, including sort and filter options
                  ontNotesTable.fnFilter("");
                  jQuery("#notes_list_filter input").val("");

                  button_reset(button);
                }
            );
          }

          // Reset form fields
          note.reset();

          // Show the delete button
          bp_notesDeletable = true;
          showDeleteInfo();

          // Update note_count
          var new_note_count = parseInt(jQuery("#note_count").text()) + 1;
          jQuery("#note_count").text(new_note_count);
          // Update the count for this concept in the cache (silently fails if we're not at a concept)
          if (getCache(jQuery.data(document.body, "node_id")) !== null) {
            getCache(jQuery.data(document.body, "node_id"))[5] = new_note_count;
          }

          // Move window to new note location (TODO: Possible future implementation)
          //   window.scrollTo(0,$("#"+id).offset().top);
        },
        error: function(response, textStatus, errorThrown) {
          button_reset(button);
          var data = jQuery.parseJSON(response.responseText);
          var message = ' Problem submitting, please try again';
          if (typeof data !== "undefined") {
            if (data.valid_recaptcha == false) {
              message = ' Text entered in CAPTHCA did not match the image, please try again';
              Recaptcha.reload();
            }
          }
          jQuery("#" + prefix + "submit_container").find("span.error_message").html(message);
        }
    });
  }

  return false;
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

function button_loading(button, prefix) {
  jQuery(".error_message").html("");
  jQuery(button).addClass("add_reply_button_busy");
  jQuery(button).attr("disabled", "true");
  jQuery("#" + jQuery(button).data("prefix") + "submit_container").append(' <span class="ajax_message"><img src="/images/spinners/spinner_E2EBF0.gif" style="vertical-align: middle;"> loading...</span>');
}

function button_reset(button) {
  jQuery(button).removeClass("add_reply_button_busy");
  jQuery(button).removeAttr("disabled");
  jQuery(".ajax_message").remove();
}

function newCaptcha(recaptchaKey, location) {
  Recaptcha.create(recaptchaKey, location, { theme: "clean" });
}

function getNoteTypeText(note_type) {
  switch (note_type) {
  case "Comment":
    return "Comment";
  case "ProposalForCreateEntity":
    return "New Term Proposal";
  case "ProposalForChangeHierarchy":
    return "New Relationship Proposal";
  case "ProposalForChangePropertyValue":
    return "Change Property Value Proposal";
  default:
    return "";
  }
}

function validateForm(oForm) {
  for (field in oForm.form_fields) {
    var fieldValue = oForm.form_fields[field].element.val();
    oForm.form_fields[field].element.val(jQuery.trim(fieldValue));
    if (jQuery.inArray(field, oForm.required) >= 0 && oForm.form_fields[field].element.val() === "") {
      oForm.failedValidation = true;
      jQuery("#" + oForm.form_fields[field].errorLocation).html("<br/>" + oForm.form_fields[field].errorMessage);
    } else {
      jQuery("#" + oForm.form_fields[field].errorLocation).html("");
    }
  }
}


function calculateNoteCount(notesTable) {
  if (typeof notesTable === "undefined" || notesTable === null) {
    return;
  }

  var rows = notesTable.find("tbody tr");
  var notes_count;
  if (rows.length == 1 && jQuery(rows).children("td")[0].getAttribute("colspan") > 1) {
    notes_count = 0;
  } else {
    notes_count = rows.length;
  }
  jQuery("#note_count").html(notes_count);
}

function deleteNotes(button) {
  var notesToDelete = [], params;
  var errors = jQuery(button).closest(".notes_list_container").find(".delete_notes_error");
  var spinner = jQuery(button).closest(".notes_list_container").find(".delete_notes_spinner");

  errors.html("");
  spinner.show();

  jQuery("input.delete_note_checkbox:checked").each(function(){
    notesToDelete.push(jQuery(this).attr("data-note_id"));
  });

  params = {
    noteids: notesToDelete,
    _method: "delete",
    ontologyid: ontology_id,
    concept_id: concept_id
  };

  errors.html("");

  jQuery.ajax({
      url: "/ajax/notes/delete",
      type: "POST",
      data: params,
      success: function(data){
        var rowId;

        spinner.hide();

        for (note_id in data.success) {
          jQuery(button).closest(".notes_list_container").find("." + data.success[note_id] + "_tr").remove();
          jQuery("#delete_" + data.success[note_id]).closest("tr").remove();
          jQuery(button).closest(".notes_list_container").find("#row_expanded_" + data.success[note_id]).remove();
        }

        for (note_id in data.error) {
          errors.html("There was a problem deleting one or more note");
          rowId = data.error[note_id];
          jQuery(button).closest(".notes_list_container").find("." + rowId + "_tr").css("border", "red solid");
        }

        calculateNoteCount();
      },
      error: function(){
        spinner.hide();
        errors.html("There was a problem deleting, please try again");
      }
  });
}



