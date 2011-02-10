require 'MappingLoader'
class MappingsController < ApplicationController
 

  # GET /mappings/new
  
  layout 'ontology'
  before_filter :authorize, :only=>[:create,:new]
  
  def index
    ontology_list = DataAccess.getOntologyList()
    views_list = DataAccess.getViewList()
    ontologies_mapping_count = DataAccess.getMappingCountOntologies

    ontologies_hash = {}
    ontology_list.each do |ontology|
      ontologies_hash[ontology.ontologyId] = ontology
    end
    
    views_list.each do |view|
      ontologies_hash[view.ontologyId] = view
    end

    @options = {}
    ontologies_mapping_count.each do |ontology|
      @options[ontologies_hash[ontology['ontologyId']].displayLabel + " (#{ontology['totalMappings']})"] = ontologies_hash[ontology['ontologyId']].id unless ontologies_hash[ontology['ontologyId']].nil?
    end
    
    @options = @options.sort
  end
  
  def service
    ontology = DataAccess.getLatestOntology(params[:ontology])
    
    if params[:id]
      concept = DataAccess.getNode(ontology.id,params[:id])    
      from =[]
      to = []
      from_res = ActiveRecord::Base.connection().execute("SELECT * from mappings  where source_ont =#{ontology.ontologyId} AND source_id = '#{concept.id}'")
      from_res.each_hash(with_table=false) {|x| from<<x}

      to_res = ActiveRecord::Base.connection().execute("SELECT * from mappings  where destination_ont =#{ontology.ontologyId} AND destination_id = '#{concept.id}'")
      to_res.each_hash(with_table=false) {|x| to<<x}

    else
      from=[]
      to=[]
      from_res = ActiveRecord::Base.connection().execute("SELECT * from mappings  where source_ont =#{ontology.ontologyId} ")
      to_res = ActiveRecord::Base.connection().execute("SELECT * from mappings  where destination_ont =#{ontology.ontologyId}")
      from_res.each_hash(with_table=false) {|x| from<<x}
      to_res.each_hash(with_table=false) {|x| to<<x}

    end
  
    #puts from.inspect
    #puts to.inspect
    mappings = {:mapping_from=>from,:mapping_to=>to}
    
    render :xml=> mappings
  end
  
  def ontology_service
    
  end
  
  
  def count
    ontology_list = DataAccess.getOntologyList()
    view_list = DataAccess.getViewList()
    @ontology = DataAccess.getOntology(params[:ontology])
    @ontologies_mapping_count = DataAccess.getMappingCountBetweenOntologies(@ontology.ontologyId)

    ontologies_hash = {}
    ontology_list.each do |ontology|
      ontologies_hash[ontology.ontologyId] = ontology
    end
    
    view_list.each do |view|
      ontologies_hash[view.ontologyId] = view
    end
    
    @ontologies_mapping_count.each do |ontology|
      ontology['ontology'] = ontologies_hash[ontology['ontologyId']]
    end

    @ontology_id = @ontology.ontologyId
    @ontology_label = @ontology.displayLabel

    @ontologies_mapping_count.sort! {|a,b| a['ontology'].displayLabel.downcase <=> b['ontology'].displayLabel.downcase }

    render :partial => 'count'
  end
  
  def show
    @ontology = DataAccess.getLatestOntology(params[:id])
    @target_ontology = DataAccess.getLatestOntology(params[:target])
    
    
    if params[:rdf].nil? || !params[:rdf].eql?("rdf")
	    @mapping_pages = DataAccess.getBetweenOntologiesMappings(@ontology.ontologyId, @target_ontology.ontologyId, params[:page], 100, :user_id => params[:user], :sources => params[:map_source], :unidirectional => "true")
	    @mappings = {}
	    @map_sources = []
	    @service_users = DataAccess.getUsers.sort{|x,y| x.username.downcase <=> y.username.downcase}
	    @users = []
	    user_count = DataAccess.getMappingCountOntologyUsers(@ontology.ontologyId)
	    
	    user_count.each do |x|
	      for user in @service_users
	        if x['userId'].to_i == user.id.to_i
	          @users << user
	        end
	      end
	    end
	    
	    for map in @mapping_pages
	      @map_sources << map.map_source.gsub(/(<[^>]*>)/mi, "") unless map.map_source.nil? || map.map_source.empty?
	      @map_sources.uniq!
	      
	      if @mappings[map.source_id].nil?
	        @mappings[map.source_id] = [{:source_ont_name=>map.source_ont_name,:destination_ont_name=>map.destination_ont_name,:source_ont=>map.source_ont,:source_name=>map.source_name,:destination_ont=>map.destination_ont,:destination_name=>map.destination_name,:destination_id=>map.destination_id,:users=>[map.user.username],:count=>1}]
	      else
	        @mappings[map.source_id]
	        
	        found = false
	        for mapping in @mappings[map.source_id]
	          if mapping[:destination_id].eql?(map.destination_id)
	            found = true
	            mapping[:users] << map.user.username
	            mapping[:users].uniq!
	            mapping[:count] += 1
	          end  
	        end
	        
	        unless found
	         @mappings[map.source_id] << {:source_ont_name=>map.source_ont_name,:destination_ont_name=>map.destination_ont_name,:source_ont=>map.source_ont,:source_name=>map.source_name,:destination_ont=>map.destination_ont,:destination_name=>map.destination_name,:destination_id=>map.destination_id,:users=>[map.user.username],:count=>1}
	        end
	      end
	    end
	    
	    @mappings = @mappings.sort {|a,b| b[1].length<=>a[1].length}
	
	    # This converts the mappings into an object that can be used with the pagination plugin
	    @page_results = WillPaginate::Collection.create(@mapping_pages.page_number, @mapping_pages.page_size, @mapping_pages.total_mappings) do |pager|
	       pager.replace(@mapping_pages)
	    end
    else
	    @mapping_pages = DataAccess.getBetweenOntologiesMappings(@ontology.ontologyId, @target_ontology.ontologyId, 1, 10000, :user_id => params[:user], :sources => params[:map_source], :unidirectional => "true")
    end
    
    if params[:rdf].nil? || !params[:rdf].eql?("rdf")
      render :partial=>'show'
    else
      send_data to_RDF(@mapping_pages), :type => 'text/html', :disposition => 'attachment; filename=mappings.rdf'
    end
  end
  
  def upload
    @ontologies = @ontologies = DataAccess.getOntologyList()
    @users = User.find(:all)
  end
  
  
  def process_mappings
    
    
    
      MappingLoader.processMappings(params)
    
     flash[:notice] = 'Mappings are processed'
     @ontologies = @ontologies = DataAccess.getOntologyList()
     @users = User.find(:all)
     render :action=>:upload
  end
  
  def new
    ontology = DataAccess.getOntology(params[:ontology])
    @mapping = Mapping.new
    @mapping.source_id = params[:source_id]
    @mapping.source_ont = ontology.ontologyId
    @mapping.source_version_id=ontology.id
    @ontologies = DataAccess.getActiveOntologies() #populates dropdown
    @name = params[:source_name] #used for display
    
    render :layout=>false
  end

  # POST /mappings
  # POST /mappings.xml
  def create
    source = DataAccess.getNode(params[:mapping]['source_version_id'], params[:mapping]['source_id'])
    target = DataAccess.getNode(params[:mapping]['destination_version_id'], params[:mapping]['destination_id'])
    comment = params[:mapping]['comment']
    unidirectional = params[:mapping]['directionality'].eql?("unidirectional")
    
    @mapping = DataAccess.createMapping(source.fullId, source.ontology.ontologyId, target.fullId, target.ontology.ontologyId, session[:user].id, comment, unidirectional)
    
    #repopulates table
    @ontology = DataAccess.getOntology(source.ontology.id)
    @mappings = DataAccess.getConceptMappings(source.ontology.ontologyId, source.fullId)    

    
    # Adds mapping to syndication
    @mapping.each do |mapping|
      event = EventItem.new
      event.event_type= "Mapping"
      event.event_type_id = mapping.id
      event.ontology_id = mapping.source_ont
      event.save
    end
    
    render :partial => 'mapping_table'
  end

