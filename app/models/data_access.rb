require 'BioPortalRestfulCore'
require "digest/sha1"

class DataAccess
  # Sets what backend we are using
  SERVICE = BioPortalRestfulCore
  
  # Last multiplicand is number of hours 
  CACHE_EXPIRE_TIME = 60*60*4
  SHORT_CACHE_EXPIRE_TIME = 60*60*1
  MEDIUM_CACHE_EXPIRE_TIME = 60*60*12
  LONG_CACHE_EXPIRE_TIME = 60*60*24
  EXTENDED_CACHE_EXPIRE_TIME = 60*60*336 # two weeks

  NO_CACHE = false
  
  def self.getNode(ontology_id, node_id, view = false) 
    view_string = view ? "view_" : ""
    return self.cache_pull("#{view_string}#{param(ontology_id)}::#{node_id.gsub(" ","%20")}", "getNode", { :ontology_id => ontology_id, :concept_id => node_id })
  end

  def self.getLightNode(ontology_id, node_id, view = false)
    view_string = view ? "view_" : ""
    return self.cache_pull("#{view_string}#{param(ontology_id)}::#{node_id.gsub(" ","%20")}_light", "getLightNode", { :ontology_id => ontology_id, :concept_id => node_id })
  end
  
  def self.getView(view_id)
    return self.cache_pull("view::#{param(view_id)}", "getView", { :view_id => view_id })
  end
  
  def self.getViews(ontology_id)
    return self.cache_pull("views::#{param(ontology_id)}", "getViews", { :ontology_id => ontology_id })
  end
  
  def self.getTopLevelNodes(ontology_id, view = false)
    view_string = view ? "view_" : ""
    return self.cache_pull("#{view_string}#{param(ontology_id)}::_top", "getTopLevelNodes", { :ontology_id => ontology_id, :view => view })
  end
  
  def self.getOntologyList
    return self.cache_pull("ont_list", "getOntologyList", nil, MEDIUM_CACHE_EXPIRE_TIME)
  end
  
  def self.getCategories
    return self.cache_pull("categories", "getCategories", nil, EXTENDED_CACHE_EXPIRE_TIME)
  end
  
  def self.getGroups
    return self.cache_pull("groups", "getGroups", nil, EXTENDED_CACHE_EXPIRE_TIME)
  end
  
  def self.getActiveOntologies
    return self.cache_pull("act_ont_list", "getActiveOntologyList", nil, MEDIUM_CACHE_EXPIRE_TIME)
  end
  
  def self.getOntologyVersions(ontology_virtual_id)
    return self.cache_pull("#{ontology_virtual_id}::_versions", "getOntologyVersions", { :ontology_virtual_id => ontology_virtual_id })
  end
  
  def self.getOntology(ontology_id)
    return self.cache_pull("#{ontology_id}::_details", "getOntology", { :ontology_id => ontology_id })
  end
  
  def self.getOntologyMetrics(ontology_id)
    metrics = self.cache_pull("#{ontology_id}::_metrics", "getOntologyMetrics", { :ontology_id => ontology_id })
    
    # Check to see if there were valid metrics returned, else get older version 
    if metrics.nil? || metrics.numberOfClasses.to_i <= 0
      versions = self.getOntologyVersions(self.getOntology(ontology_id).ontologyId)
      versions.sort! { |x, y| x.id <=> y.id }
      versions.reverse!
      versions.each_with_index do |version, index|
        if version.id.eql?(ontology_id)
          next
        end
        metrics_old = self.cache_pull("#{version.id}::_metrics", "getOntologyMetrics", { :ontology_id => version.id })
        if !metrics_old.nil? && metrics_old.numberOfClasses.to_i > 0
          return metrics_old
        elsif index >= 20 # 21 most recent versions are checked (3 weeks)
          return nil
        end
      end
    end
    
    return metrics
  end
  
  def self.getLatestOntology(ontology_virtual_id)
    return self.cache_pull("#{ontology_virtual_id}::_latest", "getLatestOntology", { :ontology_virtual_id => ontology_virtual_id })
  end
  
  def self.getUsers
    return self.cache_pull("user_list", "getUsers", nil, LONG_CACHE_EXPIRE_TIME)
  end
  
  def self.getNodeNameContains(ontologies,search,page) 
    results,pages = SERVICE.getNodeNameContains(ontologies,search,page)
    return results,pages
  end

  def self.getUserByEmail(email)
    found_user = nil
    users = self.getUsers
    for user in users
      if user.email.eql?(email)
        found_user = user
      end
    end
    return found_user              
  end
  
  def self.getUserByUsername(username)
    found_user = nil
    users = self.getUsers
    for user in users
      if user.username.eql?(username)
        found_user = user
      end
    end
    return found_user              
  end
  
  def self.getUser(user_id)
    return self.cache_pull("user::#{user_id}", "getUser", { :user_id => user_id })
  end
  
  def self.authenticateUser(username, password)    
    user = SERVICE.authenticateUser(username, password)
    return user
  end
  
  def self.createUser(params)    
    user = SERVICE.createUser(params)
    CACHE.delete("user_list")
    return user
  end
  
  def self.updateUser(params, user_id)
    user = SERVICE.updateUser(params, user_id)
    CACHE.delete("user_list")
    CACHE.delete("user::#{user_id}")
    return user
  end
  
  def self.createOntology(params)
    ontology = SERVICE.createOntology(params)
    CACHE.delete("act_ont_list")
    CACHE.delete("ont_list")
    unless(params[:ontologyId].nil?)
      CACHE.delete("#{params[:ontologyId]}::_versions")
      CACHE.delete("#{params[:ontologyId]}::_details")
      CACHE.delete("ont_list")
    end
    return ontology
  end
  
  def self.updateOntology(params, ontology_id)
    SERVICE.updateOntology(params, ontology_id)
    CACHE.delete("#{ontology_id}::_details")
    CACHE.delete("ont_list")
    unless(params[:ontologyId].nil?)
      CACHE.delete("#{params[:ontologyId]}::_versions")
      CACHE.delete("#{self.getLatestOntology(params[:ontologyId]).id}::_details")
      CACHE.delete("ont_list")
    end
    return self.getLatestOntology(params[:ontologyId])
  end
  
  def self.download(ontology_id)
    return SERVICE.download(ontology_id)
  end
  
  def self.getPathToRoot(ontology_id, source)
    return self.cache_pull("#{param(ontology_id)}::#{source.gsub(" ","%20")}_path_to_root", "getPathToRoot", { :ontology_id => ontology_id, :concept_id => source })
  end
  
  def self.getDiffs(ontology_id)
    pairs = SERVICE.getDiffs(ontology_id)
    return pairs
  end
  
private

  def self.param(string)
    return string.to_s.gsub(" ","_")
  end
   
  def self.cache_pull(token, service_call, params = nil, expires = CACHE_EXPIRE_TIME)
    if NO_CACHE || CACHE.get(token).nil?
      if params
        retrieved_object = SERVICE.send(:"#{service_call}", params)
      else
        retrieved_object = SERVICE.send(:"#{service_call}")
      end
      
      unless retrieved_object.kind_of?(Hash) && retrieved_object[:error]
        CACHE.set(token, retrieved_object, expires)
      end
      
      return retrieved_object
    else
      return CACHE.get(token)
    end
  end
  
end
