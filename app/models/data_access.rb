require 'BioPortalRestfulCore'
require "digest/sha1"

class DataAccess
  SERVICE = BioPortalRestfulCore #sets what backend we are using
  
  CACHE_EXPIRE_TIME=60*60*1
  NO_CACHE = false
    
  def self.getNode(ontology,node_id,view = false) 
    view_string=''
    if view
      view_string = 'view_'
    end
    
    if CACHE.get("#{view_string}#{param(ontology)}::#{node_id.gsub(" ","%20")}").nil? || NO_CACHE
      node = SERVICE.getNode(ontology,node_id,view)
      unless  node.kind_of?(Hash) && node[:error]
        CACHE.set("#{view_string}#{param(ontology)}::#{node_id.gsub(" ","%20")}",node,CACHE_EXPIRE_TIME)
      end
      return node
    else
      return CACHE.get("#{view_string}#{param(ontology)}::#{node_id.gsub(" ","%20")}")
    end
  end

  def self.getLightNode(ontology,node_id,view = false) 
    view_string=''
    if view
      view_string = 'view_'
    end
    
    if CACHE.get("#{view_string}#{param(ontology)}::#{node_id.gsub(" ","%20")}_light").nil? || NO_CACHE
      node = SERVICE.getLightNode(ontology,node_id,view)
      unless  node.kind_of?(Hash) && node[:error]
        CACHE.set("#{view_string}#{param(ontology)}::#{node_id.gsub(" ","%20")}_light",node,CACHE_EXPIRE_TIME)
      end
      return node
    else
      return CACHE.get("#{view_string}#{param(ontology)}::#{node_id.gsub(" ","%20")}_light")
    end
  end
    
  def self.getView(view_id)
    if CACHE.get("view::#{param(view_id)}").nil? || NO_CACHE
      view = SERVICE.getView(view_id)
      unless view.kind_of?(Hash) && view[:error]
        CACHE.set("view::#{param(view_id)}",view,CACHE_EXPIRE_TIME)
      end
      return view
    else
      return CACHE.get("view::#{param(view_id)}")
    end            
  end

  def self.getViews(ont_id)
    if CACHE.get("views::#{param(ont_id)}").nil? || NO_CACHE
      views = SERVICE.getViews(ont_id)
      unless views.kind_of?(Hash) && views[:error]
        CACHE.set("views::#{param(ont_id)}",views,CACHE_EXPIRE_TIME)
      end
      return views
    else
      return CACHE.get("views::#{param(ont_id)}")
    end            
  end
    
  def self.getTopLevelNodes(ontology,view=false)

    view_string=''
    if view
      view_string = 'view_'
    end
    
    if CACHE.get("#{view_string}#{param(ontology)}::_top").nil? || NO_CACHE
      topNodes = SERVICE.getTopLevelNodes(ontology,view)
      unless topNodes.kind_of?(Hash) && topNodes[:error] 
        CACHE.set("#{view_string}#{param(ontology)}::_top",topNodes,CACHE_EXPIRE_TIME)
      end
      return topNodes
    else
      return CACHE.get("#{view_string}#{param(ontology)}::_top")
    end
  end
    
  def self.getOntologyList
