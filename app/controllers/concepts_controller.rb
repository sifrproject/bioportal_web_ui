require 'cgi'

class ConceptsController < ApplicationController
  # GET /concepts
  # GET /concepts.xml

  layout 'ontology'

  # GET /concepts/1
  # GET /concepts/1.xml
  def show
    # Handle multiple methods of passing concept ids
    params[:id] = params[:id] ? params[:id] : params[:conceptid]
    too_many_children_override = params[:too_many_children_override].eql?("true")

    if params[:id].nil? || params[:id].empty?
      render :text => "Error: You must provide a valid concept id"
      return
    end

    if params[:callback].eql?('children') && params[:child_size].to_i > $MAX_CHILDREN && params[:child_size].to_i < $MAX_POSSIBLE_DISPLAY && !too_many_children_override
      retry_link = "<a class='too_many_children_override' href='/ajax_concepts/#{params[:ontology]}/?conceptid=#{CGI.escape(params[:id])}&callback=children&too_many_children_override=true'>Get all terms</a>"
      render :text => "<div style='background: #eeeeee; padding: 5px; width: 80%;'>There are #{params[:child_size]} terms at this level. Retrieving these may take several minutes. #{retry_link}</div>"
      return
    elsif params[:callback].eql?('children') && params[:child_size].to_i > $MAX_POSSIBLE_DISPLAY && !too_many_children_override
      render :text => "<div style='background: #eeeeee; padding: 5px; width: 80%;'>There are #{params[:child_size]} terms at this level. Please use the \"Jump To\" to search for specific terms.</div>"
      return
    end

    @ontology = DataAccess.getOntology(params[:ontology])

    if @ontology.statusId.to_i.eql?(6)
      @latest_ontology = DataAccess.getLatestOntology(@ontology.ontologyId)
      params[:ontology] = @latest_ontology.id
      flash[:notice] = "The version of <b>#{@ontology.displayLabel}</b> you were attempting to view (#{@ontology.versionNumber}) has been archived and is no longer available for exploring. You have been redirected to the most recent version (#{@latest_ontology.versionNumber})."
      concept_id = params[:id] ? "?conceptid=#{params[:id]}" : ""
      redirect_to "/visualize/#{@latest_ontology.id}#{concept_id}", :status => :moved_permanently
      return
    end

    # If we're looking for children, just use the light version of the call
    if params[:callback].eql?("children")
      if too_many_children_override
        @concept = DataAccess.getNode(@ontology.id, params[:id], 99999999999)
      else
        @concept = DataAccess.getNode(@ontology.id, params[:id])
      end
    else
      @concept = DataAccess.getNode(@ontology.id, params[:id])
    end

    if @concept.nil?
      raise Error404
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
      LOG.add :info, 'visualize_concept_direct', request, :ontology_id => @ontology.id, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel, :concept_name => @concept.label, :concept_id => @concept.id if @concept && @ontology

      show_uri_request # process a full call
      render :file=> '/ontologies/visualize',:use_full_path =>true, :layout=>'ontology' # done this way to share a view
    end
  end

  def show_label
    @ontology = DataAccess.getOntology(params[:ontology])
    begin
      term_label = DataAccess.getNodeLabel(@ontology.id, params[:concept]).label_html
    rescue Exception => e
      term_label = "<span title='This term cannot be viewed because the id cannot be found in the most recent version of the ontology' style='cursor: help;'>#{params[:concept]}</span>"
    end
    render :text => term_label
  end

  def show_definition
    @ontology = DataAccess.getOntology(params[:ontology])
    term = DataAccess.getLightNode(@ontology.id, params[:concept])
    render :text => term.definitions
  end

  def show_tree
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

    if !@ontology.flat? && (!params[:conceptid] || params[:conceptid].empty? || params[:conceptid].eql?("root"))
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
      if @concept.nil?
        raise Error404
      end

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

      @tree_concept = TreeNode.new(@concept)

      @root = TreeNode.new
      @root.children = [@tree_concept]
    elsif @ontology.flat? && params[:conceptid]
      # Display only the requested term in the tree
      @concept = DataAccess.getNode(@ontology.id, params[:conceptid], nil, view)
      @root = TreeNode.new
      @root.children = [TreeNode.new(@concept)]
    else
      # if the id is coming from a param, use that to get concept
      @concept = DataAccess.getNode(@ontology.id,params[:conceptid],view)

      if @concept.nil?
        raise Error404
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
      @root.set_children(rootNode.children, rootNode)
    end

    render :partial => "ontologies/treeview"
  end

  def virtual
    # Hack to make ontologyid and conceptid work in addition to id and ontology params
    params[:id] = params[:id].nil? ? params[:conceptid] : params[:id]
    params[:ontology] = params[:ontology].nil? ? params[:ontologyid] : params[:ontology]

    if !params[:id].nil? && params[:id].empty?
      params[:id] = nil
    end

    @ontology = DataAccess.getLatestOntology(params[:ontology])
    @versions = DataAccess.getOntologyVersions(@ontology.ontologyId)
    unless params[:id].nil? || params[:id].empty?
      @concept = DataAccess.getNode(@ontology.id,params[:id])
    end

    if @ontology.metadata_only?
      redirect_to "/ontologies/#{@ontology.id}"
      return
    end

    if @ontology.statusId.to_i.eql?(3) && @concept
      LOG.add :info, 'show_virtual_concept', request, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel, :concept_name => @concept.label, :concept_id => @concept.id
      redirect_to "/visualize/#{@ontology.id}/?conceptid=#{CGI.escape(@concept.id)}"
      return
    elsif @ontology.statusId.to_i.eql?(3)
      LOG.add :info, 'show_virtual', request, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel
      redirect_to "/visualize/#{@ontology.id}"
      return
    else
      for version in @versions
        if version.statusId.to_i.eql?(3) && @concept
          LOG.add :info, 'show_virtual_concept', request, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel, :concept_name => @concept.label, :concept_id => @concept.id
          redirect_to "/visualize/#{version.id}/?conceptid=#{CGI.escape(@concept.id)}"
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

  # Renders a details pane for a given ontology/term
  def details
    raise Error404 if params[:conceptid].nil? || params[:conceptid].empty?
    @ontology = DataAccess.getOntology(params[:ontology])
    @concept = DataAccess.getNode(@ontology.id, params[:conceptid], params[:childrenlimit])

    if params[:styled].eql?("true")
      render :partial => "details", :layout => "partial"
    else
      render :partial => "details"
    end
  end

  def flexviz
    render :partial => "flexviz", :layout => "partial"
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
       \"title\": \"#{@concept.label_html}\" , \n
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
         \"title\" : \"#{child.label_html}\" , \n
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
      LOG.add :info, 'visualize_concept_browse', request, :ontology_id => @ontology.id, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel, :concept_name => @concept.label, :concept_id => @concept.id if @concept && @ontology

      render :partial => 'load'
    when 'children' # Children is called only for drawing the tree
      @children =[]
      start_tree = Time.now
      for child in @concept.children
        @children << TreeNode.new(child, @concept)
        @children.sort!{|x,y| x.label.downcase<=>y.label.downcase} unless @children.empty?
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
      @mappings = DataAccess.getConceptMappings(@concept.ontology.ontologyId, @concept.id)
      # check to see if user should get the option to delete
      @delete_mapping_permission = check_delete_mapping_permission(@mappings)
      update_tab(@ontology, @concept.id) #updates the 'history' tab with the current node
    end

    def build_tree
      # find path to root
      rootNode = @concept.path_to_root
      @root = TreeNode.new()
      @root.set_children(rootNode.children, rootNode) unless rootNode.nil?
    end


end
