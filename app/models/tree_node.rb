class TreeNode
  attr_accessor :label
  attr_accessor :id
  attr_accessor :fullId
  attr_accessor :ontology_id
  attr_accessor :children 
  attr_accessor :ontology_name
  attr_accessor :child_size
  attr_accessor :note_icon
  attr_accessor :map_icon
  attr_accessor :relation_icon
  attr_accessor :properties
  attr_accessor :original_properties

  def initialize(object = nil, parent = nil)
    unless object.nil?
      self.id = object.id.gsub(" ","%20")
      self.fullId = object.fullId
      initialize_node(object, parent)
    end
  end

  def initialize_node(node_object, parent_node = nil)
    self.label = node_object.label
    self.child_size = node_object.child_size
    self.ontology_name = node_object.ontology_name  
    self.ontology_id = node_object.version_id 
    
    #these are removed for performance
  #  if node_object.note_count >0
  #    self.note_icon = true
  #  end
  #  if node_object.mapping_count >0
  #    self.map_icon = true
  #  end
  
    unless node_object.children.empty?
      self.set_children(node_object.children, node_object)
    end
    
    if node_object.properties.nil?
      self.properties ={}
    else
      self.properties = node_object.properties
    end
    
    if node_object.original_properties.nil?
      self.original_properties = {}
    else
      self.original_properties = node_object.original_properties
    end
    
    if !parent_node.nil? && self.ontology.format.eql?("OBO") 
	  if !parent_node.original_properties.nil? && !parent_node.original_properties.empty?
	    for key in parent_node.original_properties.keys
	      relations = parent_node.original_properties[key].split(" | ").map{|x| x.strip}
	      if relations.include?(self.label)
	        if key.include?("is_a")
	          self.relation_icon = " <img src='/images/is_a.gif' style='vertical-align: middle;'>"
	        elsif key.include?("part_of")
	          self.relation_icon = " <img src='/images/part_of.gif' style='vertical-align: middle;'>"
	        end
	      end
	    end
	  end
    end
  end

  def to_param
    param = URI.escape(self.id,":/?#!")
    return "#{param}"
  end
  
  def set_children(node_list, parent = nil)
    self.children =[]
    unless node_list.nil?
      for node in node_list
        self.children << TreeNode.new(node, parent)
      end
    end
  end
    
  def ontology
    return DataAccess.getOntology(self.ontology_id)
  end
  
  def expanded
    if !children.nil? && children.length>0
     return true
    else
     return false      
    end
  end
  
  def name
    @label
  end
  
  def to_s
    "Tree_Node_Name: #{self.name}  Node_ID: #{self.id}"
  end

end