#    puts "Calling DataAccess.getOntologyList()"
    if CACHE.get("ont_list").nil? || NO_CACHE
      list = SERVICE.getOntologyList
      
      unless list.kind_of?(Hash)  && list[:error] 
        for item in list
          item.preload_ontology            
        end
        CACHE.set("ont_list",list,CACHE_EXPIRE_TIME)
      end
      
      return list
    else
      return CACHE.get("ont_list")
    end
  end

  def self.getCategories
    # puts "Calling DataAccess.getCategories()"
    if CACHE.get("categories").nil? || NO_CACHE
      list = SERVICE.getCategories
      
      unless list.kind_of?(Hash)  && list[:error]         
        CACHE.set("categories",list,CACHE_EXPIRE_TIME)
      end
      
      return list
    else
      return CACHE.get("categories")
    end
  end


    
  def self.getActiveOntologies
    # puts "Calling DataAccess.getActiveOntologies()"
    if CACHE.get("act_ont_list").nil? || NO_CACHE
      list = SERVICE.getOntologyList
      unless list.kind_of?(Hash) && list[:error]
        activeOntologies = []
        for item in list
          if item.statusId.to_i.eql?(3)
            activeOntologies << item
          end
        end
        CACHE.set("act_ont_list",activeOntologies,CACHE_EXPIRE_TIME)
        list = activeOntologies
      end
      return list
    else
      return CACHE.get("act_ont_list")
    end
  end

  def self.getOntologyVersions(ontology)
    if CACHE.get("#{ontology}::_versions").nil? || NO_CACHE
     details = SERVICE.getOntologyVersions(ontology)
      unless details.kind_of?(Hash) && details[:error]
        CACHE.set("#{ontology}::_versions",details,CACHE_EXPIRE_TIME)
      end
      return details
    else
      return CACHE.get("#{ontology}::_versions")
    end
  end


  def self.getOntology(ontology)
    # puts "Calling DataAccess.getOntology(#{ontology})"
    if CACHE.get("#{ontology}::_details").nil? || NO_CACHE
      details = SERVICE.getOntology(ontology)
      unless details.kind_of?(Hash) && details[:error]
        CACHE.set("#{ontology}::_details",details,CACHE_EXPIRE_TIME)
      end        
      return details
    else
      return CACHE.get("#{ontology}::_details")
    end
  end
    
  def self.getLatestOntology(ontology)
    # puts "Calling DataAccess.getLatestOntology(#{ontology})"
    if CACHE.get("#{ontology}::_latest").nil? || NO_CACHE
      details = SERVICE.getLatestOntology(ontology)
      unless details.kind_of?(Hash) && details[:error]
        CACHE.set("#{ontology}::_latest",details,CACHE_EXPIRE_TIME)
      end        
      return details
    else
      return CACHE.get("#{ontology}::_latest")
    end
  end

  def self.getNodeNameExact(ontologies,search,page)
    # prevents long keys
    # cache_key = Digest::SHA1.hexdigest("#{param(ontologies.join("|"))}::_searchsound::#{param(search)}");

    # if CACHE.get(cache_key).nil? || NO_CACHE
        results,pages = SERVICE.getNodeNameExact(ontologies,search,page)
        # unless results.kind_of?(Hash) && results[:error]
          # CACHE.set(cache_key,results)
        # end
        return results,pages
    # else
      # return CACHE.get(cache_key)
    # end
  end

  def self.getNodeNameContains(ontologies,search,page) 
    # prevents long keys
    # cache_key = Digest::SHA1.hexdigest("#{param(ontologies.join("|"))}::_search::#{param(search)}")
         
    # if CACHE.get(cache_key).nil? || NO_CACHE
      results,pages = SERVICE.getNodeNameContains(ontologies,search,page)
    # unless results.kind_of?(Hash) && results[:error]
      # CACHE.set(cache_key,results)
    # end
    return results,pages
    # else
      # return CACHE.get(cache_key)
    # end
  end

  def self.getUsers
    if CACHE.get("user_list").nil? || NO_CACHE
      results = SERVICE.getUsers  
      unless results.kind_of?(Hash) && results[:error]
        CACHE.set("user_list",results)
      end        
      return results
    else
      return CACHE.get("user_list")
    end
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
    
    
  def self.getUser(user_id)
    if CACHE.get("user::#{user_id}").nil? || NO_CACHE
       results = SERVICE.getUser(user_id)
       #puts results.inspect
       unless results.kind_of?(Hash) && results[:error]
         CACHE.set("user::#{user_id}",results)
       end        
       return results
    else
      return CACHE.get("user::#{user_id}")
    end
  end

  def self.authenticateUser(username,password)    
    user = SERVICE.authenticateUser(username,password)
    return user
  end
    
  def self.createUser(params)    
    user = SERVICE.createUser(params)
    CACHE.delete("user_list")
    return user
  end
    
   def self.updateUser(params,id)
    user = SERVICE.updateUser(params,id)
    CACHE.delete("user_list")
    CACHE.delete("user::#{id}")
    return user
  end
    
  def self.createOntology(params)
    ontology = SERVICE.createOntology(params)
    CACHE.delete("act_ont_list")
    CACHE.delete("ont_list")
    unless(params[:ontologyId].nil?)
      CACHE.delete("#{params[:ontologyId]}::_versions")
      CACHE.delete("#{params[:ontologyId]}::_details")
    end
    return ontology
  end
    
  def self.updateOntology(params,version_id)
    # puts "UPDATING ONTOLOGY #{params.inspect}"
    ontology = SERVICE.updateOntology(params,version_id)
    CACHE.delete("#{version_id}::_details")
    CACHE.delete("ont_list")
    unless(params[:ontologyId].nil?)
      CACHE.delete("#{params[:ontologyId]}::_versions")
    end
    return ontology
  end
    
  def self.download(id)
    return SERVICE.download(id)
  end
    
  def self.getAttributeValueContains(ontologies,search,page)
    # if CACHE.get("#{param(ontologies.join("|"))}::_searchAttrCont::#{param(search)}").nil? || NO_CACHE
      results,pages = SERVICE.getAttributeValueContains(ontologies,search,page)
      # CACHE.set("#{param(ontologies.join("|"))}::_searchAttrCont::#{param(search)}",results)
      return results,pages
    # else
      # return CACHE.get("#{param(ontologies.join("|"))}::_searchAttrCont::#{param(search)}")
    # end
  end
    
  def self.getAttributeValueExact(ontologies,search,page)
    # if CACHE.get("#{param(ontologies.join("|"))}::_searchAttrSound::#{param(search)}").nil? || NO_CACHE
      results,pages = SERVICE.getAttributeValueExact(ontologies,search,page)
      # CACHE.set("#{param(ontologies.join("|"))}::_searchAttrSound::#{param(search)}",results)
      return results,pages
    # else
      # return CACHE.get("#{param(ontologies.join("|"))}::_searchAttrSound::#{param(search)}")
    # end
  end

#    def self.getNetworkNeighborhoodImage(ontology,node_id,associations=nil)
#      if CACHE.get("#{param(ontology)}::#{node_id}_nnImage::#{associations}").nil?
#        image = SERVICE.getNetworkNeighborhoodImage(ontology,node_id,associations) 
#        CACHE.set("#{param(ontology)}::#{node_id}_nnImage::#{associations}",image)
#        return image
#      else
#        return CACHE.get("#{param(ontology)}::#{node_id}_nnImage::#{associations}")
#      end
#    end
    
#    def self.getPathToRootImage(ontology,node_id,associations=nil)
#      if CACHE.get("#{param(ontology)}::#{node_id}_ptrImage::#{associations}").nil?
#        image = SERVICE.getPathToRootImage(ontology,node_id,associations) 
#        CACHE.set("#{param(ontology)}::#{node_id}_ptrImage::#{associations}",image)
#        return image
#      else
#        return CACHE.get("#{param(ontology)}::#{node_id}_ptrImage::#{associations}")
#      end
#    end
    
  def self.getPathToRoot(ontology,source)      
    return SERVICE.getPathToRoot(ontology,source)
  end
  
  def self.param(string)
    return string.to_s.gsub(" ","_")
  end
   
  def self.getDiffs(ontology)
    pairs = SERVICE.getDiffs(ontology)
    return pairs
  end
  
end