require 'cgi'
class MappingsController < ApplicationController

  layout 'ontology'
  before_filter :authorize, :only=>[:create,:new,:destroy]

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
      next if ontology["totalMappings"].nil?
      @options[ontologies_hash[ontology['ontologyId']].displayLabel + " (#{ontology['totalMappings']})"] = ontologies_hash[ontology['ontologyId']].id unless ontologies_hash[ontology['ontologyId']].nil?
    end

    @options = @options.sort
  end

  def count
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

    @ontologies_mapping_count.each do |ontology|
      ontology['ontology'] = ontologies_hash[ontology['ontologyId']]
    end

    @ontologies_mapping_count.delete_if {|ont| ont['ontology'].nil?}

    @ontology_id = @ontology.ontologyId
    @ontology_label = @ontology.displayLabel

    @ontologies_mapping_count.sort! {|a,b| a['ontology'].displayLabel.downcase <=> b['ontology'].displayLabel.downcase } unless @ontologies_mapping_count.nil? || @ontologies_mapping_count.length == 0

    render :partial => 'count'
  end

  def show
    @ontology = DataAccess.getLatestOntology(params[:id])
    @target_ontology = DataAccess.getLatestOntology(params[:target])

    if params[:rdf].nil? || !params[:rdf].eql?("rdf")
      @mapping_pages = DataAccess.getBetweenOntologiesMappings(@ontology.ontologyId, @target_ontology.ontologyId, params[:page], 10, :user_id => params[:user], :sources => params[:map_source], :unidirectional => "true", :ranked => "true")
      @mappings = {}
      @map_sources = []
      @users = []
      user_count = DataAccess.getMappingCountOntologyUsers(@ontology.ontologyId, @target_ontology.ontologyId)

      user_count.each do |user|
        @users << DataAccess.getUser(user['userId'])
      end
      @users.sort! {|a,b| a.username.downcase <=> b.username.downcase}

      for map in @mapping_pages
        @map_sources << map.map_source.gsub(/(<[^>]*>)/mi, "") unless map.map_source.nil? || map.map_source.empty?
        @map_sources.uniq!

        if @mappings[map.source_id].nil?
          @mappings[map.source_id] = [{:source_ont_name=>map.source_ont_name,:destination_ont_name=>map.destination_ont_name,:source_ont=>map.source_ont,:source_name=>map.source_name,:destination_ont=>map.destination_ont,:destination_name=>map.destination_name,:destination_id=>map.destination_id,:users=>[map.user.username],:count=>1,:source_missing=>map.source_missing?,:target_missing=>map.target_missing?}]
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
           @mappings[map.source_id] << {:source_ont_name=>map.source_ont_name,:destination_ont_name=>map.destination_ont_name,:source_ont=>map.source_ont,:source_name=>map.source_name,:destination_ont=>map.destination_ont,:destination_name=>map.destination_name,:destination_id=>map.destination_id,:users=>[map.user.username],:count=>1,:source_missing=>map.source_missing?,:target_missing=>map.target_missing?}
          end
        end
      end

      @mappings = @mappings.sort {|a,b| b[1].length<=>a[1].length}

      if @mapping_pages.nil? || @mapping_pages.empty?
        @mapping_pages = MappingPage.new
        @mapping_pages.page_size = 1
        @mapping_pages.total_mappings = 0
        @mapping_pages.page_number = 1
      end

      # This converts the mappings into an object that can be used with the pagination plugin
      @page_results = WillPaginate::Collection.create(@mapping_pages.page_number, @mapping_pages.page_size, @mapping_pages.total_mappings) do |pager|
         pager.replace(@mapping_pages)
      end
    else
      @mapping_pages = DataAccess.getBetweenOntologiesMappings(@ontology.ontologyId, @target_ontology.ontologyId, 1, 10000, :user_id => params[:user], :sources => params[:map_source], :unidirectional => "true")
    end

    if params[:rdf].nil? || !params[:rdf].eql?("rdf")
      render :partial => 'show'
    else
      send_data to_RDF(@mapping_pages), :type => 'text/html', :disposition => 'attachment; filename=mappings.rdf'
    end
  end

  def get_concept_table
    @ontology = DataAccess.getOntology(params[:ontologyid])
    @concept = DataAccess.getNode(@ontology.id, params[:conceptid])

    @mappings = DataAccess.getConceptMappings(@ontology.ontologyId, @concept.fullId)

    # check to see if user should get the option to delete
    @delete_mapping_permission = check_delete_mapping_permission(@mappings)

    render :partial => "mapping_table"
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
    @ontology_from = DataAccess.getOntology(params[:ontology_from]) rescue OntologyWrapper.new
    @ontology_to = DataAccess.getOntology(params[:ontology_to]) rescue OntologyWrapper.new
    @concept_from = DataAccess.getNode(@ontology_from.id, params[:conceptid_from]) rescue NodeWrapper.new
    @concept_to = DataAccess.getNode(@ontology_to.id, params[:conceptid_to]) rescue NodeWrapper.new

    if request.xhr? || params[:no_layout].eql?("true")
      render :layout => "minimal"
    else
      render :layout => "ontology"
    end
  end

  # POST /mappings
  # POST /mappings.xml
  def create
    source_ontology = DataAccess.getOntology(params[:map_from_bioportal_ontology_id])
    target_ontology = DataAccess.getOntology(params[:map_to_bioportal_ontology_id])
    source = DataAccess.getNode(source_ontology.id, params[:map_from_bioportal_full_id])
    target = DataAccess.getNode(target_ontology.id, params[:map_to_bioportal_full_id])
    comment = params[:mapping_comment]
    unidirectional = params[:mapping_directionality].eql?("unidirectional")

    @mapping = DataAccess.createMapping(source.fullId, source.ontology.ontologyId, target.fullId, target.ontology.ontologyId, session[:user].id, comment, unidirectional)

    # Adds mapping to syndication
    begin
      @mapping.each do |mapping|
        event = EventItem.new
        event.event_type= "Mapping"
        event.event_type_id = mapping.id
        event.ontology_id = mapping.source_ont
        event.save
      end
    rescue Exception => e
      LOG.add :debug, "Problem adding mapping to RSS feed"
    end

    render :json => @mapping
  end

  def destroy
    mapping_ids = params[:mappingids].split(",")
    concept_id = params[:conceptid].empty? ? "root" : params[:conceptid]

    ontology = DataAccess.getOntology(params[:ontologyid])
    concept = DataAccess.getNode(ontology.id, concept_id)
    concept = concept_id.eql?("root") ? concept.children[0] : concept

    errors = []
    successes = []
    mapping_ids.each do |map_id|
      begin
        result = DataAccess.deleteMapping(map_id)
        raise Exception if !result.nil? && result["errorCode"]
      rescue Exception => e
        errors << map_id
        next
      end
      successes << map_id
    end

    CACHE.delete("#{ontology.ontologyId}::#{CGI.escape(concept.fullId)}::map_page::page1::size100::params")
    CACHE.delete("#{ontology.ontologyId}::#{CGI.escape(concept.fullId)}::map_count")

    render :json => { :success => successes, :error => errors }
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
