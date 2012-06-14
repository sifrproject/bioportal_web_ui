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
    params[:objecttypes] = params[:include_props] ? "class,property" : "class"
    params[:page_size] = 250
    params[:includedefinitions] = "false"
    params[:query] = params[:query].strip
    params[:ontology_ids] ||= []
    params[:ontology_ids] = [params[:ontology_ids]] if params[:ontology_ids].kind_of?(String)

    # Add ontologies in the selected categories to the filter
    category_onts = DataAccess.getCategoriesWithOntologies
    unless params[:categories].nil? || params[:categories].length == 0
      debugger
      params[:categories].each do |category|
        params[:ontology_ids].concat category_onts[category][:ontologies]
      end
    end

    # Are we filtering at all by ontology?
    filter_ontologies = params[:ontology_ids].nil? || params[:ontology_ids].eql?("") ? nil : params[:ontology_ids]

    # Temporary hack to figure out which results are exact matches
    start_time = Time.now
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

    separator = (params[:separator].nil?) ? "~!~" : params[:separator]

    @results,@pages = DataAccess.getNodeNameContains([params[:id]],params[:q], 1, params)

    if params[:id]
      LOG.add :info, 'jump_to_search', request, :virtual_id => params[:id], :search_term => params[:q], :result_count => @results.length
    else
      LOG.add :info, 'jump_to_search', request, :search_term => params[:q], :result_count => @results.length
    end

    response = ""
    for result in @results
      if filter_result?(result)
        @results.delete(result)
        next
      end

      record_type = format_record_type(result[:recordType])
      record_type_value = ""
      for type in record_type
        record_type_value << type[0]
      end

      target_value = result[:preferredName]
      case params[:target]
      when "name" : target_value = result[:preferredName]
      when "shortid" : target_value = result[:conceptIdShort]
      when "uri" : target_value = result[:conceptId]
      else
        target_value = result[:preferredName]
      end

      if params[:id] && params[:id].split(",").length == 1
        response << "#{target_value}|#{result[:conceptIdShort]}|#{record_type}|#{result[:ontologyVersionId]}|#{result[:conceptId]}|#{result[:preferredName]}|#{result[:contents]}|#{CGI.escape(result[:definition])}#{separator}"
      else
        response << "#{target_value}|#{result[:conceptIdShort]}|#{record_type}|#{result[:ontologyVersionId]}|#{result[:conceptId]}|#{result[:preferredName]}|#{result[:contents]}|#{result[:ontologyDisplayLabel]}|#{result[:ontologyId]}|#{CGI.escape(result[:definition])}#{separator}"
      end
    end

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
    results.each do |result|
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
      # Rescuing 'true' here has the same effect of not showing the result, which is appropriate if we get an error getting ontology metadata
      private = DataAccess.getOntology(result["ontologyId"]).private? rescue true
      if !private
        false
      else
        !(session[:user] && session[:user].acl.include?(result["ontologyId"].to_i))
      end
    }

    results
  end

  # Check if this result should be filtered based on whether or not the result ontology is private
  def filter_result?(result)
    return false if session[:user] && session[:user].admin?

    ontology_id = result["ontologyId"].to_i if result["ontologyId"]
    ontology_id ||= result[:ontologyId]

    # Rescuing 'true' here has the same effect of not showing the result, which is appropriate if we get an error getting ontology metadata
    private = DataAccess.getOntology(ontology_id).private? rescue true

    if !private
      return false
    else
      return !(session[:user] && session[:user].acl.include?(ontology_id.to_i))
    end
  end

  def format_record_type(record_type)
    case record_type
      when "apreferredname"
        return "Preferred Name"
      when "bconceptid"
        return "Term ID"
      when "csynonym"
        return "Synonym"
      when "dproperty"
        return "Property"
      else
        return ""
    end
  end

end
