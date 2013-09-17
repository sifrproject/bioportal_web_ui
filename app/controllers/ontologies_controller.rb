class OntologiesController < ApplicationController

  require 'cgi'

  #caches_page :index

  helper :concepts
  layout 'ontology'

  before_filter :authorize, :only=>[:edit,:update,:create,:new]

  # GET /ontologies
  # GET /ontologies.xml
  def index
    @ontologies = DataAccess.getOntologyList()
    @categories = DataAccess.getCategories()
    @groups = DataAccess.getGroups()
    @term_counts = DataAccess.getTermsCountOntologies
    @mapping_counts = DataAccess.getMappingCountOntologiesHash
    @note_counts = DataAccess.getNotesCounts

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @ontologies.to_xml }
    end
  end

  # GET /ontologies/1
  # GET /ontologies/1.xml
  def show
    # This action is now a router using the 'p' parameter as the page to show
    case params[:p]
    when "terms"
      self.terms
      return
    when "mappings"
      self.mappings
      return
    when "notes"
      self.notes
      return
    when "widgets"
      self.widgets
      return
    when "summary"
      self.summary
      return
    else
      self.summary
      return
    end
  end

  def virtual
    @ontology = DataAccess.getLatestOntology(params[:ontology])

    @versions = DataAccess.getOntologyVersions(@ontology.ontologyId).sort{|x,y| x.id <=> y.id}

    LOG.add :info, 'show_virtual_ontology', request, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel

    if @ontology.statusId.to_i.eql?(3)
      redirect_to "/ontologies/#{@ontology.id}"
      return
    else
      for version in @versions
        if version.statusId.to_i.eql?(3)
          redirect_to "/ontologies/#{version.id}"
          return
        end
      end
    end
    redirect_to "/ontologies/#{@ontology.id}"
    return
  end

  def download_latest
    @ontology = DataAccess.getLatestOntology(params[:id])
    redirect_to $REST_URL + "/ontologies/download/#{@ontology.id}?apikey=#{$API_KEY}"
  end

  def update
    params[:ontology][:isReviewed]=1
    params[:ontology][:isFoundry]=0
    unless !authorize_owner(params[:ontology][:userId].to_i)
      return
    end

    @errors = validate(params[:ontology],true)

    if @errors.length < 1
      if params[:ontology][:isView] && params[:ontology][:isView].to_i == 1
        @ontology = DataAccess.updateView(params[:ontology],params[:id])
      else
        @ontology = DataAccess.updateOntology(params[:ontology],params[:id])
      end

      if @ontology.kind_of?(Hash) && @ontology[:error]
        flash[:notice]=@ontology[:longMessage]
        redirect_to ontology_path(:id=>params[:id])
      else
        if @ontology.isView.eql?("true")
          redirect_to ontology_path(@ontology.viewOnOntologyVersionId) + "#views"
        else
          redirect_to ontology_path(@ontology)
        end
      end
    else
      @ontology = OntologyWrapper.new
      @ontology.from_params(params[:ontology])
      @ontology.id = params[:id]
      @categories = DataAccess.getCategories()

      render :action=> 'edit'
    end

  end


  def edit
    raise Error404 # Disable submission for release migration
    @ontology = DataAccess.getOntology(params[:id])

    authorize_owner(@ontology.userId)

    @categories = DataAccess.getCategories()
  end

  def edit_view
    raise Error404 # Disable submission for release migration
    @ontology = DataAccess.getView(params[:id])

    authorize_owner(@ontology.userId)

    @categories = DataAccess.getCategories()
  end

  def visualize
    # Hack to make ontologyid and conceptid work in addition to id and ontology params
    params[:conceptid] = params[:id].nil? ? params[:conceptid] : params[:id]
    params[:ontology] = params[:ontology].nil? ? params[:ontologyid] : params[:ontology]

    # Error checking
    if params[:ontology].nil? || params[:id] && params[:ontology].nil?
      @error = "Please provide an ontology id or concept id with an ontology id."
      return
    end

    params_array = []
    params.each do |key,value|
      stop_words = [ "ontology", "controller", "action" ]
      next if stop_words.include?(key.to_s) || value.nil? || value.empty?
      params_array << "#{key}=#{CGI.escape(value)}"
    end
    params_string = (params_array.empty?) ? "" : "&#{params_array.join('&')}"

    redirect_to "/ontologies/#{params[:ontology]}?p=terms#{params_string}", :status => :moved_permanently
  end

  # GET /visualize/:ontology
  def terms
    # Hack to make ontologyid and conceptid work in addition to id and ontology params
    params[:id] = params[:id].nil? ? params[:ontologyid] : params[:id]
    params[:ontology] = params[:ontology].nil? ? params[:id] : params[:ontology]

    view = false
    if params[:view]
      view = true
    end

    # Set the ontology we are viewing
    if view
      @ontology = DataAccess.getView(params[:ontology])
    else
      @ontology = DataAccess.getOntology(params[:ontology])
    end

    if @ontology.private? && (session[:user].nil? || !session[:user].has_access?(@ontology))
      if request.xhr?
        return render :partial => 'private_ontology', :layout => false
      else
        return render :partial => 'private_ontology', :layout => "ontology_viewer"
      end
    end

    if @ontology.licensed? && (session[:user].nil? || !session[:user].has_access?(@ontology))
      @user = UserWrapper.new
      if request.xhr?
        return render :partial => 'licensed_ontology', :layout => false
      else
        return render :partial => 'licensed_ontology', :layout => "ontology_viewer"
      end
    end

    # Get most recent active version of ontology if there was a parsing error
    skip_status = [1, 2, 4]
    if OntologyWrapper.virtual_id?(params[:ontology]) && skip_status.include?(@ontology.statusId.to_i)
      DataAccess.getActiveOntologies.each do |ont|
        if ont.ontologyId.eql?(@ontology.ontologyId)
          @ontology = DataAccess.getOntology(ont.id)
          break
        end
      end
    end

    # Redirect to move recent unarchived version is this version is archived
    if @ontology.statusId.to_i.eql?(6)
      @latest_ontology = DataAccess.getLatestOntology(@ontology.ontologyId)
      params[:ontology] = @latest_ontology.id
      flash[:notice] = "The version of <b>#{@ontology.displayLabel}</b> you were attempting to view (#{@ontology.versionNumber}) has been archived and is no longer available for exploring. You have been redirected to the most recent version (#{@latest_ontology.versionNumber})."
      concept_id = params[:conceptid] ? "?conceptid=#{params[:conceptid]}" : ""
      redirect_to "/visualize/#{@latest_ontology.id}#{concept_id}", :status => :moved_permanently
      return
    end

    # Check to see if user is requesting RDF+XML, return the file from REST service if so
    if request.accept.to_s.eql?("application/rdf+xml")
      user_api_key = session[:user].nil? ? "" : session[:user].apikey
      concept_id = params[:conceptid] ? params[:conceptid] : "root"
      rdf = open($REST_URL + "/virtual/rdf/#{@ontology.ontologyId}?conceptid=#{CGI.escape(concept_id)}&apikey=#{$API_KEY}&userapikey=#{user_api_key}")
      render :text => rdf.string, :content_type => "appllication/rdf+xml"
      return
    end

    if !@ontology.flat? && (!params[:conceptid] || params[:conceptid].empty?)
      # get the top level nodes for the root
      @root = TreeNode.new()
      nodes = @ontology.top_level_nodes(view)
      nodes.sort!{|x,y| x.label.downcase<=>y.label.downcase}
      for node in nodes
        if node.label.downcase.include?("obsolete") || node.label.downcase.include?("deprecated")
          nodes.delete(node)
          nodes.push(node)
        end
      end

      @root.set_children(nodes, @root)

      # get the initial concepts to display
      @concept = DataAccess.getNode(@ontology.id, @root.children.first.id, nil, view)

      # Some ontologies have "too many children" at their root. These will not process and are handled here.
      raise Error404 if @concept.nil?

      LOG.add :info, 'visualize_ontology', request, :ontology_id => @ontology.id, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel, :concept_name => @concept.label, :concept_id => @concept.id
    elsif @ontology.flat? && (!params[:conceptid] || params[:conceptid].empty?)
      # Don't display any terms in the tree
      @concept = NodeWrapper.new
      @concept.label = "Please search for a term using the Jump To field above"
      @concept.id = "bp_fake_root"
      @concept.fullId = "bp_fake_root"
      @concept.child_size = 0
      @concept.properties = {}
      @concept.version_id = @ontology.id
      @concept.children = []

    elsif @ontology.flat? && params[:conceptid]
      # Display only the requested term in the tree
      @concept = DataAccess.getNode(@ontology.id, params[:conceptid], nil, view)
      raise Error404 if @concept.nil?
    else
      # if the id is coming from a param, use that to get concept
      @concept = DataAccess.getNode(@ontology.id,params[:conceptid],view)
      raise Error404 if @concept.nil?

      # Did we come from the Jump To widget, if so change logging
      if params[:jump_to_nav]
        LOG.add :info, 'jump_to_nav', request, :ontology_id => @ontology.id, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel, :concept_name => @concept.label, :concept_id => @concept.id
      else
        LOG.add :info, 'visualize_concept_direct', request, :ontology_id => @ontology.id, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel, :concept_name => @concept.label, :concept_id => @concept.id
      end

      # This handles special cases where a passed concept id is for a concept
      # that isn't browsable, usually a property for an ontology.
      if !@concept.is_browsable
        render :partial => "shared/not_browsable", :layout => "ontology"
        return
      end
    end

    # set the current PURL for this term
    @current_purl = @concept.id.start_with?("http://") ? "#{$PURL_PREFIX}/#{@ontology.abbreviation}?conceptid=#{CGI.escape(@concept.id)}" : "#{$PURL_PREFIX}/#{@ontology.abbreviation}/#{CGI.escape(@concept.id)}" if $PURL_ENABLED

    # gets the initial mappings
    @mappings = DataAccess.getConceptMappings(@concept.ontology.ontologyId, @concept.fullId)

    # check to see if user should get the option to delete
    @delete_mapping_permission = check_delete_mapping_permission(@mappings)

    unless @concept.id.to_s.empty?
      # Update the tab with the current concept
      update_tab(@ontology,@concept.id)
    end

    if request.xhr?
      return render 'visualize', :layout => false
    else
      return render 'visualize', :layout => "ontology_viewer"
    end
  end

  def new
    raise Error404 # Disable submission for release migration
    if(params[:id].nil?)
      @ontology = OntologyWrapper.new
      @ontology.userId = session[:user].id
    else
      @ontology = DataAccess.getLatestOntology(params[:id])
    end
    @categories = DataAccess.getCategories()
  end


  def new_view
    raise Error404 # Disable submission for release migration
    if(params[:id].nil? || params[:id].to_i < 1)
      @new = true
      @ontology = OntologyWrapper.new
      @ontology_version_id = params[:version_id]
      @ontology.userId = session[:user].id
    else
      @ontology = DataAccess.getView(params[:id])
    end

    @categories = DataAccess.getCategories()
  end


  def create
    raise Error404 # Disable submission for release migration
    params[:ontology][:isCurrent] = 1
    params[:ontology][:isReviewed] = 1
    params[:ontology][:isFoundry] = 0

    update = !params[:ontology][:ontologyId].nil? && !params[:ontology][:ontologyId].empty?

    # If ontology is going to be pulled, it should not be manual
    if params[:ontology][:isRemote].to_i.eql?(1) && (!params[:ontology][:downloadLocation].nil? || params[:ontology][:downloadLocation].length > 1)
      params[:ontology][:isManual] = 0
    else
      params[:ontology][:isManual] = 1
    end

    if (session[:user].admin? && (params[:ontology][:userId].nil? || params[:ontology][:userId].empty?)) || !session[:user].admin?
      params[:ontology][:userId] = session[:user].id
    end

    @errors = validate(params[:ontology], update)

    if @errors.length < 1
      @ontology = DataAccess.createOntology(params[:ontology])
      if @ontology.kind_of?(Hash) && (@ontology.empty? || @ontology[:error]) || @ontology.nil?
        notice = @ontology.nil? || @ontology[:longMessage].nil? ? "Error submitting ontology, please try again" : @ontology[:longMessage]
        flash[:notice] = notice

        if(params[:ontology][:ontologyId].empty?)
          @ontology = OntologyWrapper.new
          @ontology.from_params(params)
        else
          @ontology = DataAccess.getLatestOntology(params[:ontology][:ontologyId])
        end

        if params[:ontology][:isView].to_i==1
          render :action=>'new_view'
        else
          render :action=>'new'
        end
      else
        # Adds ontology to syndication
        # Don't break here if we encounter problems, the RSS feed isn't critical
        begin
          event = EventItem.new
          event.event_type="Ontology"
          event.event_type_id=@ontology.id
          event.ontology_id=@ontology.ontologyId
          event.save
        rescue
        end

        if params["ontology"]["subscribe_notifications"].eql?("1")
          # begin
         DataAccess.createUserSubscriptions(@ontology.userId, @ontology.ontologyId, NOTIFICATION_TYPES[:all])
          # rescue
          # end
        end

        if @ontology.isView=='true'
          # Cleaning out the cache
          parent_ontology=DataAccess.getOntology(@ontology.viewOnOntologyVersionId)
          CACHE.delete("views::#{parent_ontology.ontologyId}")
          redirect_to "/ontologies/success/#{@ontology.ontologyId}"
        else
          redirect_to "/ontologies/success/#{@ontology.ontologyId}"
        end
      end
    else
      if(params[:ontology][:ontologyId].empty?)
        @ontology = OntologyWrapper.new
        @ontology.from_params(params[:ontology])
        @categories = DataAccess.getCategories()
      else
        @ontology = DataAccess.getLatestOntology(params[:ontology][:ontologyId])
        @ontology.from_params(params[:ontology])
        @categories = DataAccess.getCategories()
      end

      if(params[:ontology][:isView].to_i==1)
        render :action=>'new_view'
      else
        render :action=>'new'
      end
    end
  end

  def submit_success
    @ontology = DataAccess.getOntology(params[:id])
    render :partial => "submit_success", :layout => "ontology"
  end


  def exhibit
    @ontologies = DataAccess.getOntologyList()

    string = ""
    string << "{
           \"items\" : [\n"

    for ont in @ontologies
      string << "{
         \"title\" : \"#{ont.displayLabel}\" , \n
         \"label\": \"#{ont.id}\",  \n
         \"ontologyId\": \"#{ont.ontologyId}\",\n
         \"version\": \"#{ont.versionNumber}\",\n
         \"status\":\"#{ont.versionStatus}\",\n
         \"format\":\"#{ont.format}\"\n"

      if ont.eql?(@ontologies.last)
        string << "}"
      else
        string << "} , "
      end
    end

    response.headers['Content-Type'] = "text/html"

    string<< "]}"
    render :text => string

  end




  ###############################################
  ## These are stub methods that let us invoke partials directly
  ###############################################
  def summary
    @ontology_version = DataAccess.getOntology(params[:id])
    raise Error404 if @ontology_version.nil?
    @ontology = DataAccess.getLatestOntology(@ontology_version.ontologyId)

    # Check to see if user is requesting RDF+XML, return the file from REST service if so
    if request.accept.to_s.eql?("application/rdf+xml")
      user_api_key = session[:user].nil? ? "" : session[:user].apikey
      begin
        rdf_file = RemoteFile.new($REST_URL + "/virtual/ontology/rdf/download/#{@ontology.ontologyId}?apikey=#{$API_KEY}&userapikey=#{user_api_key}")
      rescue Exception => e
        if !e.io.status.nil? && e.io.status[0].to_i == 404
          raise Error404
        end
      end
      send_file rdf_file.path, :type => "appllication/rdf+xml"
      return
    end

    # Grab Metadata
    @groups = DataAccess.getGroups()
    @categories = DataAccess.getCategories()
    @versions = DataAccess.getOntologyVersions(@ontology.ontologyId)
    @versions.sort!{|x,y| y.internalVersion.to_i<=>x.internalVersion.to_i}
    @metrics = DataAccess.getOntologyMetrics(@ontology.id)

    LOG.add :info, 'show_ontology', request, :ontology_id => @ontology.id, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel

    # Check to see if the metrics are from the most recent ontology version
    if !@metrics.nil? && !@metrics.id.eql?(@ontology.id)
      @old_metrics = @metrics
      @old_ontology = DataAccess.getOntology(@old_metrics.id)
    end

    @diffs = DataAccess.getDiffs(@ontology.ontologyId)

    #Grab Reviews Tab
    @reviews = Review.find(:all,:conditions=>{:ontology_id=>@ontology.ontologyId},:include=>:ratings)
    @reviews.sort! {|a,b| b.created_at <=> a.created_at}

    #Grab projects tab
    @projects = Project.find(:all,:conditions=>"uses.ontology_id = '#{@ontology.ontologyId}'",:include=>:uses)

    if request.xhr?
      render :partial => 'metadata', :layout => false
    else
      render :partial => 'metadata', :layout => "ontology_viewer"
    end
  end

  def mappings
    ontology_list = DataAccess.getOntologyList()
    view_list = DataAccess.getViewList()
    @ontology = DataAccess.getOntology(params[:id])
    @ontologies_mapping_count = DataAccess.getMappingCountBetweenOntologies(@ontology.ontologyId)

    ontologies_hash = {}
    ontology_list.each do |ontology|
      ontologies_hash[ontology.ontologyId] = ontology
    end

    view_list.each do |view|
      ontologies_hash[view.ontologyId] = view
    end

    # Add ontologies to the mapping count array, delete if no ontology exists
    @ontologies_mapping_count.delete_if do |ontology|
      ontology['ontology'] = ontologies_hash[ontology['ontologyId']]
      if ontology['ontology'].nil?
        true
      else
        false
      end
    end

    @ontology_id = @ontology.ontologyId
    @ontology_label = @ontology.displayLabel

    @ontologies_mapping_count.sort! {|a,b| a['ontology'].displayLabel.downcase <=> b['ontology'].displayLabel.downcase } unless @ontologies_mapping_count.nil? || @ontologies_mapping_count.length == 0

    if request.xhr?
      render :partial => 'mappings', :layout => false
    else
      render :partial => 'mappings', :layout => "ontology_viewer"
    end
  end

  def notes
    @ontology = DataAccess.getOntology(params[:id])
    @notes = DataAccess.getNotesForOntology(@ontology.ontologyId, true)
    @notes_deletable = false
    @notes.each {|n| @notes_deletable = true if n.deletable?(session[:user])} if @notes.kind_of?(Array)
    @note_link = "/notes/virtual/#{@ontology.ontologyId}/?noteid="
    if request.xhr?
      render :partial => 'notes', :layout => false
    else
      render :partial => 'notes', :layout => "ontology_viewer"
    end
  end

  def widgets
    @ontology = DataAccess.getOntology(params[:id])
    if request.xhr?
      render :partial => 'widgets', :layout => false
    else
      render :partial => 'widgets', :layout => "ontology_viewer"
    end
  end

  private

  def calculate_note_counts(notes)
    note_count_map = {}
    note_count = []

    unless notes.nil? || notes.empty?
      ontology_id = notes[0].ontologyId
      ontology = DataAccess.getLatestOntology(ontology_id)

      notes.each do |note|
        if note.appliesTo['type'].eql?("Class")
          note_count_map[note.appliesTo['id']] = note_count_map[note.appliesTo['id']].nil? ? 1 : note_count_map[note.appliesTo['id']] += 1
        end
      end

      if note_count_map.size > 35
        note_count_map = note_count_map.sort {|a,b| b[1] <=> a[1]}

        # Remove all elements above index 35
        note_count_map.slice!(35, (note_count_map.size - 35))
      end

      note_count_map.each do |concept_id, count|
        begin
          concept = DataAccess.getNode(ontology.id, concept_id, ontology.isView)
          note_count << [ concept.label, count, CGI.escape(concept.fullId_proper) ]
        rescue
          LOG.add :debug, "Failed to retrieve a concept for a note (likely it was from an earlier version of the ontology)"
        end
      end
    end

    note_count.sort! {|a,b| a[0] <=> b[0]}

    note_count
  end

  def validate(params, update=false)
    # strip all spaces from email
    params[:contactEmail] = params[:contactEmail].gsub(" ", "")

    acronyms = DataAccess.getOntologyAcronyms

    errors=[]
    if params[:displayLabel].nil? || params[:displayLabel].length <1
      errors << "Please Enter an Ontology Name"
    end

    if params[:abbreviation].nil? || params[:abbreviation].empty?
      errors << "Please Enter an Ontology Abbrevation"
    elsif params[:abbreviation].include?(" ") || /[\^{}\[\]:;\$=\*`#\|@'\<>\(\)\+,\\\/]/.match(params[:abbreviation])
      errors << "Abbreviations cannot contain spaces or the following characters: <span style='font-family: monospace;'>^{}[]:;$=*`#|@'<>()\+,\\/</span>"
    elsif params[:abbreviation].length < 2
      errors << "Abbreviation must be at least two characters"
    elsif params[:abbreviation].length > 16
      errors << "Abbreviations must be 16 characters or less"
    elsif !/^[A-Za-z]/.match(params[:abbreviation])
      errors << "Abbreviations must start with a letter"
    elsif DataAccess.getOntologyAcronyms.include?(params[:abbreviation].downcase)
      # We matched an existing acronym, but is it already ours from a previous version?
      unless update && !DataAccess.getLatestOntology(params[:ontologyId]).nil? && DataAccess.getLatestOntology(params[:ontologyId]).abbreviation.downcase.eql?(params[:abbreviation].downcase)
        errors << "That abbreviation is already in use. Please choose another."
      end
    end

    if params[:dateReleased].nil? || params[:dateReleased].length < 1
      errors << "Please Enter the Date Released"
    elsif params[:dateReleased].match(/[0-9]{1,2}\/[0-9]{1,2}\/[0-9]{4}/).nil?
      errors << "Please Enter a Date Formatted as MM/DD/YYYY"
    end

    unless update
      if params[:isRemote].to_i.eql?(0) && (params[:filePath].nil? || params[:filePath].length < 1)
        errors << "Please Choose a File"
      end

      if params[:isRemote].to_i.eql?(0) && !params[:filePath].nil? && params[:filePath].size.to_i > $MAX_UPLOAD_SIZE && !session[:user].admin?
        errors << "File is too large"
      end

      if params[:isRemote].to_i.eql?(1) && (params[:downloadLocation].nil? || params[:downloadLocation].length < 1)
        errors << "Please Enter a URL"
      end

      if params[:isRemote].to_i.eql?(1) && (!params[:downloadLocation].nil? || params[:downloadLocation].length > 1)
        begin
          downloadLocation = URI.parse(params[:downloadLocation])
          if downloadLocation.scheme.nil? || downloadLocation.host.nil?
            errors << "Please enter a valid URL"
          end
        rescue URI::InvalidURIError
          errors << "Please enter a valid URL"
        end

        if !remote_file_exists?(params[:downloadLocation])
          errors << "The URL you provided for us to load an ontology from doesn't reference a valid file"
        end
      end
    end

    if params[:contactName].nil? || params[:contactName].length < 1
      errors << "Please Enter the Contact Name"
    end

    if params[:contactEmail].nil? || params[:contactEmail].length <1 || !params[:contactEmail].match(/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i)
      errors << "Please Enter the Contact Email"
    end

    # options that use default text, remove them from the hash
    default_text = "use default"
    params.each do |name,value|
      if value.eql?(default_text)
        params[name] = ""
      end
    end

    # Check for metadata only and set parameter
    if params[:isRemote].to_i.eql?(3)
      params[:isMetadataOnly] = 1
    end

    return errors
  end

end
