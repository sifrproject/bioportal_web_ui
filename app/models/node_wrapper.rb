require 'uri'
require 'cgi'

class NodeWrapper
  
  attr_accessor :synonyms
  attr_accessor :definitions
  attr_accessor :type
  
  attr_accessor :id
  attr_accessor :fullId
  attr_accessor :label  
  attr_accessor :isActive
  attr_accessor :properties
  attr_accessor :version_id
  attr_accessor :child_size
  attr_accessor :children
  attr_accessor :parent_association
  
  def initialize(hash = nil, params = nil)
    if hash.nil?
      return
    end
    
    # Default values
    self.version_id = params[:ontology_id]
    self.properties = {}
    self.children = []
    
    hash.each do |key,value|
      if key.eql?("relations")
        value.each do |relation_name,relation_value|
          case relation_name
            when "ChildCount"
            self.child_size = relation_value.to_i
            when "SubClass"
            unless relation_value.nil?
              relation_value.each do |list_value|
                self.children << NodeWrapper.new(list_value, params) unless list_value.empty?
              end
              self.children.sort! { |a,b| a.name.downcase <=> b.name.downcase } unless self.children.empty?
            end
          else
            list_values = []
            
            unless relation_value.nil?
              relation_value.each do |list_item|
                if list_item.kind_of? Hash
                  list_values << list_item['label'] rescue ""
                else
                  list_values << list_item
                end
              end
            end
            
            self.properties[relation_name] = list_values.join(" | ")
          end
        end
      else
        begin
          self.send("#{key}=", value)
        rescue Exception
          LOG.add :debug, "Missing '#{key}' attribute in NodeWrapper"
        end
      end
    end
    
    self.child_size = 0 if self.child_size.nil?
  end
  
  def is_browsable
    self.type.downcase.eql?("class") rescue ""
  end
  
  def store(key, value)
    begin
      send("#{key}=", value)
    rescue Exception
      LOG.add :debug, "Missing '#{key}' attribute in NodeWrapper"
    end
  end
  
  def name
    @label
  end
  
  def name=(value)
    @label = value
  end
  
  def to_param
    URI.escape(self.id,":/?#!").to_s
  end
  
  def ontology_name
    return DataAccess.getOntology(self.version_id).displayLabel
  end
  
  def ontology_id
    return DataAccess.getOntology(self.version_id).ontologyId
  end
  
  def mapping_count
    if CACHE.get("#{self.ontology_id}::#{self.id.gsub(" ","%20")}_MappingCount").nil?
        count = Mapping.count(:conditions=>{:source_ont => self.ontology_id, :source_id => self.id})
        CACHE.set("#{self.ontology_id}::#{self.id.gsub(" ","%20")}_MappingCount",count)
      return count
    else
      return CACHE.get("#{self.ontology_id}::#{self.id.gsub(" ","%20")}_MappingCount")
    end
  end

  def note_count
    if CACHE.get("#{DataAccess.getOntology(self.version_id).ontologyId}::#{CGI.escape(self.fullId_proper)}_NoteCount").nil?
        count = DataAccess.getNotesForConcept(DataAccess.getOntology(self.version_id).ontologyId, CGI.escape(self.fullId_proper), false, true).size rescue "0"
        CACHE.set("#{DataAccess.getOntology(self.version_id).ontologyId}::#{CGI.escape(self.fullId_proper)}_NoteCount", count)
      return count
    else
      return CACHE.get("#{DataAccess.getOntology(self.version_id).ontologyId}::#{CGI.escape(self.fullId_proper)}_NoteCount")
    end
  end
    
  def note_count_old
    if CACHE.get("#{self.ontology_id}::#{self.id.gsub(" ","%20")}_NoteCount").nil?
      count = MarginNote.count(:conditions=>{:ontology_id => self.ontology_id, :concept_id =>self.id})
      CACHE.set("#{self.ontology_id}::#{self.id.gsub(" ","%20")}_NoteCount",count)
      return count
    else
      return CACHE.get("#{self.ontology_id}::#{self.id.gsub(" ","%20")}_NoteCount")
    end
  end
  
  def networkNeighborhood(relationships = nil)         
    DataAccess.getNetworkNeighborhoodImage(self.ontology_name,self.id,relationships)
  end
  
  def pathToRootImage(relationships = nil) 
    DataAccess.getPathToRootImage(self.ontology_name,self.id,relationships)
  end
  
  # def children(relationship=["is_a"])       
  #   DataAccess.getChildNodes(self.ontology_name,self.id,relationship)
  # end
  
  def parent(relationship=["is_a"])
    DataAccess.getParentNodes(self.ontology_name,self.id,relationship)
  end
  
  def path_to_root
    return DataAccess.getPathToRoot(self.version_id,self.id)    
  end
  
  def to_s
   "Node_Name: #{self.name}  Node_ID: #{self.id}"
  end
  
  def fullId_proper
    ontology_format = DataAccess.getOntology(self.version_id).format
    if ontology_format.eql?("OBO") || ontology_format.eql?("RRF") || ontology_format.eql?("LEXGRID-XML") || ontology_format.eql?("META") 
      return self.id
    else
      return self.fullId
    end
  end
  
end