module ResourcesHelper
  
  def generate_details_link(ontology_id, resource, element, concept)
    ontology = DataAccess.getOntology(ontology_id)
    conceptid = ontology.is_latest? ? "#{ontology.ontologyId}/#{concept}&virtual=true" : "#{ontology.id}/#{concept}"
    return "#{$RESOURCE_INDEX_UI_URL}/get_resource_element_context.php?url=#{CGI.escape("http://#{$REST_DOMAIN}/")}&resourceId=#{resource}&elementId=#{element}&conceptIds=#{conceptid}"
  end
  
end
