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
    return self.cache_pull("#{view_string}#{param(ontology_id)}::#{node_id.to_s.gsub(" ","%20")}", "getNode", { :ontology_id => ontology_id, :concept_id => node_id })
  end

  def self.getLightNode(ontology_id, node_id, view = false)
    view_string = view ? "view_" : ""
    return self.cache_pull("#{view_string}#{param(ontology_id)}::#{node_id.to_s.gsub(" ","%20")}_light", "getLightNode", { :ontology_id => ontology_id, :concept_id => node_id })
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
  
  def self.getLatestOntology(ontology_virtual_id)
    return self.cache_pull("#{ontology_virtual_id}::_latest", "getLatestOntology", { :ontology_virtual_id => ontology_virtual_id })
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

  def self.getNote(ontology_id, note_id, threaded = false, virtual = false)
    threaded_token = threaded ? "::threaded" : ""
    return self.cache_pull("#{note_id}#{threaded_token}", "getNote", { :ontology_id => ontology_id, :note_id => note_id, :threaded => threaded, :virtual => virtual }, EXTENDED_CACHE_EXPIRE_TIME)
  end
  
  def self.getNotesForConcept(ontology_id, concept_id, threaded = false, virtual = false)
    return self.cache_pull("#{concept_id}::notes", "getNotesForConcept", { :ontology_id => ontology_id, :concept_id => concept_id, :threaded => threaded, :virtual => virtual })
  end
  
  def self.getNotesForIndividual(ontology_virtual_id, individual_id, threaded = false)
    return self.cache_pull("#{individual_id}::notes", "getNotesForIndividual", { :ontology_virtual_id => ontology_virtual_id, :individual_id => individual_id, :threaded => threaded })
  end
  
  def self.getNotesForOntology(ontology_virtual_id, threaded = false, virtual = false)
    return self.cache_pull("#{ontology_virtual_id}::notes", "getNotesForOntology", { :ontology_virtual_id => ontology_virtual_id, :threaded => threaded, :virtual => virtual })
  end
  
  def self.updateNote(ontology_id, params, virtual = false)
    note = SERVICE.updateNote(ontology_id, params, virtual)
    CACHE.set("#{note.id}", note, CACHE_EXPIRE_TIME)
    CACHE.delete("#{params[:appliesTo]}::notes") if params[:appliesToType].eql?("Class")
    CACHE.delete("#{ontology_id}::notes")
    note
  end
  
  def self.createNote(params)
    note = SERVICE.createNote(params)
    CACHE.set("#{note.id}", note, CACHE_EXPIRE_TIME)
    CACHE.delete("#{params[:appliesTo]}::notes") if params[:appliesToType].eql?("Class")
    CACHE.delete("#{params[:ontology_virtual_id]}::notes")
    
    # If this note is in a thread, traverse to top and delete from cache
    if params[:appliesToType].eql?("Note")
      note_temp = self.getNote(params[:ontology_virtual_id], params[:appliesTo], false, true)
      while note_temp.appliesTo['type'].eql?("Note")
        old_note_id = note_temp.id
        parent_note_id = self.getNote(params[:ontology_virtual_id], note_temp.id, false, true).appliesTo['id']
        CACHE.delete("#{old_note_id}")
        CACHE.delete("#{old_note_id}::threaded")
        note_temp = self.getNote(params[:ontology_virtual_id], parent_note_id, false, true)
      end
      CACHE.delete("#{note_temp.id}::threaded")
      CACHE.delete("#{note_temp.id}")
    end

    # If this note applies to a class/concept/term then delete the count for that concept
    CACHE.delete("#{params[:ontology_virtual_id]}::#{params[:appliesTo]}_NoteCount") if params[:appliesToType].eql?("Class")
    
    # Remove cached notes for this ontology
    CACHE.delete("#{params[:ontology_virtual_id]}::notes")
    
    # Add note to index table
    notes_index = NotesIndex.new
    notes_index.populate(note)
    notes_index.save
    
    # Adds note to syndication
    event = EventItem.new
    event.event_type = "Note"
    event.event_type_id = note.id
    event.ontology_id = params[:ontology_virtual_id]
    event.save

    note
  end
  
  def self.getNodeNameContains(ontologies,search,page) 
    results,pages = SERVICE.getNodeNameContains(ontologies,search,page)
    return results,pages
  end

  def self.getUsers
    return self.cache_pull("user_list", "getUsers", nil, LONG_CACHE_EXPIRE_TIME)
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
  
  def self.updateView(params, ontology_id)
    SERVICE.updateOntology(params, ontology_id)
    CACHE.delete("view::#{ontology_id}")
    CACHE.delete("views::#{self.getOntology(params[:viewOnOntologyVersionId]).ontologyId}")
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
