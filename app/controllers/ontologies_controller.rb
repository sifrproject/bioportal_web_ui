class OntologiesController < ApplicationController

  require 'cgi'
  
  #caches_page :index
  
  helper :concepts  
  layout 'ontology'
  
  before_filter :authorize, :only=>[:edit,:update,:create,:new]
  
  # GET /ontologies
  # GET /ontologies.xml
  def index
    @ontologies = DataAccess.getOntologyList() # -- Gets list of ontologies
    @categories = DataAccess.getCategories()
    @groups = DataAccess.getGroups()
    @last_notes= MarginNote.find(:all,:order=>'created_at desc',:limit=>5)    
    @last_mappings = Mapping.find(:all,:order=>'created_at desc',:limit=>5)
    
    LOG.add :info, 'show_all_ontologies', request
    
    @notes={} # Gets list of notes for the ontologies
    #    for ont in @ontologies
    #gets last note.. not the best way to do this
    #      note = MarginNote.find(:first,:conditions=>{:ontology_id => ont.id},:order=>'margin_notes.id desc')
    #      unless note.nil?
    #        @notes[ont.id]=note
    #      end
    
    #    end
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @ontologies.to_xml }
    end
  end
  
  # GET /ontologies/1
  # GET /ontologies/1.xml
  def show
    # Grab Metadata
    @ontology = DataAccess.getOntology(params[:id])
    @groups = DataAccess.getGroups()
    @categories = DataAccess.getCategories()
    @versions = DataAccess.getOntologyVersions(@ontology.ontologyId)
    @metrics = DataAccess.getOntologyMetrics(@ontology.id)
    @notes = DataAccess.getNotesForOntology(@ontology.ontologyId, false, true)
    @note_link = "/notes/virtual/#{@ontology.ontologyId}/?noteid="
    
    LOG.add :info, 'show_ontology', request, :ontology_id => @ontology.id, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel
    
    # Check to see if the metrics are from the most recent ontology version
    if !@metrics.nil? && !@metrics.id.eql?(@ontology.id)
      @old_metrics = @metrics
      @old_ontology = DataAccess.getOntology(@old_metrics.id)
    end
    
    @diffs = DataAccess.getDiffs(@ontology.ontologyId)

    @notes_cloud = calculate_note_counts(@notes)

    mapping_tag_query = "select source_id,count(source_id) as con_count,source_name from mappings where source_ont = #{@ontology.ontologyId} group by source_id order by source_id"            
    @mappings = ActiveRecord::Base.connection.select_rows(mapping_tag_query);
    
    if @mappings.size > 35
      mapping_tag_query = "select source_id,count(source_id) as con_count,source_name from mappings where source_ont = #{@ontology.ontologyId} group by source_id order by con_count desc limit 35"
      @mappings = ActiveRecord::Base.connection.select_rows(mapping_tag_query);
      @mappings.sort! { |a,b| a[2] <=> b[2] }
    end

    #Grab Reviews Tab
    @reviews = Review.find(:all,:conditions=>{:ontology_id=>@ontology.ontologyId},:include=>:ratings)
    
    #Grab projects tab
    @projects = Project.find(:all,:conditions=>"uses.ontology_id = '#{@ontology.ontologyId}'",:include=>:uses)

    render :action=>'show'
    
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
    redirect_to $REST_URL + "/ontologies/download/#{@ontology.id}"
  end
  
  def update
    params[:ontology][:isReviewed]=1
    params[:ontology][:isFoundry]=0
    unless !authorize_owner(params[:ontology][:userId].to_i)
      return
    end
    
    @errors = validate(params[:ontology],true)
    
    if @errors.length < 1
      test = params[:ontology][:isView]
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
    @ontology = DataAccess.getOntology(params[:id])   
    
    authorize_owner(@ontology.userId.to_i)
    
    @categories = DataAccess.getCategories()
  end

  def edit_view
    @ontology = DataAccess.getView(params[:id])   
    
    authorize_owner(@ontology.userId.to_i)
    
    @categories = DataAccess.getCategories()
  end
  
  # GET /visualize/:ontology
  def visualize
    # Hack to make ontologyid and conceptid work in addition to id and ontology params
    params[:id] = params[:id].nil? ? params[:conceptid] : params[:id]
    params[:ontology] = params[:ontology].nil? ? params[:ontologyid] : params[:ontology]
    
    # Error checking
    if params[:ontology].nil? || params[:id] && params[:ontology].nil?
      @error = "Please provide an ontology id or concept id with an ontology id."
      return
    end
    
    if !params[:id].nil? && params[:id].empty?
      params[:id] = nil
    end
    
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
    
    if @ontology.statusId.to_i.eql?(6)
      @latest_ontology = DataAccess.getLatestOntology(@ontology.ontologyId)
      params[:ontology] = @latest_ontology.id
      flash[:notice] = "The version of <b>#{@ontology.displayLabel}</b> you were attempting to view (#{@ontology.versionNumber}) has been archived and is no longer available for exploring. You have been redirected to the most recent version (#{@latest_ontology.versionNumber})."
      concept_id = params[:id] ? "?conceptid=#{params[:id]}" : ""
      redirect_to "/visualize/#{@latest_ontology.id}#{concept_id}", :status => :moved_permanently
      return
    end
    
    unless params[:id]
      # get the top level nodes for the root
      @root = TreeNode.new()
      nodes = @ontology.topLevelNodes(view)
      nodes.sort!{|x,y| x.label.downcase<=>y.label.downcase}
      for node in nodes
        if node.label.downcase.include?("obsolete") || node.label.downcase.include?("deprecated")
          nodes.delete(node)
          nodes.push(node)
        end
      end
      
      @root.set_children(nodes)
      
      # get the initial concept to display
      @concept = DataAccess.getNode(@ontology.id,@root.children.first.id,view)
      
      # Some ontologies have "too many children" at their root. These will not process and are handled here.
      # TODO: This should use a proper error-handling technique with custom exceptions
      if @concept.nil?
        @error = "The requested term could not be found."
        return
      end

      LOG.add :info, 'visualize_ontology', request, :ontology_id => @ontology.id, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel, :concept_name => @concept.label, :concept_id => @concept.id
    else
      # if the id is coming from a param, use that to get concept
      @concept = DataAccess.getNode(@ontology.id,params[:id],view)

      # TODO: This should use a proper error-handling technique with custom exceptions
      if @concept.nil?
        @error = "The requested term could not be found."
        return
      end
      
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
      
      # Create the tree
      rootNode = @concept.path_to_root
      @root = TreeNode.new()
      @root.set_children(rootNode.children)
    end
    
    # gets the initial mappings
    @mappings = Mapping.find(:all, :conditions=>{:source_ont => @ontology.ontologyId, :source_id => @concept.id})
    # builds the margin note tab
    @margin_notes = MarginNote.find(:all,:conditions=>{:ontology_id => @concept.ontology_id, :concept_id => @concept.id,:parent_id =>nil})
    # needed to prepopulate the margin note
    @margin_note = MarginNote.new
    @margin_note.concept_id = @concept.id
    @margin_note.ontology_version_id = @concept.version_id
    @margin_note.ontology_id=@concept.ontology_id
    
    unless @concept.id.to_s.empty?
      # Update the tab with the current concept
      update_tab(@ontology,@concept.id)
    end
    
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @ontology.to_xml }
    end
  end
  
  def new
    if(params[:id].nil?)
      @ontology = OntologyWrapper.new
    else
      @ontology = DataAccess.getLatestOntology(params[:id])
    end
    @categories = DataAccess.getCategories()
  end
  
  
  def new_view
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
    params[:ontology][:isCurrent] = 1
    params[:ontology][:isReviewed] = 1
    params[:ontology][:isFoundry] = 0
    
    # If ontology is going to be pulled, it should not be manual
    if params[:ontology][:isRemote].to_i.eql?(1) && (!params[:ontology][:downloadLocation].nil? || params[:ontology][:downloadLocation].length > 1)
      params[:ontology][:isManual] = 0
    else
      params[:ontology][:isManual] = 1
    end
      

    if (session[:user].admin? && (params[:ontology][:userId].nil? || params[:ontology][:userId].empty?)) || !session[:user].admin?
      params[:ontology][:userId]= session[:user].id
    end

    @errors = validate(params[:ontology])

    if @errors.length < 1
      @ontology = DataAccess.createOntology(params[:ontology])
      if @ontology.kind_of?(Hash) && @ontology[:error]        
        flash[:notice]=@ontology[:longMessage]
        
        if(params[:ontology][:ontologyId].empty?)
          @ontology = OntologyWrapper.new
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
        
        # Display message to user
        if @ontology.metadata_only?
          flash[:notice] = "Thank you for submitting your ontology to #{$SITE}.
            Users can now see your ontology in our ontology list but they cannot explore or search it.
            To enable exploring and searching, please upload a full version of your ontology."
        elsif @ontology.isView.eql?("true")
          flash[:notice] = "Thank you for submitting your ontology view to #{$SITE}.
            We will now put your ontology in the queue to be processed.
            Please keep in mind that it may take up to several hours before #{$SITE} users will be able to explore and search your ontology."
        else
          flash[:notice] = "Thank you for submitting your ontology to #{$SITE}.
            We will now put your ontology in the queue to be processed.
            Please keep in mind that it may take up to several hours before #{$SITE} users will be able to explore and search your ontology."
        end
        
        if @ontology.isView=='true'
          # Cleaning out the cache
          parent_ontology=DataAccess.getOntology(@ontology.viewOnOntologyVersionId)
          CACHE.delete("views::#{parent_ontology.ontologyId}")
          redirect_to '/ontologies/'+@ontology.viewOnOntologyVersionId+'#views'
        else
          redirect_to ontology_path(@ontology)
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
    render :text=> string
    
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
  
  def validate(params, isupdate=false)
    # strip all spaces from email
    params[:contactEmail] = params[:contactEmail].gsub(" ", "") 
    
    errors=[]
    if params[:displayLabel].nil? || params[:displayLabel].length <1
      errors << "Please Enter an Ontology Name"
    end
    
    if params[:versionNumber].nil? || params[:versionNumber].length <1
      errors << "Please Enter an Ontology Version"
    end
    
    if params[:dateReleased].nil? || params[:dateReleased].length <1
      errors << "Please Enter the Date Released"
    elsif params[:dateReleased].match(/[0-9]{1,2}\/[0-9]{1,2}\/[0-9]{4}/).nil?
      errors << "Please Enter a Date Formatted as MM/DD/YYYY"
    end
    
    unless isupdate
      if params[:isRemote].to_i.eql?(0) && (params[:filePath].nil? || params[:filePath].length < 1)
        errors << "Please Choose a File"
      end
      
      if params[:isRemote].to_i.eql?(0) && !params[:filePath].nil? && params[:filePath].size.to_i > 20000000 && !session[:user].admin?
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
