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
  
  # This is used to hold original concept names because we turn them into links
  # Original names can be used for comparison if needed (like in the IS_A, PART_OF icon generation)
  attr_accessor :original_properties
  
  def initialize(hash = nil, params = nil)
    if hash.nil?
      return
    end
    
    # Default values
    self.version_id = params[:ontology_id]
    self.properties = {}
    self.children = []
    self.original_properties = {}
    
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
                self.children.sort! { |a,b| a.label.downcase <=> b.label.downcase } unless self.children.empty?
              end
          else
            list_values = []
            list_values_orig = []
            
            unless relation_value.nil?
              relation_value.each do |list_item|
                if list_item.kind_of? Hash
                  # In order to link to terms, we look for ids and labels
                  # which identify hashes that represent terms. This is done
                  # because we don't have a way to identify classBean elements
                  # at this point.
                  test = !list_item['type'].nil? && !list_item['type'].eql?("individual")
                  if !list_item['label'].nil? && !list_item['id'].nil? && !list_item['id'].start_with?("@") && (!list_item['type'].nil? && !list_item['type'].eql?("individual"))
                  	list_values_orig << list_item['label']
                    list_values << "<a href='/visualize/%ONT%/?conceptid=#{CGI.escape(list_item['id'])}'>#{list_item['label']}</a>"
                  else
                  	list_values_orig << list_item['label']
                    list_values << list_item['label'] rescue ""
                  end
                else
              	  list_values_orig << list_item
                  list_values << list_item
                end
              end
            end
            
            self.properties[relation_name] = list_values.join(" | ")
            self.original_properties[relation_name] = list_values_orig.join(" | ")
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
  
  def ontology
    return DataAccess.getOntology(self.version_id)
  end
  
  def ontology_name
    return DataAccess.getOntology(self.version_id).displayLabel
  end
  
  def ontology_id
    return DataAccess.getOntology(self.version_id).ontologyId
  end
  
  def mapping_count
    DataAccess.getMappingCountConcept(self.ontology.ontologyId, self.fullId)
  end

  def note_count
    DataAccess.getNotesForConcept(DataAccess.getOntology(self.version_id).ontologyId, CGI.escape(self.fullId_proper), false, true).size rescue "0"
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
   "Node_Name: #{self.label}  Node_ID: #{self.id}"
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