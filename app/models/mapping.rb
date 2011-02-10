class Mapping
  
  attr_accessor :id  
  attr_accessor :source
  attr_accessor :target
  attr_accessor :relation
  attr_accessor :date
  attr_accessor :submitted_by
  attr_accessor :mapping_type
  attr_accessor :source_ontology
  attr_accessor :target_ontology
  attr_accessor :comment
  attr_accessor :source_ontology_version
  attr_accessor :target_ontology_version
  attr_accessor :mapping_source
  attr_accessor :mapping_source_name
  attr_accessor :mapping_source_contact_info
  attr_accessor :mapping_source_site
  attr_accessor :mapping_source_algorithm
  attr_accessor :dependency
  
  def initialize(hash = nil, params = nil)
    return if hash.nil? || hash.empty?
    
    self.id = hash['id']
    self.source = hash['source']
    self.target = hash['target']
    self.relation = hash['relation']
    self.date = Time.iso8601(hash['date'].gsub(" PST", "-07:00").gsub(" PDT", "-07:00").gsub(" ", "T")).localtime
    self.submitted_by = hash['submittedBy'].to_i
    self.mapping_type = hash['mappingType']
    self.source_ontology = hash['sourceOntologyId'].to_i
    self.target_ontology = hash['targetOntologyId'].to_i
    self.source_ontology_version = hash['createdInSourceOntologyVersion'].to_i
    self.target_ontology_version = hash['createdInTargetOntologyVersion'].to_i
    self.comment = hash['comment'] rescue ""
    self.mapping_source = hash['mappingSource'] rescue ""
    self.mapping_source_name = hash['mappingSourceName'] rescue ""
    self.mapping_source_name = hash['mappingSourceName'] rescue ""
    self.mapping_source_contact_info = hash['mappingSourceContaInfo'] rescue ""
    self.mapping_source_site = hash['mappingSourceSite'] rescue ""
    self.mapping_source_algorithm = hash['mappingSourceAlgorithm'] rescue ""
    self.dependency = hash['dependency'] rescue ""
  end

  def source_node
    return DataAccess.getNode(self.source_ontology_version, self.source)
  end
  
  def dest_node
    return DataAccess.getNode(self.target_ontology_version, self.target) rescue nil
  end

  def user
    return DataAccess.getUser(self.submitted_by)
  end
  
  def ontology
    DataAccess.getLatestOntology(self.sourceOntologyId)
  end
  
  ##
  # Aliases for old properties, hopefully we won't have to update views
  # because the aliases should provide the same information.
  ##
  
  alias :user_id :submitted_by
  alias :user_id= :submitted_by=
  
  alias :source_id :source
  alias :source_id= :source=
  
  alias :destination_id :target
  alias :destination_id= :target=
  
  alias :map_type :mapping_type
  alias :map_type= :mapping_type=
  
  alias :source_ont :source_ontology
  alias :source_ont= :source_ontology=
  
  alias :destination_ont :target_ontology
  alias :destination_ont= :target_ontology=
  
  alias :created_at :date
  alias :created_at= :date=
  
  alias :updated_at :date
  alias :created_at= :date=
  
  alias :relationship_type :relation
  alias :relationship_type= :relation=
  
  alias :map_source :mapping_source_name
  alias :map_source= :mapping_source_name=
  
  def source_name
    DataAccess.getLightNode(self.source_ontology_version, self.source).label rescue ""
  end

  def destination_name
    DataAccess.getLightNode(self.target_ontology_version, self.target).label rescue ""
  end
  
  def source_ont_name
    DataAccess.getOntology(self.source_ontology_version).displayLabel rescue ""
  end

  def destination_ont_name
    DataAccess.getOntology(self.target_ontology_version).displayLabel rescue ""
  end
  
  alias :source_version_id :source_ontology_version
  alias :source_version_id= :source_ontology_version=
  
  alias :destination_version_id :target_ontology_version
  alias :destination_version_id= :target_ontology_version=

end
