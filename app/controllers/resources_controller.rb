class ResourcesController < ApplicationController

  def show
    params[:id] = params[:conceptid].nil? ? params[:id] : params[:conceptid]

    @concept =  DataAccess.getNode(params[:ontology],params[:id])
    @ontology = DataAccess.getOntology(params[:ontology])
    latest = @ontology.is_latest? ? true : false
  
    @resources = []
    @resources = OBDWrapper.gatherResources(@ontology.ontologyId,@concept,latest,@ontology.id)

    render :partial => 'resources'
  end


  def details
    # Rails passes params as strings not booleans, so we convert latest to a true boolean here.
    latest = convert_boolean_param(params[:latest])
    
    params[:id] = params[:conceptid].nil? ? params[:id] : params[:conceptid]
    
    @details = OBDWrapper.gatherResourcesDetails(params[:ontology],latest,params[:version_id],params[:id],params[:resource],params[:element])

    unless @details["obs.common.beans.mgrepContext"].nil?
      @details["obs.common.beans.mgrepContext"].each do |key, mgrep_hash|
        # The following method for inserting opening and closing tags to highlight
        # annotation items will only work if the offsets are provided in ascending
        # order. To get this to work with multiple classes we'll want to change the
        # array that holds the offsets into a hash, using the offsets as a key
        # and the class as the value.
        total_added_chars = 0
        open_b = "<b>"
        close_b = "</b>"
        mgrep_hash[:offsets].each_with_index do |offset, index|
          # On even, insert the open tag. On odd, insert the close tag.
          if index % 2 < 1
            mgrep_hash[:contextString].insert(offset + total_added_chars, open_b)
            total_added_chars += open_b.length
          else
            mgrep_hash[:contextString].insert(offset + total_added_chars, close_b)
            total_added_chars += close_b.length
          end
        end
      end
    end

    render :partial=>'details'
  end

  
  def page
    #@concept =  DataAccess.getNode(params[:versioned_id],params[:concept])
    #@ontology = DataAccess.getOntology(params[:versioned_id])
    
    # rails passes params as strings not booleans, so we convert latest to a true boolean here
    latest = convert_boolean_param(params[:latest])
    
    @resource = Resource.new
    @resource.shortname=params[:resource]

    # Checking for UMLS_CUI is not implemented properly here
    # Eventually, we will be making a call for RRF ontologies that will take the place of the
    # check below.
    #if(@concept.properties["UMLS_CUI"]!=nil)
    #  @resource = OBDWrapper.gatherResourcesCui(@concept)
    #else
      @resource = OBDWrapper.pageResources(params[:ontology],latest,params[:version_id],params[:concept],params[:resource],params[:resource_main_context],params[:start],params[:end])
    #end
    
    render :partial=> 'paged'
  end  

private

  ##
  # Converts param string to a true boolean value.
  ##
  def convert_boolean_param(latest_param)
    latest = latest_param.eql?("true") ? true : false
  end


end
