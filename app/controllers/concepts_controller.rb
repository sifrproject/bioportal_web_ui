class ConceptsController < ApplicationController
  # GET /concepts
  # GET /concepts.xml
   
  layout 'ontology'

  # GET /concepts/1
  # GET /concepts/1.xml
  def show
    @ontology = DataAccess.getOntology(params[:ontology])

    # If we're looking for children, just use the light version of the call
    if params[:callback].eql?("children")
      @concept = DataAccess.getLightNode(params[:ontology],params[:id])
    else
      @concept = DataAccess.getNode(params[:ontology],params[:id])
    end

    # TODO: This should use a proper error-handling technique with custom exceptions
    if @concept.nil?
      @error = "The requested term could not be found."

      if request.xhr?
        render :text => @error
        return
      else
        render :file=> '/ontologies/visualize',:use_full_path =>true, :layout=>'ontology' # done this way to share a view
        return
      end
    end

    # This handles special cases where a passed concept id is for a concept
    # that isn't browsable, usually a property for an ontology.
    if !@concept.is_browsable
      render :partial => "shared/not_browsable", :layout => "ontology"
      return
    end
    
    if request.xhr?
      show_ajax_request # process an ajax call
    else
      # We only want to log concept loading, not showing a list of child concepts
      LOG.add :info, 'visualize_concept_direct', request, :ontology_id => @ontology.id, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel, :concept_name => @concept.name, :concept_id => @concept.id if @concept && @ontology

      show_uri_request # process a full call
      render :file=> '/ontologies/visualize',:use_full_path =>true, :layout=>'ontology' # done this way to share a view
    end
  end
  
  def virtual
    @ontology = DataAccess.getLatestOntology(params[:ontology])
    @versions = DataAccess.getOntologyVersions(@ontology.ontologyId)
    @concept =  DataAccess.getNode(@ontology.id,params[:id])
    
    if @ontology.isRemote.to_i.eql?(1)
      redirect_to "/ontologies/#{@ontology.id}"
      return
    end
    
    if @ontology.statusId.to_i.eql?(3) && @concept
      LOG.add :info, 'show_virtual_concept', request, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel, :concept_name => @concept.name, :concept_id => @concept.id
      redirect_to "/visualize/#{@ontology.id}/#{@concept.id}"
      return
    elsif @ontology.statusId.to_i.eql?(3)
      LOG.add :info, 'show_virtual', request, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel
      redirect_to "/visualize/#{@ontology.id}"
      return
    else
      for version in @versions
        if version.statusId.to_i.eql?(3) && @concept
          LOG.add :info, 'show_virtual_concept', request, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel, :concept_name => @concept.name, :concept_id => @concept.id
          redirect_to "/visualize/#{version.id}/#{@concept.id}"
          return
        elsif version.statusId.to_i.eql?(3)
          LOG.add :info, 'show_virtual', request, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel
          redirect_to "/visualize/#{version.id}"
          return
        end
      end
      redirect_to "/ontologies/#{@ontology.id}"
      return
    end
  end
  

  def exhibit
    time = Time.now
    #puts "Starting Retrieval"
    @concept =  DataAccess.getNode(params[:ontology],params[:id])
    #puts "Finished in #{Time.now- time}"
    
    string =""
    string << "{
           \"items\" : [\n
       	{ \n
       \"title\": \"#{@concept.name}\" , \n
       \"label\": \"#{@concept.id}\" \n"
    for property in @concept.properties.keys
      if @concept.properties[property].empty?
        next
      end
      
      string << " , "
      
      string << "\"#{property.gsub(":","")}\" : \"#{@concept.properties[property]}\"\n"
      
    end
    
    if @concept.children.length > 0
      string << "} , \n"
    else
      string << "}"
    end
    
    
    for child in @concept.children
      string << "{
         \"title\" : \"#{child.name}\" , \n
         \"label\": \"#{child.id}\"  \n"
      for property in child.properties.keys
        if child.properties[property].empty?
          next
        end
        
        string << " , "        
        
        string << "\"#{property.gsub(":","")}\" : \"#{child.properties[property]}\"\n"
      end
      if child.eql?(@concept.children.last)
        string << "}"
      else
        string << "} , "
      end
    end
    
    response.headers['Content-Type'] = "text/html" 
    
    string<< "]}"
    
    render :text=> string
  end


  
  # PRIVATE -----------------------------------------
  private
    
    def show_ajax_request
       case params[:callback]
          when 'load' # Load pulls in all the details of a node
            time = Time.now
            gather_details
            LOG.add :debug, "Processed concept details (#{Time.now - time})"
            
            # We only want to log concept loading, not showing a list of child concepts
            LOG.add :info, 'visualize_concept', request, :ontology_id => @ontology.id, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel, :concept_name => @concept.name, :concept_id => @concept.id if @concept && @ontology
  
            render :partial => 'load'
          when 'children' # Children is called only for drawing the tree
            @children =[]
            start_tree = Time.now
            for child in @concept.children
              @children << TreeNode.new(child)
              @children.sort!{|x,y| x.name.downcase<=>y.name.downcase}
            end
            LOG.add :debug,  "Get children (#{Time.now - start_tree})"
            render :partial => 'childNodes'
        end    
    end
    
    # gathers the full set of data for a node
    def show_uri_request
      gather_details
      build_tree
    end
    
    # gathers the information for a node
    def gather_details
      
   #    sids = [] #stores the thread IDs
      
    #  sids << spawn(:method => :thread) do  #threaded implementation to improve performance
        #builds the mapping tab
        @mappings = Mapping.find(:all, :conditions=>{:source_ont => @concept.ontology_id, :source_id => @concept.id})    
        
        #builds the margin note tab
        @margin_notes = MarginNote.find(:all,:conditions=>{:ontology_id => @concept.ontology_id, :concept_id => @concept.id,:parent_id =>nil})
        #needed to prepopulate the margin note
        @margin_note = MarginNote.new
        @margin_note.concept_id = @concept.id
        @margin_note.ontology_version_id = @concept.version_id
        @margin_note.ontology_id=@concept.ontology_id
     # end   
        
      #wait(sids) #waits for threads to finish
      
      update_tab(@ontology,@concept.id) #updates the 'history' tab with the current node
      
    end
    
    def build_tree
      # find path to root    
      rootNode = @concept.path_to_root
      @root = TreeNode.new()
      @root.set_children(rootNode.children)
    end
 
  
end
