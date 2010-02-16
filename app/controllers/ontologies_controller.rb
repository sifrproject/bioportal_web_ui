# This require is here to prevent problems when trying to get models
# from the cache. Sometimes, even in the production env, Rails wouldn't have
# the model cached and an exception would be thrown saying that the
# model was unknown/undefined.
require_dependency 'ontology_metrics_wrapper'
require_dependency 'groups'

class OntologiesController < ApplicationController
  
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
    
    LOG.add :info, 'show_ontology', request, :ontology_id => @ontology.id, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel
    
    # Check to see if the metrics are from the most recent ontology version
    if !@metrics.nil? && !@metrics.id.eql?(@ontology.id)
      @old_metrics = @metrics
      @old_ontology = DataAccess.getOntology(@old_metrics.id)
    end
    
    @diffs = DataAccess.getDiffs(@ontology.ontologyId)
    
    note_tag_query = "select concept_id,count(concept_id) as con_count from margin_notes where ontology_id = #{@ontology.ontologyId} group by concept_id order by concept_id"
    @notes = ActiveRecord::Base.connection.select_rows(note_tag_query);
    
    if @notes.size > 100
      note_tag_query = "select concept_id,count(concept_id) as con_count from margin_notes where ontology_id = #{@ontology.ontologyId} group by concept_id order by con_count limit 100 "
      @notes = ActiveRecord::Base.connection.select_rows(note_tag_query);
    end
    
    mapping_tag_query = "select source_id,count(source_id) as con_count,source_name from mappings where source_ont = #{@ontology.ontologyId} group by source_id order by source_id"            
    @mappings = ActiveRecord::Base.connection.select_rows(mapping_tag_query);
    
    if @mappings.size > 100
      mapping_tag_query = "select source_id,count(source_id) as con_count,source_name from mappings where source_ont = #{@ontology.ontologyId} group by source_id order by con_count limit 100"
      @mappings = ActiveRecord::Base.connection.select_rows(mapping_tag_query);        
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
    
    if @ontology.isRemote.to_i.eql?(1)
      redirect_to "/ontologies/#{@ontology.id}"
      return
    end
    
    if @ontology.statusId.to_i.eql?(3)
      redirect_to "/visualize/#{@ontology.id}"
      return
    else
      for version in @versions
        if version.statusId.to_i.eql?(3)
          redirect_to "/visualize/#{version.id}"
          return
        end
      end
      redirect_to "/ontologies/#{@ontology.id}"
      return
    end
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
      @ontology = DataAccess.updateOntology(params[:ontology],params[:id])      
      
      if @ontology.kind_of?(Hash) && @ontology[:error]        
        flash[:notice]=@ontology[:longMessage]
        redirect_to ontology_path(:id=>params[:id])
      else
        redirect_to ontology_path(@ontology)
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
  
  # GET /visualize/:ontology
  def visualize
    # Hack to make ontologyid and conceptid work in addition to id and ontology params
    params[:id] = params[:id].nil? ? params[:conceptid] : params[:id]
    params[:ontology] = params[:ontology].nil? ? params[:ontologyid] : params[:ontology]
    
    # Error checking
    if params[:ontology].nil? || params[:id] && params[:ontology].nil?
      return "Please provide an ontology id or concept id with an ontology id."
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
    
    unless params[:id]
      # get the top level nodes for the root
      @root = TreeNode.new()
      nodes = @ontology.topLevelNodes(view)
      nodes.sort!{|x,y| x.name.downcase<=>y.name.downcase}
      for node in nodes
        if node.name.downcase.include?("obsolete") || node.name.downcase.include?("deprecated")
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
      
      LOG.add :info, 'visualize_ontology', request, :ontology_id => @ontology.id, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel, :concept_name => @concept.name, :concept_id => @concept.id
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
        LOG.add :info, 'jump_to_nav', request, :ontology_id => @ontology.id, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel, :concept_name => @concept.name, :concept_id => @concept.id
      else
        LOG.add :info, 'visualize_concept', request, :ontology_id => @ontology.id, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel, :concept_name => @concept.name, :concept_id => @concept.id
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
    params[:ontology][:isCurrent]=1
    params[:ontology][:isReviewed]=1
    params[:ontology][:isFoundry]=0
    params[:ontology][:isManual]=1

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
        if(params[:ontology][:isView].to_i==1)
          render :action=>'new_view'
        else
          render :action=>'new'  
        end
      else
        
        #puts "Ontology Error: #{@ontology.inspect}"
        #adds ontology to syndication
        event = EventItem.new
        event.event_type="Ontology"
        event.event_type_id=@ontology.id
        event.ontology_id=@ontology.ontologyId
        event.save
        flash[:notice]="Thank you for submitting your ontology to BioPortal.
          We will now put your ontology in the queue to be processed.
           Please keep in mind that it may take up to several hours before BioPortal users will be able to explore and search your ontology"
        
        if(@ontology.isView=='true')
          #cleaning out the cache
          parent_ontology=DataAccess.getOntology(@ontology.viewOnOntologyVersionId)
          CACHE.delete("views::#{parent_ontology.ontologyId}")
          redirect_to '/ontologies/'+@ontology.viewOnOntologyVersionId
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
  
  def validate(params, isupdate=false)
    errors=[]
    if params[:displayLabel].nil? || params[:displayLabel].length <1
      errors << "Please Enter an Ontology Name"
    end
    if params[:versionNumber].nil? || params[:versionNumber].length <1
      errors << "Please Enter an Ontology Version"
    end
    if params[:dateReleased].nil? || params[:dateReleased].length <1
      errors << "Please Enter the Date Released"
    end
    unless isupdate
      if params[:isRemote].to_i.eql?(0) && (params[:filePath].nil? || params[:filePath].length <1)
        errors << "Please Choose a File"
      end
      if params[:isRemote].to_i.eql?(0) && params[:filePath].size.to_i > 20000000 && !session[:user].admin?
        errors << "File is too large"
      end
      if params[:isRemote].to_i.eql?(1) && (params[:urn].nil? || params[:urn].length <1)
        errors << "Please Enter a URL"
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
    
    return errors
  end
  
end