private

  def to_RDF(mappings)
    rdf_text = "<?xml version='1.0' encoding='UTF-8'?>
    
	<rdf:RDF
		xmlns=\"http://bioontology.org/mappings/mappings.rdf#\"
      	xmlns:xsd=\"http://www.w3.org/2001/XMLSchema#\"
		xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"
		xmlns:rdfs=\"http://www.w3.org/2000/01/rdf-schema#\"
		xmlns:mappings=\"http://protege.stanford.edu/ontologies/mappings/mappings.rdfs#\">

         <rdfs:Class rdf:about=\"mappings:One_To_One_Mapping\">
             <rdfs:label rdf:datatype=\"xsd:string\"
                 >One_To_One_Mapping</rdfs:label>
         </rdfs:Class>
         
         <rdf:Property rdf:about=\"mappings:id\">
             <rdfs:domain rdf:resource=\"mappings:One_To_One_Mapping\"/>
             <rdfs:range rdf:resource=\"xsd:anyURI\"/>
             <rdfs:label rdf:datatype=\"xsd:string\">id</rdfs:label>
         </rdf:Property>
         
         <rdf:Property rdf:about=\"mappings:source\">
             <rdfs:domain rdf:resource=\"mappings:One_To_One_Mapping\"/>
             <rdfs:range rdf:resource=\"xsd:anyURI\"/>
             <rdfs:label rdf:datatype=\"xsd:string\">source</rdfs:label>
         </rdf:Property>
         
         <rdf:Property rdf:about=\"mappings:target\">
             <rdfs:domain rdf:resource=\"mappings:One_To_One_Mapping\"/>
             <rdfs:range rdf:resource=\"xsd:anyURI\"/>
             <rdfs:label rdf:datatype=\"xsd:string\">target</rdfs:label>
         </rdf:Property>

         <rdf:Property rdf:about=\"mappings:relation\">
             <rdfs:domain rdf:resource=\"mappings:One_To_One_Mapping\"/>
             <rdfs:range rdf:resource=\"xsd:anyURI\"/>
              <rdfs:label rdf:datatype=\"xsd:string\">relation</rdfs:label>
         </rdf:Property>
         
         <rdf:Property rdf:about=\"mappings:source_ontology_id\">
             <rdfs:domain rdf:resource=\"mappings:One_To_One_Mapping\"/>
             <rdfs:range rdf:resource=\"xsd:int\"/>
              <rdfs:label rdf:datatype=\"xsd:string\">source ontology id</rdfs:label>
         </rdf:Property>
         
         <rdf:Property rdf:about=\"mappings:target_ontology_id\">
             <rdfs:domain rdf:resource=\"mappings:One_To_One_Mapping\"/>
             <rdfs:range rdf:resource=\"xsd:int\"/>
              <rdfs:label rdf:datatype=\"xsd:string\">target ontology id</rdfs:label>
         </rdf:Property>
         
         <rdf:Property rdf:about=\"mappings:created_in_source_ontology_version\">
             <rdfs:domain rdf:resource=\"mappings:One_To_One_Mapping\"/>
             <rdfs:range rdf:resource=\"xsd:int\"/>
              <rdfs:label rdf:datatype=\"xsd:string\">created in source ontology version</rdfs:label>
         </rdf:Property>
         
         <rdf:Property rdf:about=\"mappings:created_in_target_ontology_version\">
             <rdfs:domain rdf:resource=\"mappings:One_To_One_Mapping\"/>
             <rdfs:range rdf:resource=\"xsd:int\"/>
              <rdfs:label rdf:datatype=\"xsd:string\">created in target ontology version</rdfs:label>
         </rdf:Property>
         
         <rdf:Property rdf:about=\"mappings:date\">
             <rdfs:domain rdf:resource=\"mappings:One_To_One_Mapping\"/>
             <rdfs:range rdf:resource=\"xsd:datetime\"/>
             <rdfs:label rdf:datatype=\"xsd:string\">date</rdfs:label>
         </rdf:Property>
         
         <rdf:Property rdf:about=\"mappings:submitted_by\">
             <rdfs:domain rdf:resource=\"mappings:One_To_One_Mapping\"/>
             <rdfs:range rdf:resource=\"xsd:int\"/>
             <rdfs:label rdf:datatype=\"xsd:string\">submitted by</rdfs:label>
         </rdf:Property>
         
         <rdf:Property rdf:about=\"mappings:mapping_type\">
             <rdfs:domain rdf:resource=\"mappings:One_To_One_Mapping\"/>
             <rdfs:range rdf:resource=\"xsd:string\"/>
             <rdfs:label rdf:datatype=\"xsd:string\">mapping type</rdfs:label>
         </rdf:Property>
         
         <rdf:Property rdf:about=\"mappings:dependency\">
             <rdfs:domain rdf:resource=\"mappings:One_To_One_Mapping\"/>
             <rdfs:range rdf:resource=\"xsd:anyURI\"/>
             <rdfs:label rdf:datatype=\"xsd:string\">dependency</rdfs:label>
         </rdf:Property>
         
         <rdf:Property rdf:about=\"mappings:comment\">
             <rdfs:domain rdf:resource=\"mappings:One_To_One_Mapping\"/>
             <rdfs:range rdf:resource=\"xsd:string\"/>
              <rdfs:label rdf:datatype=\"xsd:string\">comment</rdfs:label>
         </rdf:Property>
         
         <rdf:Property rdf:about=\"mappings:mapping_source\">
             <rdfs:domain rdf:resource=\"mappings:One_To_One_Mapping\"/>
             <rdfs:range rdf:resource=\"xsd:string\"/>
             <rdfs:label rdf:datatype=\"xsd:string\">mapping source</rdfs:label>
         </rdf:Property>
         
         <rdf:Property rdf:about=\"mappings:mapping_source_name\">
             <rdfs:domain rdf:resource=\"mappings:One_To_One_Mapping\"/>
             <rdfs:range rdf:resource=\"xsd:string\"/>
             <rdfs:label rdf:datatype=\"xsd:string\">mapping_source_name</rdfs:label>
         </rdf:Property>
         
         <rdf:Property rdf:about=\"mappings:mapping_source_contact_info\">
             <rdfs:domain rdf:resource=\"mappings:One_To_One_Mapping\"/>
             <rdfs:range rdf:resource=\"xsd:string\"/>
             <rdfs:label rdf:datatype=\"xsd:string\">mapping source contact info</rdfs:label>
         </rdf:Property>
         
         <rdf:Property rdf:about=\"mappings:mapping_source_site\">
             <rdfs:domain rdf:resource=\"mappings:One_To_One_Mapping\"/>
             <rdfs:range rdf:resource=\"xsd:anyURI\"/>
             <rdfs:label rdf:datatype=\"xsd:string\">mapping source site</rdfs:label>
         </rdf:Property>
         
         <rdf:Property rdf:about=\"mappings:mapping_source_algorithm\">
             <rdfs:domain rdf:resource=\"mappings:One_To_One_Mapping\"/>
             <rdfs:range rdf:resource=\"xsd:anyURI\"/>
             <rdfs:label rdf:datatype=\"xsd:string\">mapping source algorithm</rdfs:label>
         </rdf:Property>
         
         "
         
         for mapping in mappings
          rdf_text << "<mappings:One_To_One_Mapping rdf:about=\"#{mapping.id}\">
             <mappings:source rdf:resource='#{mapping.source}'/>
             <mappings:target rdf:resource='#{mapping.target}'/>
             <mappings:relation rdf:resource='#{mapping.relation}' />
             <mappings:source_ontology_id rdf:datatype=\"xsd:int\">#{mapping.source_ontology}</mappings:source_ontology_id>
             <mappings:target_ontology_id rdf:datatype=\"xsd:int\">#{mapping.target_ontology}</mappings:target_ontology_id>
             <mappings:created_in_source_ontology_version rdf:datatype=\"xsd:int\">#{mapping.source_ontology_version}</mappings:created_in_source_ontology_version>
             <mappings:created_in_target_ontology_version rdf:datatype=\"xsd:int\">#{mapping.target_ontology_version}</mappings:created_in_target_ontology_version>
             <mappings:date rdf:datatype=\"xsd:datetime\">#{mapping.date}</mappings:date>
             <mappings:submitted_by rdf:datatype=\"xsd:int\">#{mapping.submitted_by}</mappings:submitted_by>
             <mappings:mapping_type rdf:datatype=\"xsd:string\">#{mapping.mapping_type}</mappings:mapping_type>
             <mappings:dependency rdf:resource='#{mapping.dependency}' />
             <mappings:comment rdf:datatype=\"xsd:string\">#{mapping.comment}</mappings:comment>
             <mappings:mapping_source rdf:datatype=\"xsd:string\">#{mapping.mapping_source}</mappings:mapping_source>
             <mappings:mapping_source_name rdf:datatype=\"xsd:string\">#{mapping.mapping_source_name}</mappings:mapping_source_name>
             <mappings:mapping_source_contact_info rdf:datatype=\"xsd:string\">#{mapping.mapping_source_contact_info}</mappings:mapping_source_contact_info>
             <mappings:mapping_source_site rdf:resource='#{mapping.mapping_source_site}' />
             <mappings:mapping_source_algorithm rdf:datatype=\"xsd:string\">#{mapping.mapping_source_algorithm}</mappings:mapping_source_algorithm>
          </mappings:One_To_One_Mapping>
          
          "
        end
         
         
     rdf_text << "</rdf:RDF>"
     return rdf_text
  end


end
