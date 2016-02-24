# TODO: Put these requires and the get_json method into a new annotator client
require 'json'
require 'open-uri'
require 'cgi'
require 'rest-client'
require 'ontologies_api_client'

class ResourceIndexController < ApplicationController
  include ActionView::Helpers::TextHelper

  layout 'ontology'

  # Resource Index annotation offsets rely on latin-1 character sets for the count to be right. So we set all responses as latin-1.
  before_action :set_encoding

  def index
    @resources = LinkedData::Client::ResourceIndex.resources
    @resources_hash = resources_to_hash(@resources)
    @ri_ontologies = LinkedData::Client::Models::Ontology.all(include: LinkedData::Client::Models::Ontology.include_params)
    @ont_ids = []
    @ont_acronyms = {}
    @ont_names = {}
    @ri_ontologies.each do |ont|
      acronym = ont.acronym.nil? && ont.name || ont.acronym
      @ont_acronyms[ont.id] = acronym
      @ont_names[ont.id] = ont.name
      @ont_ids.push ont.id
    end
  end

  def search_classes
    # check query
    if params[:q].nil?
      render :text => "No search class provided"
      return
    end
    params[:q] = params[:q].strip
    # Get the first 50 classes matching the query
    search_page = LinkedData::Client::Models::Class.search(params[:q], params)
    search_subset = search_page.collection[0...50]
    # Simplify search results and get ontology details
    classes_hash = simplify_classes( search_subset ) # application_controller
    # Get the simplified classes in the search order
    classes = search_subset.map {|cls| classes_hash[cls.id] }
    classes_json = classes.to_json
    if params[:response].eql?("json")
      classes_json = classes_json.gsub("\"","'")
      classes_json = "#{params[:callback]}({data:\"#{classes_json}\"})"
    end
    render :text => classes_json
  end

  def resources_table
    create()
  end

  def create
    if params[:classes].nil?
      render :text => "No search class(es) provided. Please use the search box above to find classes to search the index with."
      return
    end

    @bp_last_params = params
    @classes = lookup_classes(params)
    @counts = LinkedData::Client::ResourceIndex.counts(@classes, params)

    @resources ||= LinkedData::Client::ResourceIndex.resources # application_controller
    @resources_hash ||= resources_to_hash(@resources)  # required in partial 'resources_results'

    # Enable for retrieving the first 10 docs from all resources at once
    # @documents_by_resource = LinkedData::Client::ResourceIndex.documents_all_resources(@classes, page: 1, pagesize: 10)

    render :partial => "resources_results"
  end

  def results_paginate
    params[:page]  ||= 1
    params[:limit] ||= 10
    @classes = lookup_classes(params)
    @documents = LinkedData::Client::ResourceIndex.documents(params[:acronym], @classes, page: params[:page], pagesize: params[:limit])
    @resource_results = ResourceIndexResultPaginatable.new(@documents)
    @acronym = params[:acronym]

    @resources ||= LinkedData::Client::ResourceIndex.resources
    @resources_hash ||= resources_to_hash(@resources)  # required in partial 'resources_results'

    render :partial => "resource_results"
  end

  def element_annotations
    render :json => annotate_filter_to_classes(params["element_text"], params["classes"])
  end

  private

  ##
  # Annotate with a given ontology and filter results to given class
  def annotate_filter_to_classes(text_sections, classes)
    threads = []
    class_ids = classes.values
    text_sections.keys.each do |section|
      text = text_sections[section]
      next if text.nil? || text.empty?
      threads << Thread.new do
        query = "#{$REST_URL}/annotator"
        query += "?text=" + CGI.escape(text)
        query += "&ontologies=" + CGI.escape(classes.keys.join(","))
        query += "&mappings=false" # not supported in RI yet
        all_annotations = parse_json(query) # See application_controller.rb
        text_sections[section] = all_annotations.lazy.select {|a| class_ids.include?(a["annotatedClass"]["@id"])}.map {|a| a["annotations"]}.force.flatten
      end
    end
    threads.each(&:join)
    text_sections
  end

  def resources_to_hash(resourcesList)
    resources_hash = {}
    resourcesList.each do |r|
      # convert struct to hash (to_json will create a javascript object).
      resources_hash[r[:acronym]] = struct_to_hash(r)
    end
    return resources_hash
  end

  def convert_for_will_paginate(resources)
    resources_paginate = []
    resources.each do |r|
      resources_paginate.push ResourceIndexResultPaginatable.new(r)
    end
    resources_paginate
  end

  def lookup_classes(params)
    classes = []
    if params[:classes].kind_of?(Hash)
      classesHash = params[:classes]
      classesHash.each do |ont_uri, cls_uris|
        cls_uris = cls_uris.is_a?(Array) ? cls_uris : cls_uris.split(",")
        ont = LinkedData::Client::Models::Ontology.find(ont_uri)
        cls_uris.each {|cls_id| classes << ont.explore.single_class(cls_id)}
      end
    end
    return classes
  end

  def set_encoding
    response.headers['Content-type'] = 'text/html; charset=ISO-8859-1'
  end

end
