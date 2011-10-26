require 'BioPortalRestfulCore'
require "digest/sha1"
include Spawn

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

  def self.getNode(ontology_id, node_id, max_children = $MAX_CHILDREN, view = false)
    max_children = max_children.nil? ? $MAX_CHILDREN : max_children
    view_string = view ? "view_" : ""
    return self.cache_pull("#{view_string}#{param(ontology_id)}::#{node_id.to_s.gsub(" ","%20")}::max_children=#{max_children}", "getNode", { :ontology_id => ontology_id, :concept_id => node_id, :max_children => max_children })
  end

  def self.getLightNode(ontology_id, node_id, max_children = $MAX_CHILDREN, view = false)
    max_children = max_children.nil? ? $MAX_CHILDREN : max_children
    view_string = view ? "view_" : ""
    return self.cache_pull("#{view_string}#{param(ontology_id)}::#{node_id.to_s.gsub(" ","%20")}::max_children=#{max_children}_light", "getLightNode", { :ontology_id => ontology_id, :concept_id => node_id, :max_children => max_children })
  end

  def self.getNodeLabel(ontology_id, node_id)
    return self.cache_pull("label::#{param(ontology_id)}::#{param(node_id.to_s)}", "getNodeLabel", { :ontology_id => ontology_id, :concept_id => node_id })
  end

  def self.getView(view_id)
    return self.cache_pull("view::#{param(view_id)}", "getView", { :view_id => view_id })
  end

  def self.getViewList
    return self.cache_pull("view_list", "getViewList", nil, MEDIUM_CACHE_EXPIRE_TIME)
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

  def self.getOntologyAcronyms
    CACHE.set("ontology_acronyms", Array.new)

    ontologies = self.getOntologyList

    ontology_acronyms = []
    ontologies.each do |ontology|
      ontology_acronyms << ontology.abbreviation.downcase unless ontology.abbreviation.nil?
    end

    CACHE.set("ontology_acronyms", ontology_acronyms, MEDIUM_CACHE_EXPIRE_TIME)

    ontology_acronyms
  end

  def self.getTotalTermCount
    ontology_term_counts = self.getTermsCountOntologies

    if ontology_term_counts.nil? || ontology_term_counts.length == 0
      # Return a default term count, based on a value from Feb 2011
      return 4849100
    end

    total_terms = 0
    ontology_term_counts.each do |ontology, terms|
      total_terms += terms.to_i rescue 0
    end

    total_terms
  end

  def self.getTermsCountOntologies
    ontologies = self.getOntologyList

    terms = CACHE.get("terms_all_ontologies")
    running = CACHE.get("running_term_calc")

    if (terms.nil? || terms.to_s.length == 0) && (running.nil? || !running.eql?("true"))
      CACHE.set("running_term_calc", "true", 60*15)

      # Set a default hash either empty or based on an old calculation
      default_terms = CACHE.get("terms_all_ontologies_old").nil? ? Hash.new : CACHE.get("terms_all_ontologies_old")
      CACHE.set("terms_all_ontologies", default_terms)
      terms = default_terms

      # Spawn a process to calculate total term size
      spawn(:argv => "spawn_ontology_terms") do
        ontology_terms = {}
        ontologies.each do |ontology|
          begin
            ontology_terms[ontology.ontologyId.to_i] = self.getOntologyMetrics(ontology.id).numberOfClasses.to_i
          rescue Exception => e
            LOG.add :info, "Problem getting metrics during term counting"
            LOG.add :info, e.inspect
            LOG.add :info, e.backtrace
          end
        end

        # Since we spawn a new process we need to make sure to reset the cache
        CACHE.reset

        CACHE.set("terms_all_ontologies", ontology_terms, LONG_CACHE_EXPIRE_TIME)
        CACHE.set("terms_all_ontologies_old", ontology_terms, EXTENDED_CACHE_EXPIRE_TIME)
        CACHE.set("running_term_calc", "false")

        # Since we spawn a new process we need to make sure to reset the cache
        CACHE.reset
      end
    end

    return Hash.new if terms.nil?
    return terms
  end

  def self.getNotesCounts
    ontologies = self.getOntologyList

    notes_counts = CACHE.get("notes_all_ontologies")
    running = CACHE.get("running_notes_count_calc")

    if (notes_counts.nil? || notes_counts.length == 0) && (running.nil? || !running.eql?("true"))
      CACHE.set("running_notes_count_calc", "true", 60*15)

      default_notes_counts =  CACHE.get("notes_all_ontologies_old").nil? ? Hash.new : CACHE.get("notes_all_ontologies_old")
      CACHE.set("notes_all_ontologies", default_notes_counts)
      notes_counts = default_notes_counts

      # Spawn a process to calculate total term size
      spawn(:argv => "spawn_notes_counts") do
        notes_counts = {}
        ontologies.each do |ontology|
          notes = self.getNotesForOntology(ontology.ontologyId)
          notes = [notes] if notes.kind_of?(Note)
          LOG.add :debug, "Note count for #{ontology.displayLabel}: #{notes.length}"
          notes_counts[ontology.ontologyId.to_i] = notes.length
        end

        # Since we spawn a new process we need to make sure to reset the cache
        CACHE.reset

        CACHE.set("notes_all_ontologies", notes_counts, LONG_CACHE_EXPIRE_TIME)
        CACHE.set("notes_all_ontologies_old", notes_counts, EXTENDED_CACHE_EXPIRE_TIME)
        CACHE.set("running_notes_count_calc", "false")

        # Since we spawn a new process we need to make sure to reset the cache
        CACHE.reset
      end
    end

    return Hash.new if notes_counts.nil?
    return notes_counts
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
    return self.getLatestOntology(ontology_id) if OntologyWrapper.virtual_id?(ontology_id)
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
        elsif index >= 4 # 21 most recent versions are checked (3 weeks)
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
    return self.cache_pull("#{concept_id}::notes", "getNotesForConcept", { :ontology_id => ontology_id, :concept_id => concept_id, :threaded => threaded, :virtual => virtual }, 60*15)
  end

  def self.getNotesForIndividual(ontology_virtual_id, individual_id, threaded = false)
    return self.cache_pull("#{individual_id}::notes", "getNotesForIndividual", { :ontology_virtual_id => ontology_virtual_id, :individual_id => individual_id, :threaded => threaded }, 60*15)
  end

  def self.getNotesForOntology(ontology_virtual_id, threaded = false)
    return self.cache_pull("#{ontology_virtual_id}::notes", "getNotesForOntology", { :ontology_virtual_id => ontology_virtual_id, :threaded => threaded }, 60*15)
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

    # We rescue all so the user doesn't get an error if the add fails
    begin
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
    rescue Exception => e
    end

    note
  end

  def self.archiveNote(params)
    note = SERVICE.archiveNote(params)
    CACHE.set("#{note.id}", note, CACHE_EXPIRE_TIME)
    CACHE.set("#{note.id}::threaded", note)
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

    note
  end

  def self.createRecommendation(text, ontology_ids)
    subs = self.cache_pull("recommendation::#{text.hash}::ontologies::#{ontology_ids}", "createRecommendation", { :text => text, :ontologyids => ontology_ids }, EXTENDED_CACHE_EXPIRE_TIME)
  end

  def self.getUserSubscriptions(user_id)
    subs = self.cache_pull("subscription::#{user_id}", "getUserSubscriptions", { :user_id => user_id }, LONG_CACHE_EXPIRE_TIME)
  end

  def self.createUserSubscriptions(user_id, ontology_ids, notification_type)
    subscriptions = SERVICE.createUserSubscriptions(:user_id => user_id, :ontology_ids => ontology_ids, :notification_type => notification_type)

    if subscriptions.nil?
      return nil
    else
      CACHE.delete("subscription::#{user_id}")
      return self.getUserSubscriptions(user_id)
    end
  end

  def self.deleteUserSubscriptions(user_id, ontology_ids, notification_type)
    subscriptions = SERVICE.deleteUserSubscriptions(:user_id => user_id, :ontology_ids => ontology_ids, :notification_type => notification_type)

    if subscriptions.nil?
      return nil
    else
      CACHE.delete("subscription::#{user_id}")
      return self.getUserSubscriptions(user_id)
    end
  end

  def self.createMapping(source, source_ontology_id, target, target_ontology_id, user_id, comment, unidirectional)
    mapping = SERVICE.createMapping({ :source => source, :sourceontology => source_ontology_id, :target => target, :targetontology => target_ontology_id, :submittedby => user_id, :comment => comment, :unidirectional => unidirectional })

    CACHE.delete("ontoliges::map_count")
    CACHE.delete("ontoliges::users::map_count")
    CACHE.delete("between_ontologies::map_count::#{source_ontology_id}")
    CACHE.delete("between_ontologies::map_count::#{target_ontology_id}")
    CACHE.delete("#{source_ontology_id}::#{CGI.escape(source)}::map_count")
    CACHE.delete("#{target_ontology_id}::#{CGI.escape(target)}::map_count")
    CACHE.delete("#{source_ontology_id}::map_count")
    CACHE.delete("#{target_ontology_id}::map_count")
    CACHE.delete("recent::mappings")
    CACHE.delete("#{source_ontology_id}::#{CGI.escape(source)}::map_page::page1::size100::params")
    CACHE.delete("#{target_ontology_id}::#{CGI.escape(target)}::map_page::page1::size100::params")
    CACHE.delete("#{source_ontology_id}::concepts::map_count")
    CACHE.delete("#{target_ontology_id}::concepts::map_count")

    return mapping
  end

  def self.getMapping(mapping_id)
    self.cache_pull("#{mapping_id}::mapping", "getMapping", { :mapping_id => mapping_id }, LONG_CACHE_EXPIRE_TIME)
  end

  def self.getConceptMappings(ontology_virtual_id, concept_id, page_number = 1, page_size = 100, params = {})
    self.cache_pull("#{ontology_virtual_id}::#{CGI.escape(concept_id)}::map_page::page#{page_number}::size#{page_size}::params#{params.to_s}", "getConceptMappings", { :ontology_virtual_id => ontology_virtual_id, :concept_id => concept_id, :page_number => page_number, :page_size => page_size }.merge(params), LONG_CACHE_EXPIRE_TIME)
  end

  def self.getOntologyMappings(ontology_virtual_id, page_number = 1, page_size = 100, params = {})
    self.cache_pull("#{ontology_virtual_id}::map_page::page#{page_number}::size#{page_size}::params#{params.to_s}", "getOntologyMappings", { :ontology_virtual_id => ontology_virtual_id, :page_number => page_number, :page_size => page_size }.merge(params), LONG_CACHE_EXPIRE_TIME)
  end

  def self.getBetweenOntologiesMappings(source_ontology_virtual_id, target_ontology_virtual_id, page_number = 1, page_size = 100, params = {})
    page_number ||= 1
    page_size ||= 100

  	# We avoid caching this result when it might be too big (> 5000 results)
  	if page_size > 5000
  	  SERVICE.getBetweenOntologiesMappings({ :source_ontology_virtual_id => source_ontology_virtual_id, :target_ontology_virtual_id => target_ontology_virtual_id, :page_number => page_number, :page_size => page_size }.merge(params))
  	else
      self.cache_pull("#{source_ontology_virtual_id}::#{target_ontology_virtual_id}::map_page::page#{page_number}::size#{page_size}::params#{params.to_s}", "getBetweenOntologiesMappings", { :source_ontology_virtual_id => source_ontology_virtual_id, :target_ontology_virtual_id => target_ontology_virtual_id, :page_number => page_number, :page_size => page_size }.merge(params), LONG_CACHE_EXPIRE_TIME)
	  end
  end

  def self.getMappingCountOntology(ontology_virtual_id)
    self.cache_pull("#{ontology_virtual_id}::map_count", "getMappingCountOntology", { :ontology_virtual_id => ontology_virtual_id }, LONG_CACHE_EXPIRE_TIME)
  end

  def self.getMappingCountConcept(ontology_virtual_id, concept_id)
    self.cache_pull("#{ontology_virtual_id}::#{CGI.escape(concept_id)}::map_count", "getMappingCountConcept", { :ontology_virtual_id => ontology_virtual_id, :concept_id => concept_id }, LONG_CACHE_EXPIRE_TIME)
  end

  def self.getMappingCountBetweenOntologies(ontology_virtual_id)
    self.cache_pull("between_ontologies::map_count::#{ontology_virtual_id}", "getMappingCountBetweenOntologies", { :ontology_virtual_id => ontology_virtual_id }, LONG_CACHE_EXPIRE_TIME)
  end

  def self.getMappingCountOntologies
    self.cache_pull("ontoliges::map_count", "getMappingCountOntologies", nil, LONG_CACHE_EXPIRE_TIME)
  end

  def self.getMappingCountOntologiesHash
    if CACHE.get("mapping_count_ontologies_hash").nil?
      mappings_counts = self.getMappingCountOntologies rescue Array.new
      mappings_counts_hash = {}
      mappings_counts.each do |map_count|
        mappings_counts_hash[map_count['ontologyId'].to_i] = map_count['totalMappings'].to_i
      end
      CACHE.set("mapping_count_ontologies_hash", mappings_counts_hash, MEDIUM_CACHE_EXPIRE_TIME)
    else
      mappings_counts_hash = CACHE.get("mapping_count_ontologies_hash")
    end
    mappings_counts_hash
  end

  def self.getMappingCountOntologyConcepts(ontology_virtual_id, limit = 35)
    self.cache_pull("#{ontology_virtual_id}::concepts::map_count", "getMappingCountOntologyConcepts", { :ontology_virtual_id => ontology_virtual_id, :limit => limit }, LONG_CACHE_EXPIRE_TIME)
  end

  def self.getMappingCountOntologyUsers(ontology_virtual_id, target_ontology_virtual_id = "")
    self.cache_pull("ontologies::users::map_count::ont_#{ontology_virtual_id}::target_#{target_ontology_virtual_id}", "getMappingCountOntologyUsers", { :ontology_virtual_id => ontology_virtual_id, :target_ontology_virtual_id => target_ontology_virtual_id }, LONG_CACHE_EXPIRE_TIME)
  end

  def self.getRecentMappings
    self.cache_pull("recent::mappings", "getRecentMappings", nil, 60*15)
  end

  def self.getNodeNameContains(ontologies, search, page, params = {})
    results,pages = SERVICE.getNodeNameContains(ontologies, search, page, params)
    return results,pages
  end

  def self.searchQuery(ontologies, query, page = 1, params = {})
    params_sym = {}
    params.each {|k,v| params_sym[k.to_sym] = v}
    SERVICE.searchQuery({ :ontologies => ontologies, :query => query, :page => page}.merge(params_sym) )
    # Technically we should probably cache this but the search service has been unreliable so it's disabled for now so we always get current data
    #return self.cache_pull("search::#{ontologies.join(",")}::page=#{page}::params=#{params.to_s}", "searchQuery", { :ontologies => ontologies, :query => query, :page => page}.merge(params), LONG_CACHE_EXPIRE_TIME)
  end

  def self.getUsers
    return self.cache_pull("user_list", "getUsers", nil, LONG_CACHE_EXPIRE_TIME)
  end

  def self.getUserByEmail(email)
    found_user = []
    users = self.getUsers
    for user in users
      if user.email.eql?(email)
        found_user << user
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
    CACHE.delete("ontology_acronyms")
    unless(params[:ontologyId].nil?)
      CACHE.delete("#{params[:ontologyId]}::_latest")
      CACHE.delete("#{params[:ontologyId]}::_versions")
      CACHE.delete("#{params[:ontologyId]}::_details")
      CACHE.delete("ont_list")
      CACHE.delete("ontology_acronyms")
    end
    return ontology
  end

  def self.updateOntology(params, ontology_id)
    SERVICE.updateOntology(params, ontology_id)
    CACHE.delete("#{ontology_id}::_details")
    CACHE.delete("ont_list")
    CACHE.delete("ontology_acronyms")
    unless(params[:ontologyId].nil?)
   	  CACHE.delete("#{params[:ontologyId]}::_latest")
      CACHE.delete("#{params[:ontologyId]}::_versions")
      CACHE.delete("#{params[:ontologyId]}::_details")
      CACHE.delete("ont_list")
      CACHE.delete("ontology_acronyms")
    end
    return self.getOntology(ontology_id)
  end

  def self.removeLatestOntologyFromCache(virtual_ontology_id)
    ontology = self.getLatestOntology(virtual_ontology_id)
    ontology_id = ontology.id

    CACHE.delete("#{ontology_id}::_details")
    CACHE.delete("#{virtual_ontology_id}::_latest")
    CACHE.delete("#{virtual_ontology_id}::_versions")
    CACHE.delete("#{virtual_ontology_id}::_details")
    CACHE.delete("ont_list")
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

      unless retrieved_object.kind_of?(Hash) && retrieved_object[:error] || retrieved_object.nil? || retrieved_object.to_s.length == 0
        # Don't cache nodes with more than the default number of max children
        if retrieved_object.class == NodeWrapper && retrieved_object.child_size.to_i > 10000
          return retrieved_object
        else
          CACHE.set(token, retrieved_object, expires)
        end
      end

      return retrieved_object
    else
      return CACHE.get(token)
    end
  end

end
