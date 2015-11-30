require 'cgi'
class MappingsController < ApplicationController
  include ActionView::Helpers::NumberHelper

  layout 'ontology'
  before_action :authorize_and_redirect, :only=>[:create,:new,:destroy]

  MAPPINGS_URL = "#{LinkedData::Client.settings.rest_url}/mappings"
  EXTERNAL_MAPPINGS_GRAPH = "http://data.bioontology.org/metadata/ExternalMappings"
  INTERPORTAL_MAPPINGS_GRAPH = "http://data.bioontology.org/metadata/InterportalMappings"
  EXTERNAL_URL_PARAM_STR = "mappings:external"
  INTERPORTAL_URL_PARAM_STR = "interportal:"

  INTERPORTAL_HASH = $INTERPORTAL_HASH ||= {}

  def index
    ontology_list = LinkedData::Client::Models::Ontology.all.select {|o| !o.summaryOnly}
    ontologies_mapping_count = LinkedData::Client::HTTP.get("#{MAPPINGS_URL}/statistics/ontologies")
    ontologies_hash = {}
    ontology_list.each do |ontology|
      ontologies_hash[ontology.acronym] = ontology
    end

    # TODO_REV: Views support for mappings
    # views_list.each do |view|
    #   ontologies_hash[view.ontologyId] = view
    # end

    @options = {}
    if ontologies_mapping_count
      ontologies_mapping_count.members.each do |ontology_acronym|
        # Adding external and interportal mappings to the dropdown list
        if ontology_acronym.to_s == EXTERNAL_MAPPINGS_GRAPH
          mapping_count = ontologies_mapping_count[ontology_acronym.to_s]
          select_text = "External Mappings (#{number_with_delimiter(mapping_count, delimiter: ',')})" if mapping_count > 0
          ontology_acronym = EXTERNAL_URL_PARAM_STR
        elsif ontology_acronym.to_s.start_with?(INTERPORTAL_MAPPINGS_GRAPH)
          mapping_count = ontologies_mapping_count[ontology_acronym.to_s]
          select_text = "Interportal Mappings - #{ontology_acronym.to_s.split("/")[-1].upcase} (#{number_with_delimiter(mapping_count, delimiter: ',')})" if mapping_count > 0
          ontology_acronym = INTERPORTAL_URL_PARAM_STR + ontology_acronym.to_s.split("/")[-1]
        else
          ontology = ontologies_hash[ontology_acronym.to_s]
          mapping_count = ontologies_mapping_count[ontology_acronym]
          next unless ontology && mapping_count > 0
          select_text = "#{ontology.name} - #{ontology.acronym} (#{number_with_delimiter(mapping_count, delimiter: ',')})"
        end
        @options[select_text] = ontology_acronym
      end
    end

    @options = @options.sort
  end

  def count
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:id]).first
    if @ontology
      @ontology_id = @ontology.acronym
      @ontology_label = @ontology.name
      counts = LinkedData::Client::HTTP.get("#{MAPPINGS_URL}/statistics/ontologies/#{params[:id]}")
    else
      @ontology = params[:id]
      @ontology_id = @ontology
      @ontology_label = params[:id].split(":")[-1]
      if @ontology_label == "external"
        counts = LinkedData::Client::HTTP.get("#{MAPPINGS_URL}/statistics/external")
      elsif params[:id].split(":")[0] == "interportal"
        counts = LinkedData::Client::HTTP.get("#{MAPPINGS_URL}/statistics/interportal/#{@ontology_label}")
      end
    end

    @ontologies_mapping_count = []
    counts.members.each do |acronym|
      count = counts[acronym]
      ontology = LinkedData::Client::Models::Ontology.find_by_acronym(acronym.to_s).first
      if ontology
        onto_info = {:id => ontology.id, :name => ontology.name, :viewOf => ontology.viewOf}
      else
        if acronym.to_s == EXTERNAL_MAPPINGS_GRAPH
          onto_info = {:id => acronym.to_s, :name => "External Mappings", :viewOf => nil}
          @ontologies_mapping_count << {'ontology' => onto_info, 'count' => count}
        elsif acronym.to_s.start_with?(INTERPORTAL_MAPPINGS_GRAPH)
          onto_info = {:id => acronym.to_s, :name => "#{acronym.to_s.split("/")[-1].upcase} Interportal", :viewOf => nil}
          @ontologies_mapping_count << {'ontology' => onto_info, 'count' => count}
        end
      end
      next unless ontology
      @ontologies_mapping_count << {'ontology' => onto_info, 'count' => count}
    end
    @ontologies_mapping_count.sort! {|a,b| a['ontology'][:name].downcase <=> b['ontology'][:name].downcase } unless @ontologies_mapping_count.nil? || @ontologies_mapping_count.length == 0

    render :partial => 'count'
  end

  def show
    page = params[:page] || 1
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:id]).first
    @target_ontology = LinkedData::Client::Models::Ontology.find(params[:target])

    # Cases if ontology or target are interportal or external
    if @ontology.nil?
      ontology_acronym = params[:id]
      if params[:id] == EXTERNAL_URL_PARAM_STR
        @ontology_name = "External Mappings"
      elsif params[:id].start_with?(INTERPORTAL_URL_PARAM_STR)
        @ontology_name = params[:id].sub(":", " - ")
      end
    else
      ontology_acronym = @ontology.acronym
      @ontology_name = @ontology.name
    end
    if @target_ontology.nil?
      if params[:target] == EXTERNAL_MAPPINGS_GRAPH
        target_acronym = EXTERNAL_URL_PARAM_STR
        @target_ontology_name = "External Mappings"
      elsif params[:target].start_with?(INTERPORTAL_MAPPINGS_GRAPH)
        target_acronym = "#{INTERPORTAL_URL_PARAM_STR}:#{params[:target].split("/")[-1]}"
        @target_ontology_name = "Interportal - #{params[:target].split("/")[-1].upcase}"
      end
    else
      target_acronym = @target_ontology.acronym
      @target_ontology_name = @target_ontology.name
    end

    ontologies = [ontology_acronym, target_acronym]

    @mapping_pages = LinkedData::Client::HTTP.get(MAPPINGS_URL, {page: page, ontologies: ontologies.join(",")})
    @mappings = @mapping_pages.collection
    @delete_mapping_permission = check_delete_mapping_permission(@mappings)

    if @mapping_pages.nil? || @mapping_pages.collection.empty?
      @mapping_pages = MappingPage.new
      @mapping_pages.page = 1
      @mapping_pages.pageCount = 1
    end

    total_results = @mapping_pages.pageCount * @mapping_pages.collection.length

    # This converts the mappings into an object that can be used with the pagination plugin
    @page_results = WillPaginate::Collection.create(@mapping_pages.page, @mapping_pages.collection.length, total_results) do |pager|
       pager.replace(@mapping_pages.collection)
    end

    render :partial => 'show'
  end

  def get_concept_table
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontologyid]).first
    @concept = @ontology.explore.single_class({full: true}, params[:conceptid])

    @mappings = @concept.explore.mappings

    @delete_mapping_permission = check_delete_mapping_permission(@mappings)

    render :partial => "mapping_table"
  end

  def new
    @ontology_from = LinkedData::Client::Models::Ontology.find(params[:ontology_from])
    @ontology_to = LinkedData::Client::Models::Ontology.find(params[:ontology_to])
    @concept_from = @ontology_from.explore.single_class({full: true}, params[:conceptid_from]) if @ontology_from
    @concept_to = @ontology_to.explore.single_class({full: true}, params[:conceptid_to]) if @ontology_to

    # Defaults just in case nothing gets provided
    @ontology_from ||= LinkedData::Client::Models::Ontology.new
    @ontology_to ||= LinkedData::Client::Models::Ontology.new
    @concept_from ||= LinkedData::Client::Models::Class.new
    @concept_to ||= LinkedData::Client::Models::Class.new

    if request.xhr? || params[:no_layout].eql?("true")
      render :layout => false
    else
      render :layout => "ontology"
    end
  end

  def new_external
    @ontology_from = LinkedData::Client::Models::Ontology.find(params[:ontology_from])
    @ontology_to = LinkedData::Client::Models::Ontology.find(params[:ontology_to])
    @concept_from = @ontology_from.explore.single_class({full: true}, params[:conceptid_from]) if @ontology_from
    @concept_to = @ontology_to.explore.single_class({full: true}, params[:conceptid_to]) if @ontology_to

    @interportal_options = []
    INTERPORTAL_HASH.each do |key, value|
      @interportal_options.push([key, key])
    end

    # Defaults just in case nothing gets provided
    @ontology_from ||= LinkedData::Client::Models::Ontology.new
    @ontology_to ||= LinkedData::Client::Models::Ontology.new
    @concept_from ||= LinkedData::Client::Models::Class.new
    @concept_to ||= LinkedData::Client::Models::Class.new

    if request.xhr? || params[:no_layout].eql?("true")
      render :layout => false
    else
      render :layout => "ontology"
    end
  end

  # POST /mappings
  # POST /mappings.xml
  def create
    if params.has_key?(:mapping_type)
      # Means its an external or interportal mapping
      target_ontology = params[:map_to_bioportal_ontology_id]
      target = params[:map_to_bioportal_full_id]
    else
      # Means it's a regular internal mapping
      target_ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:map_to_bioportal_ontology_id]).first
      target = target_ontology.explore.single_class(params[:map_to_bioportal_full_id]).id
      target_ontology = target_ontology.id
    end
    source_ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:map_from_bioportal_ontology_id]).first
    source = source_ontology.explore.single_class(params[:map_from_bioportal_full_id])
    values = {
      classes: {
        source.id => source_ontology.id,
        target => target_ontology
      },
      creator: session[:user].id,
      relation: params[:mapping_relation],
      comment: params[:mapping_comment]
    }
    @mapping = LinkedData::Client::Models::Mapping.new(values: values)
    @mapping_saved = @mapping.save
    if @mapping_saved.errors
      render text: @mapping_saved.errors[0], status: :bad_request
    else
      @delete_mapping_permission = check_delete_mapping_permission(@mapping_saved)
      render :json => @mapping_saved
    end
  end

  def destroy
    errors = []
    successes = []
    mapping_ids = params[:mappingids].split(",")
    mapping_ids.each do |map_id|
      begin
        map_uri = "#{MAPPINGS_URL}/#{CGI.escape(map_id)}"
        result = LinkedData::Client::HTTP.delete(map_uri)
        raise Exception if !result.nil? #&& result["errorCode"]
        successes << map_id
      rescue Exception => e
        errors << map_id
      end
    end
    render :json => { :success => successes, :error => errors }
  end

end
