require "rexml/document"
require 'open-uri'
require 'cgi'

class OntrezService
  
  # Tokens
  # %CONC% = Concept Id
  # %ELEMENT% = Element Id
  # %ONT% = Ontology Name
  # %RESOURCE% = Resource Name
  # %S_PAGE% = Page Start
  # %E_PAGE% = Page End
  
  ONTREZ_URL = $RESOURCE_INDEX_REST_URL
  
  RESOURCE_BY_CONCEPT = "/byconcept/virtual/%ONT%/false/true/0/10?conceptid=%CONC%"
  VERSIONED_RESOURCE_BY_CONCEPT = "/byconcept/%ONT%/false/true/0/10?conceptid=%CONC%"
  PAGING_RESOURCE_BY_CONCEPT = "/byconcept/virtual/%ONT%/%RESOURCE%/false/false/%S_PAGE%/10?conceptid=%CONC%"
  VERSIONED_PAGING_RESOURCE_BY_CONCEPT = "/byconcept/%ONT%/%RESOURCE%/false/false/%S_PAGE%/10?conceptid=%CONC%"
  RESOURCES = "/resources"
  DETAILS = "/details/true/virtual/concept/%ONT%/resource/%RESOURCE%/?conceptid=%CONC%&elementid=%ELEMENT%"
  VERSIONED_DETAILS = "/details/true/concept/%ONT%/resource/%RESOURCE%/?conceptid=%CONC%&elementid=%ELEMENT%"
  
  CLASS_STRING = "/result/ontology/%ONT%/classID/from/0/number/15/metadata?conceptid=%CONC%"
  CUI_STRING = "/result/cui/from/0/number/15/metadata?conceptid=%CONC%"
  NEXTBIO_URL = "http://www.nextbio.com/b/api/searchcount.api?q=%CONC%&details=true&apikey=2346462a645f102ba7f2001d096b4f04&type=study"
  PAGING_CLASS_STRING = "/result/ontology/%ONT%/classID/from/%S_PAGE%/number/%E_PAGE%/resource/%RESOURCE%/metadata?conceptid=%CONC%"
  PAGING_CUI_STRING = "/result/cui/from/%S_PAGE%/number/%E_PAGE%/resource/%RESOURCE%/metadata?conceptid=%CONC%"
  

  def self.gatherResources(ontology_id,concept_id,latest,version_id)
    resources = []
    
    # if this isn't the most recent version of the ontology, use the versioned URL instead of the virtual
    resource_url = latest ? RESOURCE_BY_CONCEPT : VERSIONED_RESOURCE_BY_CONCEPT
    ont = latest ? ontology_id : version_id
    
    # this call gets all of the resources and their associated information
    LOG.add :debug, "Retrieve resources"
    LOG.add :debug, ONTREZ_URL + RESOURCES
    startGet = Time.now
    doc = REXML::Document.new(open(ONTREZ_URL + RESOURCES))
    LOG.add :debug, "Resources retrieved (#{Time.now - startGet})"
    
    if CACHE.get("ri::resources").nil?
      doc.elements.each("/success/data/set/resource"){|resource|
        new_resource = Resource.new
        new_resource.name = resource.elements["resourceName"].get_text.value
        new_resource.shortname = resource.elements["resourceId"].get_text.value
        new_resource.url = resource.elements["resourceURL"].get_text.value
        new_resource.resource_element_url = resource.elements["resourceElementURL"].get_text.value rescue ""
        new_resource.description = resource.elements["resourceDescription"].get_text.value
        new_resource.logo = resource.elements["resourceLogo"].get_text.value
        new_resource.main_context = resource.elements["mainContext"].get_text.value
        resources << new_resource
      }
      LOG.add :debug, "Resources parsed (#{Time.now - startGet})"
      
      CACHE.set("ri::resources", resources, 60*60*336)
    else
      resources = CACHE.get("ri::resources")
    end

    LOG.add :debug, "Retrieve annotations for #{concept_id}"
    LOG.add :debug, ONTREZ_URL+resource_url.gsub("%ONT%",ont).gsub("%CONC%",CGI.escape(concept_id))
    startGet = Time.now
    # this call gets the annotation numbers and the first 10 annotations for each resource
    begin
      doc = REXML::Document.new(open(ONTREZ_URL + resource_url.gsub("%ONT%",ont).gsub("%CONC%",CGI.escape(concept_id))))
    rescue Exception => e
      LOG.add :debug, e.inspect
    end
    LOG.add :debug, "Annotations retrieved #{Time.now - startGet}"
    
    # parse out the annotation numbers and annotations
    startGet = Time.now
    for resource in resources
      # number of annotations
      xpath = "/success/data/list/result[resourceId='" + resource.shortname + "']/resultStatistics/statistics/annotationCount"
      resource.count = doc.elements[xpath].get_text.value.to_i

      # annotations
      xpath = "/success/data/list/result[resourceId='" + resource.shortname + "']/annotations"
      annotations_doc = doc.elements[xpath]
      parseAnnotations(annotations_doc,resource)
    end
    LOG.add :debug, "Annotations parsed (#{Time.now - startGet})"

    resources.sort! { |x,y| x.name.downcase <=> y.name.downcase }

    return resources
  end


  def self.gatherResourcesDetails(ontology_id,latest,version_id,concept_id,resource,element)
    resources = []

    # if this isn't the most recent version of the ontology, use the versioned URL instead of the virtual
    resource_url = latest ? DETAILS : VERSIONED_DETAILS
    ont = latest ? ontology_id : version_id

    rest_url = ONTREZ_URL + resource_url.gsub("%ONT%",ont.to_s.strip).gsub("%RESOURCE%",resource.strip).gsub("%CONC%",CGI.escape(concept_id)).gsub("%ELEMENT%",CGI.escape(element))
    
    LOG.add :debug, "Details retrieve for #{concept_id}"
    LOG.add :debug, rest_url
    
    begin
      doc = REXML::Document.new(open(rest_url))
    rescue Exception=>e
      LOG.add :debug,  "Exception retrieving/parsing detailed annotations xml"
      LOG.add :debug, e.inspect
    end

    time = Time.now
    resources = parseOBSDetails(doc,rest_url)
    LOG.add :debug, "Details parsing done (#{Time.now - time})"

    return resources
  end


  def self.pageResources(ontology_id,latest,version_id,concept_id,resource_name,resource_main_context,page_start,page_end)
    # if this isn't the most recent version of the ontology, use the versioned URL instead of the virtual
    resource_url = latest ? PAGING_RESOURCE_BY_CONCEPT : VERSIONED_PAGING_RESOURCE_BY_CONCEPT
    ont = latest ? ontology_id : version_id
    
    LOG.add :debug, "Page retrieve"
    LOG.add :debug, ONTREZ_URL + resource_url.gsub("%ONT%",ont.to_s.strip).gsub("%CONC%",CGI.escape(concept_id).strip).gsub("%S_PAGE%",page_start).gsub("%E_PAGE%",page_end).gsub("%RESOURCE%",resource_name.strip)
    doc = REXML::Document.new(open(ONTREZ_URL + resource_url.gsub("%ONT%",ont.to_s.strip).gsub("%CONC%",CGI.escape(concept_id).strip).gsub("%S_PAGE%",page_start).gsub("%E_PAGE%",page_end).gsub("%RESOURCE%",resource_name.strip)))

    # new resource object with info from params
    new_resource = Resource.new
    new_resource.shortname = resource_name
    new_resource.main_context = resource_main_context

    # use xpath to isolate annotations and send those as a parameter
    xpath = "/success/data/result/annotations"
    annotations_doc = doc.elements[xpath]
    parseAnnotations(annotations_doc,new_resource)
    
    return new_resource
  end

  def self.pageResourcesByCui(cui,resource_name,page_start,page_end)
  
  end

  def self.parseNextBio(text)
    doc = REXML::Document.new(open(NEXTBIO_URL.gsub("%CONC%",text.gsub(" ","%20").gsub("_","%20"))))
    resource = Resource.new   
    resource.context_numbers = {}
    resource.annotations = []
    resource.name ="NextBio"
    resource.url="http://www.nextbio.com/b/home/generalSearch.nb?q=#{text}#sitype=STUDY"
    resource.description ="NextBio's data
    and literature search engine makes massive amounts of disparate
    biological, clinical and chemical data from public and proprietary
    sources searchable, regardless of data type and origin, empowering
    researchers to quickly understand their own experimental results
    within the context of other research."
    resource.logo ="http://www.nextbio.com/b/s/images2/common/nbLogoSmBeta.png"
    resource.count = doc.elements["NBResultSummary"].elements["count"].get_text.value.to_i
    # Placeholders for main_context because NextBio doesn't include this information
    resource.main_context = "Title"
    
      doc.elements.each("*/details"){ |detail| 
          detail.elements.each { |element| 
            resource.context_numbers[element.name]=element.get_text.value          
          }
        }
      doc.elements.each("*/results"){ |results|
          results.elements.each { |result|
            annotation = Annotation.new
            annotation.local_id = result.elements["name"].get_text.value unless result.elements["name"].nil?
            annotation.term_id = result.elements["name"].get_text.value unless result.elements["name"].nil?
            annotation.item_key = result.elements["name"].get_text.value unless result.elements["name"].nil?
            annotation.url = result.elements["url"].get_text.value unless result.elements["url"].nil?
           
              annotation.description =  result.elements["name"].get_text.value
                             
              #annotation.description = result.elements["title"].get_text.value
            
            
            resource.annotations << annotation            
            }
        
        }  
    return resource  
  end
  
