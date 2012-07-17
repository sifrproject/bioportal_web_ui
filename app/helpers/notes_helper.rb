require 'cgi'

module NotesHelper

  def generate_notes_thread(thread, params = {})
    html = ""
    thread.each { |note| html << process_thread(note, params) }
    html
  end

  def process_thread(note, params = {})
    if params[:collapsed]
      collapsed = "collapsed"
      display = "none"
    else
      collapsed = ""
      display = "block"
    end

    proposal_info = proposal_html(note)

    html1 = <<-html
      <div class="response_container">
        <div class="response" id="note_#{note.id}">
          <div class="note_corner">&nbsp;</div>
          <div class="response_head #{collapsed}">
            <span class="response_collapse"><span class="response_title">#{note.subject}</span> by <span class="response_author">#{get_username(note.author)}</span> <span class="response_date">#{time_ago_in_words(Time.at(convert_java_time(note.created.to_i)))} ago</span></span>
          </div>
          <div id="note_#{note.id}_collapse" class="collapsible #{params[:root_id] unless params[:root_id].nil?}" style="display: #{display};">
            <div class="proposal_info" #{ " style='display: none;'" if proposal_info.nil? or proposal_info.empty? }>
              <h3>#{get_note_type_text(note.type)}</h3>
              #{proposal_info}
            </div>
            <div class="response_body">
              #{note.body}
            </div>
            <div class="create_reply_container" id="#{note.id}_reply_link">
              <a class="create_reply" note_id="#{note.id}" href="javascript:void(0)">reply</a>
            </div>
            <div class="reply_compose" id="note_#{note.id}_reply">
              <a href="javascript:void(0)" note_id="#{note.id}" class="cancel_reply ui-icon ui-icon-closethick"></a>
              <div id="reply_#{note.id}" class="reply_form_container"></div>
            </div>
            <div class="spacer"></div>
            <div class="response_children" id="#{note.id}_children">
          </div>
    html

    html2 = note.associated.empty? ? "" : generate_notes_thread(note.associated, params)

    html3 = <<-html
          </div>
          <div class="response_spacer"></div>
        </div>
      </div>
    html

    html1 + html2 + html3
  end

  def proposal_html(note)
    case note.type
    when "Comment"
      return ""
    when "ProposalForCreateEntity"
      html = <<-html
        <table class="proposal">
          <tr>
            <th>Preferred Name</th>
            <td>#{note.values[note.type]['preferredName']}</td>
            <th>Provisional id</th>
            <td>#{note.values[note.type]['id']}</td>
            <th>Parent</th>
            <td>#{note.values[note.type]['parent']}</td>
          </tr>
          <tr>
            <th>Reason for Change</th>
            <td>#{note.values[note.type]['reasonForChange']}</td>
            <th>Status</th>
            <td>#{note.status}</td>
            <th>Contact Info</th>
            <td>#{note.values[note.type]['contactInfo']}</td>
          </tr>
          <tr>
            <th>Synonyms</th>
            <td colspan="5">#{note.values[note.type]['synonyms'].join(", ")}</td>
          </tr>
          <tr>
            <th>Definition</th>
            <td colspan="5">#{note.values[note.type]['definition']}</td>
          </tr>
        </table>
      html
    when "ProposalForChangeHierarchy"
      html = <<-html
        <table class="proposal">
          <tr>
            <th>Relationship Type</th>
            <td>#{note.values[note.type]['relationshipType']}</td>
          </tr>
          <tr>
            <th>New Relationship Target</th>
            <td colspan="3">#{note.values[note.type]['relationshipTarget']}</td>
          </tr>
          <tr>
            <th>Old Relationship Target</th>
            <td colspan="3">#{note.values[note.type]['oldRelationshipTarget']}</td>
          </tr>
          <tr>
            <th>Reason for Change</th>
            <td>#{note.values[note.type]['reasonForChange']}</td>
            <th>Status</th>
            <td>#{note.status}</td>
            <th>Contact Info</th>
            <td>#{note.values[note.type]['contactInfo']}</td>
          </tr>
        </table>
      html
    when "ProposalForChangePropertyValue"
      html = <<-html
        <table class="proposal">
          <tr>
            <th>Property id</th>
            <td>#{note.values[note.type]['propertyId']}</td>
          </tr>
          <tr>
            <th>New Property Value</th>
            <td colspan="3">#{note.values[note.type]['newValue']}</td>
          </tr>
          <tr>
            <th>Old Property Value</th>
            <td colspan="3">#{note.values[note.type]['oldValue']}</td>
          </tr>
          <tr>
            <th>Reason for Change</th>
            <td>#{note.values[note.type]['reasonForChange']}</td>
            <th>Status</th>
            <td>#{note.status}</td>
            <th>Contact Info</th>
            <td>#{note.values[note.type]['contactInfo']}</td>
          </tr>
        </table>
      html
    end

    html
  end

  def get_applies_to_link(ontology_id, type, id)
    # We don't use helper methods (like link_to or url_for) here because this can get called from the controller
    begin
      case type
      when "Class"
        return "<a href='/visualize/#{ontology_id}/?conceptid=#{CGI.escape(id)}#notes'>#{DataAccess.getNode(ontology_id, id).label_html}</a>"
      when "Note"
        ontology = DataAccess.getOntology(ontology_id)
        return "<a href='/notes/virtual/#{ontology.ontologyId}?noteid=#{id}'>#{DataAccess.getNote(ontology.ontologyId, id, false, true).subject}</a>"
      when "Individual"
      when "Property"
      when "Ontology"
        ontology = DataAccess.getOntology(ontology_id)
        return "<a href='/ontologies/#{ontology.ontologyId}/?p=notes'>#{ontology.displayLabel}</a>"
      end
    rescue Exception => e
      return "Unknown or Deprecated #{type}"
    end
  end

  def get_applies_to_url(ontology_id, type, id)
    # We don't use helper methods (like link_to or url_for) here because this can get called from the controller
    begin
      case type
      when "Class"
        return "/visualize/#{ontology_id}/?conceptid=#{CGI.escape(id)}#notes"
      when "Note"
        ontology = DataAccess.getOntology(ontology_id)
        return "/notes/virtual/#{ontology.ontologyId}?noteid=#{id}"
      when "Individual"
      when "Property"
      when "Ontology"
        ontology = DataAccess.getOntology(ontology_id)
        return "/ontologies/#{ontology.ontologyId}/?p=notes"
      end
    rescue Exception => e
      return ""
    end
  end

  def get_note_type_text(note_type)
    case note_type
    when "Comment"
      return "Comment"
    when "ProposalForCreateEntity"
      return "New Term Proposal"
    when "ProposalForChangeHierarchy"
      return "New Relationship Proposal"
    when "ProposalForChangePropertyValue"
      return "Change Property Value Proposal"
    end
  end

  def subscribe_button(ontology_id)
    user = session[:user]
    return "<a href='/login?redirect=#{request.request_uri}' style='font-size: .9em;' class='subscribe_to_notes'>Subscribe to notes emails</a>" if user.nil?

    subs = DataAccess.getUserSubscriptions(user.id)

    if !subs.nil?
      sub_text = subbed_to_ont?(ontology_id, subs) ? "Unsubscribe" : "Subscribe"
      params = "data-bp_ontology_id='#{ontology_id}' data-bp_is_subbed='#{subbed_to_ont?(ontology_id, subs)}' data-bp_user_id='#{user.id}'"
      spinner = '<span class="notes_subscribe_spinner" style="display: none;"><img src="/images/spinners/spinner_000000_16px.gif" style="vertical-align: text-bottom;"></span>'
      error = "<span style='color: red;' class='notes_sub_error'></span>"
      return "<a href='javascript:void(0);' class='subscribe_to_notes link_button' #{params}>#{sub_text} to notes emails</a> #{spinner} #{error}"
    else
      return ""
    end
  end

  def delete_button
    user = session[:user]
    return "" if user.nil?

    params = "data-bp_user_id='#{user.id}'"
    spinner = '<span class="delete_notes_spinner" style="display: none;"><img src="/images/spinners/spinner_000000_16px.gif" style="vertical-align: text-bottom;"></span>'
    error = "<span style='color: red;' class='delete_notes_error'></span>"
    return "<a href='#' onclick='deleteNotes(this);return false;' style='display: inline-block !important;' class='notes_delete link_button' #{params}>Delete selected notes</a> #{spinner} #{error}"
  end

  def subbed_to_ont?(ontology_id, subscriptions)
    subscriptions.each do |sub|
      return true if sub["ontologyId"].to_i == ontology_id.to_i
    end
    return false
  end

end
