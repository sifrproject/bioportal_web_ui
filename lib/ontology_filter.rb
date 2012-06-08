# This is used to restrict ontologies based on user-defined preferences
# (AKA "My BioPortal")

class OntologyFilter

  USER_ONTOLOGY_FILTER_PRE = {
    :searchQuery => lambda { |args, user_ontologies| args[0][:ontologies] = user_ontologies[:virtual_ids].to_a if args[0][:ontologies].nil? || args[0][:ontologies].empty? || (args[0][:ontologies].length == 1 && args[0][:ontologies][0].empty?)},
    :getNodeNameContains => lambda { |args, user_ontologies| args[0] = user_ontologies[:virtual_ids].to_a if args[0].nil? || args[0].join("").empty? },
    :createRecommendation => lambda { |args, user_ontologies| args[0][:ontologyids] = user_ontologies[:virtual_ids].to_a.join(",") if args[0][:ontologyids].nil? || args[0][:ontologyids].empty? },
    :annotator => lambda { |args, user_ontologies| args[:ontologiesToKeepInResult] = user_ontologies[:virtual_ids].to_a if args[:ontologiesToKeepInResult].nil? || args[:ontologiesToKeepInResult].empty? }
  }

  USER_ONTOLOGY_FILTER_POST = {
    :getConceptMappings => lambda { |mappings, user_ontologies| mappings.reject! {|a| !user_ontologies[:virtual_ids].include?(a.target_ontology) } unless mappings.nil? || mappings.empty? },
    :getMappingCountOntologies => lambda { |mappings, user_ontologies| mappings.reject! {|a| !user_ontologies[:virtual_ids].include?(a["ontologyId"].to_i) } unless mappings.nil? || mappings.empty? },
    :getMappingCountBetweenOntologies => lambda { |mappings, user_ontologies| mappings.reject! {|a| !user_ontologies[:virtual_ids].include?(a["ontologyId"].to_i) } unless mappings.nil? || mappings.empty? },
    :getRecentMappings => lambda { |mappings, user_ontologies| mappings.reject! {|a| !user_ontologies[:virtual_ids].include?(a.target_ontology) } unless mappings.nil? || mappings.empty? },
    :getOntologyList => lambda { |ontologies, user_ontologies| ontologies.reject! {|a| !user_ontologies[:virtual_ids].include?(a.ontologyId.to_i) } }
  }

  def self.pre(method, args)
    return unless Thread.current[:session] && Thread.current[:session][:user_ontologies] && USER_ONTOLOGY_FILTER_PRE.key?(method.to_sym)
    USER_ONTOLOGY_FILTER_PRE[method.to_sym].call(args, Thread.current[:session][:user_ontologies])
  end

  def self.post(method, object)
    return unless Thread.current[:session] && Thread.current[:session][:user_ontologies] && USER_ONTOLOGY_FILTER_POST.key?(method.to_sym)
    USER_ONTOLOGY_FILTER_POST[method.to_sym].call(object, Thread.current[:session][:user_ontologies])
  end

end