private 

  ##
  # Parses annotation information from OBR REST XML.
  # Doc should be XML returned from the OBR REST service starting at the <annotation> level.
  ##
  def self.parseAnnotations(doc,resource)
    resource.context_numbers = {}
    resource.annotations = []
    
    # Sometimes the OBR service doesn't return an annotation tag when there are no annotations
    # To work around this, return is the annotation source xml is nil
    return if doc.nil?

    xpath = "annotationDetailed"

    doc.elements.each(xpath){ |annotationXML|
      begin
        annotation = Annotation.new
        annotation.score = annotationXML.elements["score"].get_text.value
        annotation.local_id = CGI.escape(annotationXML.elements["localElementId"].get_text.value).strip
        # We try to find the description with a non-reference xpath first.
        xpath = "element/elementStructure/contexts/entry[string='" + resource.main_context + "']/string[2]"
        # If that didn't work, revert to finding the description using provided relative xpath from the reference attr.
        if annotationXML.elements[xpath].nil?
          xpath_alt = "../annotationDetailed/element/elementStructure/contexts/entry[string='" + resource.main_context + "']/string[2]"
          annotation.description = annotationXML.elements[xpath_alt].get_text.value
        else
          annotation.description = annotationXML.elements[xpath].get_text.value
        end
        resource.annotations << annotation
      rescue Exception=>e
        LOG.add :debug, e.inspect
      end
    }
  end
 
  def self.parseOBS(doc,resource)
    # get annotation count
    resource.count = doc.elements["//statistics/statisticsBean/nbAnnotation"].get_text.value.to_i      
    
    # get annotations
    resource.context_numbers = {}
    resource.annotations = []

    doc.elements.each("*/annotations/obrAnnotationBeanDetailed"){ |statistic|
      annotation = Annotation.new
      annotation.score = statistic.elements["score"].get_text.value
      annotation.local_id= statistic.elements["localElementID"].get_text.value
      resource.annotations << annotation
    }

  end
 
  def self.parseOBSDetails(doc,rest_url)
    details = {}
    details[:rest_url] = rest_url

    doc.elements.each("*/obrAnnotationBeanDetailed"){ |annotation|
      context = annotation.elements["context"]
      annot_class = context.attributes["class"]
      context_name = context.elements["contextName"].get_text.value

      # Build detail representation
      details[annot_class] = Hash.new unless !details[annot_class].nil?
      details[annot_class][context_name] = Hash.new unless !details[annot_class][context_name].nil?
      details[annot_class][context_name][:contextName] = context_name
      details[annot_class][context_name][:contextNameDisplay] = context_name[context_name.index("_") + 1, context_name.length].gsub("_", " ").titleize
      details[annot_class][context_name][:isDirect] = context.elements["isDirect"].get_text.value
      
      # Get the annotation string for this context
      # Check if references are used
      resource_element = annotation.elements["element"]
      reference = resource_element.attributes["reference"] rescue nil
      if reference
        contexts = annotation.elements["../obrAnnotationBeanDetailed/element/elementStructure/contexts"]
      else
        contexts = annotation.elements["element/elementStructure/contexts"]
      end
      details[annot_class][context_name][:contextString] = contexts.elements["entry[string='" + context_name + "']/string[2]"].get_text.value

      case annot_class
      when "mgrepContext"
        # String that contains the annotation term
        details[annot_class][context_name][:termID] = context.elements["termID"].get_text.value
        details[annot_class][context_name][:termName] = context.elements["termName"].get_text.value
        # Store the from/to characters in an array
        details[annot_class][context_name][:offsets] = [] unless !details[annot_class][context_name][:offsets].nil?
        details[annot_class][context_name][:offsets] << context.elements["from"].get_text.value.to_i - 1 # we subtract one because the api gives the count at the actual start, not before
        details[annot_class][context_name][:offsets] << context.elements["to"].get_text.value.to_i
      when "isaContext"
        details[annot_class][context_name][:childConceptID]= context.elements["childConceptID"].get_text.value
        details[annot_class][context_name][:level]= context.elements["level"].get_text.value
      when "mappingContext"
        details[annot_class][context_name][:mappedConceptID] = context.elements["mappedConceptID"].get_text.value
        details[annot_class][context_name][:mappingType] = context.elements["mappingType"].get_text.value
      when "reportedContext"
      end
    }

    return details
  end
 
end