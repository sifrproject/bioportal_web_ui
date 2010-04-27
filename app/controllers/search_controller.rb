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
  
  def fetch_results
    if params[:search].nil?
      redirect_to :ontologies
      return
    end
    @query = params[:search][:keyword]
    @ontologies = params[:search][:ontologies]
    if @ontologies.eql?("0") || @ontologies.first.eql?("0")
      @ontologies = ""
    end
    render :action=>'results'
  end
  
  def search # full search
    
    ontologies = params[:search][:ontologies]
    if ontologies.nil? || ontologies.empty?
      render :text=>"<h1 style='color:red'>Please select an ontology</h1>"
      return
    end
    
    if params[:search][:keyword].empty?
        render :text=>"<h1 style='color:red'>Please Enter a Search Term</h1>"
        return
      end
      
      
    
    @keyword = params[:search][:keyword]

    if params[:search][:attributes].nil? || params[:search][:attributes].eql?("0") || params[:search][:attributes].eql?("")
      if params[:search][:search_type].eql?("contains")
        @results,@pages = DataAccess.getNodeNameContains(params[:search][:ontologies],params[:search][:keyword],params[:page]||1)

      elsif params[:search][:search_type].eql?("exact")
        @results,@pages = DataAccess.getNodeNameExact(params[:search][:ontologies],params[:search][:keyword],params[:page]||1)


      end 
    end
  
    if params[:search][:attributes].eql?("1")
      if params[:search][:search_type].eql?("contains")
        @results,@pages =  DataAccess.getAttributeValueContains(params[:search][:ontologies],params[:search][:keyword],params[:page]||1)

        
      elsif params[:search][:search_type].eql?("exact")
        @results,@pages = DataAccess.getAttributeValueExact(params[:search][:ontologies],params[:search][:keyword],params[:page]||1)

        
      end 
      
      
  
    end

#    session[:search]={}
#    session[:search][:results]=@results
#    session[:search][:ontologies]=@ontologies
#    session[:search][:keyword]=@keyword
    
    if params[:page].nil?
      params[:page]=1
    end
    
    if request.xhr?
      render :partial =>'results'
    else
      @ontologies = DataAccess.getActiveOntologies() 
      render :action=>'results'
    end
    
    
  end
  
  def json_search
    if params[:q].nil?
      render :text => "No search term provided"
      return
    end
    
    @results,@pages = DataAccess.getNodeNameContains([params[:id]],params[:q],1)

    if params[:id]
      LOG.add :info, 'jump_to_search', request, :virtual_id => params[:id], :search_term => params[:q], :result_count => @results.length
    else
      LOG.add :info, 'jump_to_search', request, :search_term => params[:q], :result_count => @results.length
    end
    
    response = ""
    for result in @results
      record_type = result[:recordType].titleize.gsub("Record Type","").split(" ")
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
        response << "#{target_value}|#{result[:conceptIdShort]}|#{result[:recordType].titleize.gsub("Record Type","").downcase.strip}|#{result[:ontologyVersionId]}|#{result[:conceptId]}|#{result[:preferredName]}|#{result[:contents]}~!~"
      else
        response << "#{target_value}|#{result[:conceptIdShort]}|#{result[:recordType].titleize.gsub("Record Type","").downcase.strip}|#{result[:ontologyVersionId]}|#{result[:conceptId]}|#{result[:preferredName]}|#{result[:contents]}|#{result[:ontologyDisplayLabel]}~!~"
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
  #  begin
    if !request.env['HTTP_REFERER'].nil? && !request.env["HTTP_REFERER"].downcase.include?("bioontology.org")
      widget_log = WidgetLog.find_or_initialize_by_referer_and_widget(request.env["HTTP_REFERER"],@widget)
      if widget_log.id.nil?
        widget_log.count=1
      else
        widget_log.count+=1
      end
      widget_log.save
    end
#    rescue Exception=>e
      
#    end
    
    
    render :text=>response
    
  end
  
end
