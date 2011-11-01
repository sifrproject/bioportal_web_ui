require 'OntrezService'

class OBDWrapper

  NO_CACHE = false

  def self.getResourcesInfo
    if CACHE.get("resource_index_info").nil?
      resource_info = OntrezService.getResourcesInfo
      CACHE.set("resource_index_info", resource_info, 60*60*24*14)
    else
      resource_info = CACHE.get("resource_index_info")
    end
    resource_info
  end

  def self.gatherResources(ontology,concept,latest,version_id)
    if CACHE.get("#{ontology}::#{concept.id}_resource").nil? || NO_CACHE
      resources = []

      cache = true

      begin
        resources = OntrezService.gatherResources(ontology,concept.id,latest,version_id)
      rescue Exception => e
        cache  =false
      end

      # makes it so no resources show if ontrez is broken
      if resources.empty?
        return resources
      end

      begin
        resources << OntrezService.parseNextBio(concept.name)
      rescue Exception => e
        cache = false
        Notifier.deliver_error(e)
      end

      if cache
        CACHE.set("#{ontology}::#{concept.id}_resource",resources)
      end
      resources.sort!{|x,y| x.name.downcase<=>y.name.downcase}

      return resources
    else
      return CACHE.get("#{ontology}::#{concept.id}_resource")
    end
  end

  def self.gatherResourcesDetails(ontology_id,latest,version_id,concept_id,resource,element)
    details = OntrezService.gatherResourcesDetails(ontology_id,latest,version_id,concept_id,resource,element)
    return details
  end

  def self.pageResources(ontology_id,latest,version_id,concept_id,resource_name,resource_main_context,page_start,page_end)
    resource = Resource.new

    begin
      resource = OntrezService.pageResources(ontology_id,latest,version_id,concept_id,resource_name,resource_main_context,page_start,page_end)
    rescue Exception => e
      Notifier.deliver_error(e)
      return resource
    end
  end

  def self.getResourceStats
    if CACHE.get("resource_index_stats").nil?
      stats = OntrezService.getResourceStats

      CACHE.set("resource_index_stats", stats, 60*60*336)
    else
      stats = CACHE.get("resource_index_stats")
    end
    stats
  end

end
