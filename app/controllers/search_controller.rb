require 'uri'

class SearchController < ApplicationController

  skip_before_filter :verify_authenticity_token

  layout 'ontology'

  def index
    @search_query = params[:query].nil? ? params[:q] : params[:query]
    @search_query = "" if @search_query.nil?
  end

  def concept #search for concept for mappings
    @ontology = DataAccess.getOntology(params[:ontology])
    @concepts,@pages = DataAccess.getNodeNameContains([@ontology.ontologyId],params[:name],1)
    render :partial => 'concepts'
  end

  def concept_preview #get the priview of the concept for mapping
    @ontology = DataAccess.getOntology(params[:ontology])
    @concept = DataAccess.getNode(params[:ontology],params[:id])
    @children = @concept.children
    render :partial =>'concept_preview'
  end

  def json
    # Safety checks
    params[:objecttypes] = set_objecttypes(params)
    params[:page_size] = 250
    params[:includedefinitions] = "false"
    params[:query] = params[:query].strip
    # Ensure :ontology_ids is an array
    params[:ontology_ids] ||= []
    params[:ontology_ids] = [params[:ontology_ids]] if params[:ontology_ids].kind_of?(String)

    # Add ontologies in the selected categories to the filter
    unless params[:categories].nil? || params[:categories].length == 0
      category_onts = DataAccess.getCategoriesWithOntologies
      params[:categories].each do |category|
        params[:ontology_ids].concat category_onts[category][:ontologies]
      end
    end

    # Temporary hack to figure out which results are exact matches
    start_time = Time.now
    # Force the search to be exact by adding the parameter to the call (this doesn't update the params hash)
    exact_results = DataAccess.searchQuery(params[:ontology_ids], params[:query], params[:page], params.merge({:exact_match => true}))
    LOG.add :debug, "Get exact matches: #{Time.now - start_time}s"
    exact_results.results = filter_advanced_options(exact_results.results, params)
    filter_private_results(exact_results)
    exact_count = exact_results.results.length

    if params[:exact_match].eql?("true")
      results = exact_results
    else
      start_time = Time.now
      results = DataAccess.searchQuery(params[:ontology_ids], params[:query], params[:page], params)
      LOG.add :debug, "Get other matches: #{Time.now - start_time}s"
    end

    # Add a tracker for exact results so we know which ones are exact when they get output to browser
    results.results.each_with_index do |result, index|
      result[:exactMatch] = index <= exact_count ? true : false
    end

    # Filter out ontologies using user-provided parameters
    start_time = Time.now
    results.results = filter_advanced_options(results.results, params)
    LOG.add :debug, "Filter advanced options: #{Time.now - start_time}s"

    # Store the total results counts before aggregation
    results.disaggregated_current_page_results = results.current_page_results

    # TODO: It would be nice to include a delete command in the iteration above so we don't
    # iterate over the results twice, but it wasn't working and no time to troubleshoot
    start_time = Time.now
    filter_private_results(results)
    LOG.add :debug, "Filter private ontologies: #{Time.now - start_time}s"

    start_time = Time.now
    results.results = results.rank_results(exact_count)
    LOG.add :debug, "Rank search results: #{Time.now - start_time}s"

    results.current_page_results = results.results.length + results.obsolete_results.length

    render :text => results.hash_for_serialization.to_json
  end

  def json_search
    if params[:q].nil?
      render :text => "No search term provided"
      return
    end

    params[:objecttypes] = set_objecttypes(params)

    separator = (params[:separator].nil?) ? "~!~" : params[:separator]

    @results,@pages = DataAccess.getNodeNameContains([params[:id]], params[:q], 1, params)

    if params[:id]
      LOG.add :info, 'jump_to_search', request, :virtual_id => params[:id], :search_term => params[:q], :result_count => @results.length
    else
      LOG.add :info, 'jump_to_search', request, :search_term => params[:q], :result_count => @results.length
    end

    response = ""
    obsolete_response = ""
    for result in @results
      if filter_private_result?(result)
        next
      end

      record_type = format_record_type(result[:recordType], result[:obsolete])

      target_value = result[:preferredName]
      case params[:target]
        when "name"
          target_value = result[:preferredName]
        when "shortid"
          target_value = result[:conceptIdShort]
        when "uri"
          target_value = result[:conceptId]
        else
          target_value = result[:preferredName]
      end

      json = []
      json << "#{target_value}"
      json << "|#{result[:conceptIdShort]}"
      json << "|#{record_type}"
      json << "|#{result[:ontologyVersionId]}"
      json << "|#{result[:conceptId]}"
      json << "|#{result[:preferredName]}"
      json << "|#{result[:contents]}"
      if params[:id] && params[:id].split(",").length == 1
        json << "|#{CGI.escape(result[:definition])}#{separator}"
      else
        json << "|#{result[:ontologyDisplayLabel]}"
        json << "|#{result[:ontologyId]}"
        json << "|#{CGI.escape(result[:definition])}#{separator}"
      end

      # Obsolete results go at the end
      if result[:obsolete]
        obsolete_response << json.join
      else
        response << json.join
      end
    end

    # Obsolete results merge
    response << obsolete_response

    if params[:response].eql?("json")
      response = response.gsub("\"","'")
      response = "#{params[:callback]}({data:\"#{response}\"})"
    end

    #default widget
    @widget="jump"
    if !params[:target].nil?
      #this is the form widget
      @widget="form"
    end

    #dont save it if its a test
    if !request.env['HTTP_REFERER'].nil? && !request.env["HTTP_REFERER"].downcase.include?("bioontology.org")
      widget_log = WidgetLog.find_or_initialize_by_referer_and_widget(request.env["HTTP_REFERER"],@widget)
      if widget_log.id.nil?
        widget_log.count=1
      else
        widget_log.count+=1
      end
      widget_log.save
    end

    render :text => response
  end

  private

  # Filters out ontologies from the advanced options that were selected
  # @params [Array] a list of results to filter
  # @params [Hash] hash of parameters from user, can just provide from global params
  # @return [Array] filtered list of results
  def filter_advanced_options(results, params)
    # Remove results due to advanced search options
    advanced_options_results = []
    ontology_list_hash = DataAccess.getOntologyListHash
    results.each do |result|
      # Discard if ontology doesn't exist
      # WARNING!!! THIS SKIPS ALL ONTOLOGY VIEWS NO MATTER WHAT!!!
      # It's in here to fix a problem where ontologies aren't in the index
      # and I'm out today and can't do anything more complicated
      next unless ontology_list_hash.key?(result['ontologyId'].to_i)

      # The following statements filter results using defaults. They can be overridden with "advanced options"
      # Discard if ontology is not production
      if params[:include_non_production].eql?("false")
        ont = DataAccess.getOntology(result['ontologyId'])
        next unless ont.production? || (!params[:ontology_ids].nil? && params[:ontology_ids].include?(ont.ontologyId.to_s))
      end

      # Discard if the result is an obsolete term
      if params[:include_obsolete].eql?("false")
        next if result['obsolete']
      end

      # Discard if the ontology is a view
      if params[:include_views].eql?("false")
        next if DataAccess.getOntology(result['ontologyId']).view?
      end

      advanced_options_results << result
    end
    advanced_options_results
  end

  # Filter an array of results based on whether or not the result ontology is private
  def filter_private_results(results)
    return results if session[:user] && session[:user].admin?

    results.results.delete_if { |result|
      # Rescuing 'true' here has the same effect of not showing the result,
      # which is appropriate if we get an error getting ontology metadata
      private = DataAccess.getOntology(result["ontologyId"]).private? rescue true
      if !private
        false
      else
        !(session[:user] && session[:user].acl && session[:user].acl.include?(result["ontologyId"].to_i))
      end
    }

    results
  end

  # Check if this result should be filtered based on
  # whether or not the result ontology is private
  def filter_private_result?(result)
    return false if session[:user] && session[:user].admin?

    ontology_id = result["ontologyId"].to_i if result["ontologyId"]
    ontology_id ||= result[:ontologyId]

    # Rescuing 'true' here has the same effect of not showing the result,
    # which is appropriate if we get an error getting ontology metadata
    private = DataAccess.getOntology(ontology_id).private? rescue true

    if !private
      return false
    else
      return !(session[:user] && session[:user].acl.include?(ontology_id.to_i))
    end
  end

  def format_record_type(record_type, obsolete = false)
    case record_type
      when "apreferredname"
        record_text = "Preferred Name"
      when "bconceptid"
        record_text = "Term ID"
      when "csynonym"
        record_text = "Synonym"
      when "dproperty"
        record_text = "Property"
      else
        record_text = ""
    end
    record_text = "Obsolete Term" if obsolete
    record_text
  end

  def set_objecttypes(params)
    if params[:objecttypes].nil? || params[:objecttypes].length == 0
      objecttypes = "class"  # default
    else
      objecttypes = params[:objecttypes]
    end
    return objecttypes
  end

end
