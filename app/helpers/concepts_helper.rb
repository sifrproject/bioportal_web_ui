module ConceptsHelper

  def exclude_relation?(relation_to_check, ontology = nil)
    excluded_relations = [ "type", "rdf:type", "[R]", "SuperClass", "InstanceCount" ]

    # Show or hide property based on the property and ontology settings
    if ontology
      # Hide owl:deprecated if a user has set class or property based obsolete checking
      if !ontology.obsoleteParent.nil? && relation_to_check.include?("owl:deprecated") || !ontology.obsoleteProperty.nil? && relation_to_check.include?("owl:deprecated")
        return true
      end
    end

    excluded_relations.each do |relation|
      return true if relation_to_check.include?(relation)
    end
    return false
  end

end
