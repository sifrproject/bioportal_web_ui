require "date"
require "net/http"
require 'libxml'
require "rexml/document"
require 'open-uri'
require 'uri'
require 'cgi'
require 'BioPortalResources'

class BioPortalRestfulCore

  # Resources
  BASE_URL = $REST_URL

  # Search URL
  SEARCH_PATH = "/search/?query=%query%%ONT%"

  # Constants
  SUPERCLASS = "SuperClass"
  SUBCLASS = "SubClass"
  CHILDCOUNT = "ChildCount"
  API_KEY = $API_KEY

  # Track paths that have already been processed when building a path to root tree
  @seen_paths = {}


  def self.createMapping(params)
    # Default values
    params[:relation] = "http://www.w3.org/2004/02/skos/core#exactMatch"
    params[:type] = "Manual"
    params[:mappingsource] = "application"
    params[:mappingsourcename] = "BioPortal UI"
    params[:mappingsourcecontactinfo] = "support@bioontology.org"
    params[:mappingsourcesite] = "http://bioportal.bioontology.org"

    uri_gen = BioPortalResources::CreateMapping.new
    uri = uri_gen.generate_uri

    # uri = "http://localhost:8080/bioportal/virtual/mappings/concepts"

    begin
      mapping = postToRestlet(uri, params)
    rescue Exception => e
      LOG.add :debug, "Problem retrieving xml: #{e.message}"
      if !e.io.status.nil? && e.io.status[0].to_i == 404
        raise Error404
      end
      return nil
    end

    mapping = generic_parse(:xml => mapping, :type => "Mapping")

    return mapping
  end

  def self.deleteMapping(params)
    uri_gen = BioPortalResources::DeleteMapping.new
    uri = uri_gen.generate_uri

    LOG.add :debug, "Delete mapping"
    LOG.add :debug, uri
    doc = deleteToRestlet(uri, params)

    mapping = errorCheckLibXML(doc) unless doc.nil?

    return mapping
  end

  def self.getMapping(params)
    uri_gen = BioPortalResources::Mapping.new(params)
    uri = uri_gen.generate_uri

    LOG.add :debug, "Retrieve mapping"
    LOG.add :debug, uri

    doc = get_xml(uri) rescue nil

    if doc.nil?
      return Array.new
    end

    mappings = []
    timer = Benchmark.ms { mappings = generic_parse(:xml => doc, :type => "Mapping") }
    LOG.add :debug, "Mapping parsed (#{timer}ms)"

    return mappings
  end

  def self.getConceptMappings(params)
    params[:page_num] = (params[:page_num].nil?) ? 1 : params[:page_num]
    params[:page_size] = (params[:page_size].nil?) ? 10 : params[:page_size]

    uri_gen = BioPortalResources::ConceptMapping.new(params)
    uri = uri_gen.generate_uri

    LOG.add :debug, "Retrieve mappings for concept"
    LOG.add :debug, uri

    doc = get_xml(uri) rescue nil

    if doc.nil?
      return MappingPage.new
    end

    mappings = []
    timer = Benchmark.ms { mappings = generic_parse(:xml => doc, :type => "MappingPage") }
    LOG.add :debug, "Mapping parsed (#{timer}ms)"

    return mappings
  end

  def self.getOntologyMappings(params)
    params[:page_num] = (params[:page_num].nil?) ? 1 : params[:page_num]
    params[:page_size] = (params[:page_size].nil?) ? 10 : params[:page_size]

    uri_gen = BioPortalResources::OntologyMapping.new(params)
    uri = uri_gen.generate_uri

    LOG.add :debug, "Retrieve mappings for ontology"
    LOG.add :debug, uri

    doc = get_xml(uri) rescue nil

    if doc.nil?
      return Array.new
    end

    mappings = []
    timer = Benchmark.ms { mappings = generic_parse(:xml => doc, :type => "MappingPage") }
    LOG.add :debug, "Mappings for ontology parsed (#{timer}ms)"

    return mappings
  end

  def self.getBetweenOntologiesMappings(params)
    params[:page_num] = (params[:page_num].nil?) ? 1 : params[:page_num]
    params[:page_size] = (params[:page_size].nil?) ? 10 : params[:page_size]

    uri_gen = BioPortalResources::BetweenOntologiesMapping.new(params)
    uri = uri_gen.generate_uri

    LOG.add :debug, "Retrieve mappings between ontologies"
    LOG.add :debug, uri

    doc = get_xml(uri) rescue nil

    if doc.nil?
      return Array.new
    end

    mappings = []
    timer = Benchmark.ms { mappings = generic_parse(:xml => doc, :type => "MappingPage") }
    LOG.add :debug, "Mappings between ontologies parsed (#{timer}ms)"

    return mappings
  end

  def self.getRecentMappings
    uri_gen = BioPortalResources::RecentMappings.new
    uri = uri_gen.generate_uri

    LOG.add :debug, "Retrieve mappings counts between ontologies"
    LOG.add :debug, uri

    doc = get_xml(uri) rescue nil

    if doc.nil?
      return Array.new
    end

    mappings = []
    timer = Benchmark.ms { mappings = generic_parse(:xml => doc) }

    mappings = convert_to_one_to_one_mapping(mappings)
    mappings = (mappings.length > 5) ? mappings.shift(5) : mappings

    LOG.add :debug, "Between ontologies mapping counts parsed (#{timer}ms)"

    mappings = (mappings.kind_of? Array) ? mappings : Array.new

    return mappings
  end

  def self.getMappingCountBetweenOntologies(params)
    uri_gen = BioPortalResources::BetweenOntologiesMappingCount.new(params)
    uri = uri_gen.generate_uri

    LOG.add :debug, "Retrieve mappings counts between ontologies"
    LOG.add :debug, uri

    doc = get_xml(uri) rescue nil

    if doc.nil?
      return Array.new
    end

    mappings = []
    timer = Benchmark.ms { mappings = generic_parse(:xml => doc) }
    LOG.add :debug, "Between ontologies mapping counts parsed (#{timer}ms)"

    return mappings
  end

  def self.getMappingCountOntologyUsers(params)
    uri_gen = BioPortalResources::OntologyUserMappingCount.new(params)
    uri = uri_gen.generate_uri

    LOG.add :debug, "Retrieve user mapping counts for an ontology"
    LOG.add :debug, uri

    doc = get_xml(uri) rescue nil

    if doc.nil?
      return Array.new
    end

    mappings = []
    timer = Benchmark.ms { mappings = generic_parse(:xml => doc) }
    LOG.add :debug, "User mapping counts parsed (#{timer}ms)"

    return mappings
  end

  def self.getMappingCountOntologyConcepts(params)
    uri_gen = BioPortalResources::OntologyConceptMappingCount.new(params)
    uri = uri_gen.generate_uri

    LOG.add :debug, "Retrieve concepts mapping counts for an ontology"
    LOG.add :debug, uri

    doc = get_xml(uri) rescue nil

    if doc.nil?
      return Array.new
    end

    mappings = []
    timer = Benchmark.ms { mappings = generic_parse(:xml => doc) }
    LOG.add :debug, "Concept mapping counts parsed (#{timer}ms)"

    return mappings
  end

  def self.getMappingCountOntologies
    uri_gen = BioPortalResources::OntologiesMappingCount.new
    uri = uri_gen.generate_uri

    LOG.add :debug, "Retrieve mappings counts for all ontologies"
    LOG.add :debug, uri

    doc = get_xml(uri) rescue nil

    if doc.nil?
      return Array.new
    end

    mappings = []
    timer = Benchmark.ms { mappings = generic_parse(:xml => doc) }
    LOG.add :debug, "Ontologies mapping counts parsed (#{timer}ms)"

    return mappings
  end

  def self.getMappingCountOntology(params)
    params[:page_num] = 1
    params[:page_size] = 1

    uri_gen = BioPortalResources::OntologyMapping.new(params)
    uri = uri_gen.generate_uri

    LOG.add :debug, "Retrieve mapping count for ontology"
    LOG.add :debug, uri

    doc = get_xml(uri) rescue nil

    if doc.nil?
      return 0
    end

    mappings = 0
    timer = Benchmark.ms { mappings = generic_parse(:xml => doc, :type => "MappingPage") }
    LOG.add :debug, "Mapping parsed (#{timer}ms)"

    return (mappings.nil? || mappings.empty?) ? 0 : mappings.total_mappings
  end

  def self.getMappingCountConcept(params)
    params[:page_num] = 1
    params[:page_size] = 1

    uri_gen = BioPortalResources::ConceptMapping.new(params)
    uri = uri_gen.generate_uri

    LOG.add :debug, "Retrieve mapping count for concept"
    LOG.add :debug, uri

    doc = get_xml(uri) rescue nil

    if doc.nil?
      return 0
    end

    mappings = 0
    timer = Benchmark.ms { mappings = generic_parse(:xml => doc, :type => "MappingPage") }
    LOG.add :debug, "Mapping parsed (#{timer}ms)"

    return (mappings.nil? || mappings.empty?) ? 0 : mappings.total_mappings
  end

  def self.getView(params)
    uri_gen = BioPortalResources::View.new(params)
    uri = uri_gen.generate_uri

    doc = REXML::Document.new(get_xml(uri))

    view = nil
    doc.elements.each("*/data/ontologyBean"){ |element|
      view = parseOntology(element)
    }

    return view
  end

  def self.getViewList()
    uri_gen = BioPortalResources::Views.new
    uri = uri_gen.generate_uri

    doc = REXML::Document.new(get_xml(uri))

    ontologies = errorCheck(doc)

    unless ontologies.nil?
      return ontologies
    end

    ontologies = []
    doc.elements.each("*/data/list/ontologyBean"){ |element|
      ontologies << parseOntology(element)
    }

    return ontologies
  end

  def self.getViews(params)
    uri_gen = BioPortalResources::ViewVersions.new(params)
    uri = uri_gen.generate_uri

    doc = REXML::Document.new(get_xml(uri))

    views = []
    doc.elements.each("*/data/list/list"){ |element|
      virtual_view = []
      element.elements.each{ |version|
        virtual_view << parseOntology(version)
      }
        virtual_view.sort! { |a,b| a.internalVersion <=> b.internalVersion }
        virtual_view.reverse!
        views << virtual_view unless virtual_view.nil? || virtual_view.empty?
    }

    views.sort! {|a,b| a[0].displayLabel <=> b[0].displayLabel }

    return views
  end

  def self.getCategories()
    uri_gen = BioPortalResources::Categories.new
    uri = uri_gen.generate_uri

    doc = REXML::Document.new(get_xml(uri))

    categories = errorCheck(doc)

    unless categories.nil?
      return categories
    end

    categories = {}
    doc.elements.each("*/data/list/categoryBean"){ |element|
      category = parseCategory(element)
      categories[category[:id].to_s]=category
    }

    return categories
  end

  def self.getGroups
    uri_gen = BioPortalResources::Groups.new
    uri = uri_gen.generate_uri

    LOG.add :debug, "Retrieve groups"
    LOG.add :debug, uri
    doc = REXML::Document.new(get_xml(uri))

    groups = errorCheck(doc)
    unless groups.nil?
      return groups
    end

    groups = Groups.new
    groups.group_list = {}
    time = Time.now
    doc.elements.each("*/data/list/groupBean"){ |element|
      unless element.nil?
        group = parseGroup(element)
        groups.group_list[group[:id]] = group
      end
    }
    puts "getGroups Parse Time: #{Time.now - time}"

    return groups
  end

  ##
  # Gets a concept node.
  ##
  def self.getNode(params)
    uri_gen = BioPortalResources::Concept.new(params, params[:max_children])
    uri = uri_gen.generate_uri

    LOG.add :debug, "Retrieve node"
    LOG.add :debug, uri
    doc = get_xml(uri, 360)

    node = errorCheck(doc)

    if !node.nil? && node[:error] && node[:shortMessage].eql?("missing_xml")
      raise Error404
    end

    unless node.nil?
      return node
    end

    timer = Benchmark.ms { node = generic_parse(:xml => doc, :type => "NodeWrapper", :ontology_id => params[:ontology_id]) }
    LOG.add :debug, "Node parsed (#{timer}ms)"

    return node
  end

  ##
  # Gets a light version of a concept node. Used for tree browsing.
  ##
  def self.getLightNode(params)
    uri_gen = BioPortalResources::Concept.new(params, params[:max_children], true)
    uri = uri_gen.generate_uri

    LOG.add :debug, "Retrieve light node"
    LOG.add :debug, uri
    doc = get_xml(uri, 360)

    node = errorCheck(doc)

    unless node.nil?
      return node
    end

    timer = Benchmark.ms { node = generic_parse(:xml => doc, :type => "NodeWrapper", :ontology_id => params[:ontology_id]) }
    LOG.add :debug, "Light node parsed (#{timer}ms)"

    return node
  end

  # Super-fast method to get just the label for a node
  def self.getNodeLabel(params)
    uri_gen = BioPortalResources::Concept.new(params, 0, true)
    uri = uri_gen.generate_uri

    LOG.add :debug, "Retrieve node label"
    LOG.add :debug, uri
    doc = get_xml(uri, 360)

    node = errorCheck(doc)

    unless node.nil?
      return node
    end

    if doc.kind_of?(String)
      parser = XML::Parser.string(doc, :options => LibXML::XML::Parser::Options::NOBLANKS)
    else
      parser = XML::Parser.io(doc, :options => LibXML::XML::Parser::Options::NOBLANKS)
    end

    doc = parser.parse

    node = NodeLabel.new

    node.label = doc.find("/success/data/classBean/label").first.content
    node.obsolete = doc.find("/success/data/classBean/isObsolete").first.content rescue ""

    return node
  end

  def self.getTopLevelNodes(params)
    params[:concept_id] = "root"

    uri_gen = BioPortalResources::Concept.new(params, params[:max_children])
    uri = uri_gen.generate_uri

    LOG.add :debug, "Retrieve top level nodes"
    LOG.add :debug, uri
    doc = get_xml(uri)

    node = errorCheck(doc)

    unless node.nil?
      return node
    end

    timer = Benchmark.ms { node = generic_parse(:xml => doc, :type => "NodeWrapper", :ontology_id => params[:ontology_id]) }
    LOG.add :debug, "Top level nodes parsed (#{timer}ms)"

    return node.children
  end

  def self.getOntologyList(params = {})
    uri_gen = BioPortalResources::Ontologies.new
    uri = uri_gen.generate_uri

    doc = get_xml(uri)

    ontologies = errorCheck(doc)

    unless ontologies.nil?
      return ontologies
    end

    timer = Benchmark.ms { ontologies = generic_parse(:xml => doc, :type => "OntologyWrapper") }

    ontologies = Array.new if ontologies.nil? || !ontologies.kind_of?(Array)

    return ontologies
  end

  def self.getActiveOntologyList(params = {})
    uri_gen = BioPortalResources::ActiveOntologies.new
    uri = uri_gen.generate_uri

    doc = get_xml(uri)

    ontologies = errorCheck(doc)

    unless ontologies.nil?
      return ontologies
    end

    timer = Benchmark.ms { ontologies = generic_parse(:xml => doc, :type => "OntologyWrapper") }

    ontologies = Array.new if ontologies.nil? || !ontologies.kind_of?(Array)

    return ontologies
  end

  def self.getOntologyVersions(params)
    uri_gen = BioPortalResources::OntologyVersions.new(params)
    uri = uri_gen.generate_uri

    doc = get_xml(uri)

    ontologies = errorCheck(doc)

    unless ontologies.nil?
      return ontologies
    end

    timer = Benchmark.ms { ontologies = generic_parse(:xml => doc, :type => "OntologyWrapper") }

    return ontologies
  end

  def self.getOntology(params)
    uri_gen = BioPortalResources::Ontology.new(params)
    uri = uri_gen.generate_uri

    LOG.add :debug, "Retrieving ontology"
    LOG.add :debug, uri
    doc = get_xml(uri)

    ont = errorCheck(doc)

    unless ont.nil?
      return ont
    end

    timer = Benchmark.ms { ont = generic_parse(:xml => doc, :type => "OntologyWrapper") }

    return ont
  end

  def self.getLatestOntology(params)
    uri_gen = BioPortalResources::LatestOntology.new(params)
    uri = uri_gen.generate_uri

    doc = get_xml(uri)

    ont = errorCheck(doc)

    unless ont.nil?
      return ont
    end

    ont = generic_parse(:xml => doc, :type => "OntologyWrapper")

    return ont
  end

  def self.getOntologyProperties(params)
    uri_gen = BioPortalResources::OntologyProperties.new(params)
    uri = uri_gen.generate_uri

    doc = get_xml(uri)

    ont = errorCheck(doc)

    unless ont.nil?
      return ont
    end

    ont = generic_parse(:xml => doc, :type => "NodeWrapper")

    return ont
  end

  ##
  # Used to retrieve data from back-end REST service, then parse from the resulting metrics bean.
  # Returns an OntologyMetricsWrapper object.
  ##
  def self.getOntologyMetrics(params)
    uri_gen = BioPortalResources::OntologyMetrics.new(params)
    uri = uri_gen.generate_uri

    LOG.add :debug, "Retrieving ontology metrics"
    LOG.add :debug, uri
    doc = get_xml(uri)

    metrics = errorCheck(doc)

    unless metrics.nil?
      return metrics
    end

    timer = Benchmark.ms { metrics = generic_parse(:xml => doc, :type => "OntologyMetricsWrapper") }
    LOG.add :debug, "Parsed ontology metrics (#{timer}ms)"

    metrics
  end

  def self.getAllOntologyMetrics
    uri_gen = BioPortalResources::AllMetrics.new
    uri = uri_gen.generate_uri

    LOG.add :debug, "Retrieving all ontology metrics"
    LOG.add :debug, uri

    doc = get_xml(uri)

    metrics = errorCheck(doc)

    unless metrics.nil?
      return metrics
    end

    timer = Benchmark.ms { metrics = generic_parse(:xml => doc, :type => "OntologyMetricsWrapper") }
    LOG.add :debug, "Parsed all ontology metrics (#{timer}ms)"

    metrics = metrics.kind_of?(Array) ? metrics : nil

    metrics
  end

  ##
  # Get a path from a given concept to the root of the ontology.
  ##
  def self.getPathToRoot(params)
    uri_gen = BioPortalResources::PathToRoot.new(params)
    uri = uri_gen.generate_uri

    LOG.add :debug, "Retrieve path to root"
    LOG.add :debug, uri
    doc = get_xml(uri)

    root = errorCheck(doc)

    unless root.nil?
      return root
    end

    timer = Benchmark.ms { root = generic_parse(:xml => doc, :type => "NodeWrapper", :ontology_id => params[:ontology_id]) }
    LOG.add :debug, "getPathToRoot Parse Time: #{timer}ms"

    return root
  end

  def self.getNote(params)
    if params[:virtual] == true
      params[:ontology_virtual_id] = params[:ontology_id]
      uri_gen = BioPortalResources::NoteVirtual.new(params)
    else
      uri_gen = BioPortalResources::Note.new(params)
    end
    uri = uri_gen.generate_uri

    LOG.add :debug, "Retrieve note"
    LOG.add :debug, uri
    doc = get_xml(uri)

    note = errorCheck(doc)

    unless note.nil?
      return note
    end

    timer = Benchmark.ms { note = generic_parse(:xml => doc, :type => "Note") }
    LOG.add :debug, "note Parse Time: #{timer}ms"

    if note.kind_of?(Array) && note.size == 1
      note = note[0]
    end

    return note
  end

  def self.getNotesForConcept(params)
    if params[:virtual] == true
      params[:ontology_virtual_id] = params[:ontology_id]
      uri_gen = BioPortalResources::NotesForConceptVirtual.new(params)
    else
      uri_gen = BioPortalResources::NotesForConcept.new(params)
    end
    uri = uri_gen.generate_uri

    LOG.add :debug, "Retrieve notes for concept"
    LOG.add :debug, uri

    begin
      doc = get_xml(uri)
    rescue Exception => e
      puts e.message
    end

    notes = errorCheck(doc)

    unless notes.nil?
      return notes
    end

    timer = Benchmark.ms { notes = generic_parse(:xml => doc, :type => "Note") }
    LOG.add :debug, "note Parse Time: #{timer}ms"

    notes.sort! { |x,y| x.created <=> y.created }

    return notes
  end

  def self.getNotesForIndividual(params)

  end

  def self.getNotesForOntology(params)
    uri_gen = BioPortalResources::NotesForOntologyVirtual.new(params)
    uri = uri_gen.generate_uri

    LOG.add :debug, "Retrieve notes for ontology"
    LOG.add :debug, uri
    doc = get_xml(uri)

    notes = errorCheck(doc)

    unless notes.nil?
      return notes
    end

    begin
      timer = Benchmark.ms { notes = generic_parse(:xml => doc, :type => "Note") }
      LOG.add :debug, "notesForOntology Parse Time: #{timer}ms"
    rescue
      LOG.add :debug, "Error parsing notes"
    end

    begin
      notes.sort! { |x,y| x.created <=> y.created }
    rescue
      LOG.add :debug, "Error sorting notes"
    end

    return Array.new if !notes.kind_of?(Array)
    return notes
  end

  def self.createNote(params)
    # Convert param names to match Core
    params[:ontologyid] = params[:ontology_virtual_id]
    params[:content] = params[:body]
    params.each { |k,v| params[k.to_s.downcase.to_sym] = v }

    uri_gen = BioPortalResources::CreateNote.new(params)
    uri = uri_gen.generate_uri

    LOG.add :debug, "Create note"
    LOG.add :debug, uri
    doc = postToRestlet(uri, params)

    note = errorCheck(doc)

    unless note.nil?
      return doc
    end

    timer = Benchmark.ms { note = generic_parse(:xml => doc, :type => "Note") }
    LOG.add :debug, "createNote Parse Time: #{timer}ms"

    if note.kind_of?(Array) && note.size == 1
      note = note[0]
    end

    return note
  end

  def self.archiveNote(params)
    uri_gen = BioPortalResources::ArchiveNote.new(params)
    uri = uri_gen.generate_uri

    LOG.add :debug, "Archive note"
    LOG.add :debug, uri
    doc = putToRestlet(uri, params)

    note = errorCheck(doc)

    unless note.nil?
      return doc
    end

    return getNote({ :ontology_id => params[:ontology_virtual_id], :note_id => params[:noteid], :threaded => false, :virtual => true })
  end

  def self.getNodeNameContains(ontologies, search, page, params = {})
    ontologies = ontologies.nil? || ontologies.empty? ? "" : "&ontologyids=#{ontologies.join(",")}"
    search_branch = params[:subtreerootconceptid].nil? ? "" : "&subtreerootconceptid=#{params[:subtreerootconceptid]}"
    object_types = params[:objecttypes].nil? ? "" : "&objecttypes=#{params[:objecttypes]}"
    include_definitions = params[:includedefinitions].nil? || !params[:includedefinitions].eql?("true") ? "" : "&includedefinitions=true"

    LOG.add :debug, BASE_URL+SEARCH_PATH.gsub("%ONT%",ontologies).gsub("%query%",CGI.escape(search))+"&isexactmatch=0&pagesize=50&pagenum=#{page}&includeproperties=0&maxnumhits=15#{search_branch}#{object_types}#{include_definitions}"
    begin
      doc = REXML::Document.new(get_xml(BASE_URL + SEARCH_PATH.gsub("%ONT%",ontologies).gsub("%query%", CGI.escape(search)) + "&isexactmatch=0&pagesize=50&pagenum=#{page}&includeproperties=0&maxnumhits=15#{search_branch}#{object_types}#{include_definitions}"))
    rescue Exception=>e
      doc =  REXML::Document.new(e.io.read)
    end

    results = errorCheck(doc)

    unless results.nil?
      return results
    end

    results = []
    doc.elements.each("*/data/page/contents"){ |element|
      results = parseSearchResults(element)
    }

    pages = 1
    doc.elements.each("*/data/page"){|element|
      pages = element.elements["numPages"].get_text.value
    }

    return results,pages
  end

  def self.searchQuery(params)
    uri_gen = BioPortalResources::Search.new(params)
    uri = uri_gen.generate_uri

    LOG.add :debug, uri
    begin
      doc = get_xml(uri)
    rescue Exception=>e
      doc = e.io.read
    end

    results = errorCheck(doc)

    unless results.nil?
      return results
    end

    results = []
    timer = Benchmark.ms { results = generic_parse(:xml => doc, :type => "SearchResults") }
    LOG.add :debug, "SearchResults Parse Time: #{timer}ms"

    return results
  end

  def self.getUserSubscriptions(params)
    uri_gen = BioPortalResources::Subscriptions.new(params)
    uri = uri_gen.generate_uri

    LOG.add :debug, "Retrieve subscriptions for user"
    LOG.add :debug, uri
    doc = get_xml(uri)

    subscriptions = errorCheck(doc)

    unless subscriptions.nil?
      return subscriptions
    end

    timer = Benchmark.ms { subscriptions = generic_parse(:xml => doc) }

    return subscriptions
  end

  def self.createUserSubscriptions(params)
    params[:ontologyid] = params[:ontology_ids]
    params[:notificationtype] = params[:notification_type]

    uri_gen = BioPortalResources::Subscriptions.new(params)
    uri = uri_gen.generate_uri

    LOG.add :debug, "Create subscriptions for user"
    LOG.add :debug, uri
    doc = postToRestlet(uri, params)

    subscriptions = errorCheck(doc)

    unless subscriptions.nil?
      return subscriptions
    end

    timer = Benchmark.ms { subscriptions = generic_parse(:xml => doc) }

    return subscriptions
  end

  def self.deleteUserSubscriptions(params)
    params[:ontologyid] = params[:ontology_ids]
    params[:notificationtype] = params[:notification_type]

    uri_gen = BioPortalResources::Subscriptions.new(params)
    uri = uri_gen.generate_uri

    LOG.add :debug, "Delete subscriptions for user"
    LOG.add :debug, uri
    doc = deleteToRestlet(uri, params)

    subscriptions = errorCheck(doc)

    unless subscriptions.nil?
      return subscriptions
    end

    timer = Benchmark.ms { subscriptions = generic_parse(:xml => doc) }

    return subscriptions
  end

  def self.getUsers()
    uri_gen = BioPortalResources::Users.new
    uri = uri_gen.generate_uri

    LOG.add :debug, "Get all users"
    LOG.add :debug, uri
    doc = get_xml(uri)

    users = errorCheck(doc)

    unless users.nil?
      return users
    end

    timer = Benchmark.ms { users = generic_parse(:xml => doc, :type => "UserWrapper") }

    return users
  end

  def self.getUser(params)
    uri_gen = BioPortalResources::User.new(params)
    uri = uri_gen.generate_uri

    LOG.add :debug, "Get user"
    LOG.add :debug, uri
    doc = get_xml(uri)

    user = errorCheck(doc)

    unless user.nil?
      return user
    end

    timer = Benchmark.ms { user = generic_parse(:xml => doc, :type => "UserWrapper") }

    return user
  end

  def self.authenticateUser(username,password)
    uri_gen = BioPortalResources::Auth.new(:username => username, :password => password)
    uri = uri_gen.generate_uri

    LOG.add :debug, "Get user"
    LOG.add :debug, uri
    doc = get_xml(uri)

    user = errorCheck(doc)

    unless user.nil?
      return user
    end

    timer = Benchmark.ms { user = generic_parse(:xml => doc, :path => "/success/data/session/attributes/entry/securityContext", :type => "UserWrapper") }

    return user
  end

  def self.createUser(params)
    uri_gen = BioPortalResources::CreateUser.new
    uri = uri_gen.generate_uri

    begin
      doc = REXML::Document.new(postToRestlet(uri, params))
    rescue Exception=>e
      doc =  REXML::Document.new(e.io.read)
    end

    user = errorCheck(doc)

    unless user.nil?
      return user
    end

    doc.elements.each("*/data/session/attributes/entry/securityContext"){ |element|
      user = parseAuthenticatedUser(element)
    }

    return user
  end

  def self.updateUser(params,user_id)
    uri_gen = BioPortalResources::UpdateUser.new(:user_id => user_id)
    uri = uri_gen.generate_uri

    begin
      doc = REXML::Document.new(putToRestlet(uri, params))
    rescue Exception=>e
      doc = REXML::Document.new(e.io.read)
    end

    user = errorCheck(doc)

    unless user.nil?
      return user
    end

    doc.elements.each("*/data/session/attributes/entry/securityContext"){ |element|
      user = parseAuthenticatedUser(element)
    }

    return user
  end

  def self.createOntology(params)
    uri_gen = BioPortalResources::CreateOntology.new
    uri = uri_gen.generate_uri

    LOG.add :debug, "Creating ontology using #{uri}"

    begin
      doc = postMultiPart(uri, params)
    rescue Exception=>e
      doc = e.io.read
    end

    ontology = errorCheck(doc)

    unless ontology.nil?
      return ontology
    end

    ontology = generic_parse(:xml => doc, :type => "OntologyWrapper")

    return ontology
  end

  def self.updateOntology(params,version_id)
    uri_gen = BioPortalResources::UpdateOntology.new(:ontology_id => version_id)
    uri = uri_gen.generate_uri

    begin
      doc = putToRestlet(uri, params)
    rescue Exception=>e
      doc = e.io.read
    end

    ontology = errorCheck(doc)

    unless ontology.nil?
      return ontology
    end

    ontology = generic_parse(:xml => doc, :type => "OntologyWrapper")

    return ontology

  end

  def self.download(ontology_id)
    uri_gen = BioPortalResources::DownloadOntology.new(:ontology_id => ontology_id)
    return uri_gen.generate_uri
  end

  def self.getDiffs(ontology_id)
    uri_gen = BioPortalResources::Diffs.new(:ontology_id => ontology_id)
    uri = uri_gen.generate_uri

    begin
      doc = REXML::Document.new(get_xml(uri))
    rescue Exception=>e
      doc = REXML::Document.new(e.io.read) rescue nil
    end

    results = errorCheck(doc)

    unless results.nil?
      return results
    end

    pairs = []
    begin
      doc.elements.each("*/data/list") { |pair|
        pair.elements.each{|list|
          pair = []
          list.elements.each{|item|
            pair << item.get_text.value
          }
          pairs << pair
        }
      }
    rescue Exception => e
      LOG.add :debug, "Parsing diffs failed: #{e.message}"
    end
    return pairs
  end

  def self.diffDownload(ver1,ver2)
    uri_gen = BioPortalResources::DownloadDiffs.new( :ontology_version1 => ver1, :ontology_version2 => ver2 )
    return uri_gen.generate_uri
  end

  def self.createRecommendation(params)
    params[:format] = "asXML"

    uri_gen = BioPortalResources::Recommendation.new
    uri = uri_gen.generate_uri

    LOG.add :debug, "Retrieve recommendation"
    LOG.add :debug, uri
    doc = postToRestlet(uri, params)

    recommendation = errorCheck(doc)

    unless recommendation.nil?
      return recommendation
    end

    timer = Benchmark.ms { recommendation = generic_parse(:xml => doc) }

    return recommendation
  end

private

  # Converts a mapping from many-to-many to multiple one-to-one mappings
  def self.convert_to_one_to_one_mapping(mappings)
    one_to_one_mappings = []

    mappings.each do |mapping|
    if mapping['target'].size > 1 || mapping['source'].size > 1
        sources = mapping['source'].values
        targets = mapping['target'].values

        sources.each do |source|
          targets.each do |target|
            mapping['source'] = source
            mapping['target'] = target
            one_to_one_mappings << Mapping.new(mapping)
          end
        end
      else
        mapping['source'] = mapping['source']['fullId']
        mapping['target'] = mapping['target']['fullId']
        one_to_one_mappings << Mapping.new(mapping)
      end
    end

    one_to_one_mappings
  end

  # Gets XML from the rest service. Used to include a user-agent in one location.
  def self.get_xml(uri, timeout = 60)
    apikey = uri.include?("?") ? "&apikey=" + API_KEY  : "?apikey=" + API_KEY
    uri << apikey unless uri.include?("apikey=")

    request = Thread.current[:request]
    unless request.nil? || request.user_agent.nil?
      useragent = uri.include?("?") ? "&trackinguseragent=#{CGI.escape(request.user_agent)}" : "?trackinguseragent=#{CGI.escape(request.user_agent)}"
      uri << useragent
    end

    begin
      open(uri, "User-Agent" => "BioPortal-UI")
    rescue Exception => e
      LOG.add :debug, "Problem retrieving xml for #{uri}: #{e.message}"
      if !e.io.status.nil? && e.io.status[0].to_i == 404
        raise Error404
      end
      return nil
    end
  end

  def self.postMultiPart(url, paramsHash)
    paramsHash["apikey"] = API_KEY
    params=[]
    for param in paramsHash.keys
      if paramsHash["isRemote"].eql?("0") && param.eql?("filePath")
        params << file_to_multipart('filePath',paramsHash["filePath"].original_filename,paramsHash["filePath"].content_type,paramsHash["filePath"])
      else
        params << text_to_multipart(param, paramsHash[param])
      end
    end

    boundary = '349832898984244898448024464570528145'
    query = params.collect {|p| '--' + boundary + "\r\n" + p}.join('') + "--" + boundary + "--\r\n"

    uri = URI.parse(url)
    uri.port = $REST_PORT

    response = nil
    Net::HTTP.start(uri.host, uri.port) do |http|
      headers = {"Content-Type" => "multipart/form-data; boundary=" + boundary, "Accept-Charset" => "UTF-8"}
      response = http.send_request('POST', uri.request_uri, query, headers)
    end

    return response.body
  end

  def self.text_to_multipart(key, value)
    if value.class.to_s.downcase.eql?("array")
      return "Content-Disposition: form-data; name=\"#{CGI::escape(key)}\"\r\n" +
            "\r\n" +
            "#{value.join(",")}\r\n"
    else
      return "Content-Disposition: form-data; name=\"#{CGI::escape(key)}\"\r\n" +
            "\r\n" +
            "#{value}\r\n"
    end
  end

  def self.file_to_multipart(key, filename, mime_type,content)
    return "Content-Disposition: form-data; name=\"#{CGI::escape(key)}\"; filename=\"#{filename}\"\r\n" +
            "Content-Transfer-Encoding: base64\r\n" +
            "Content-Type: text/plain\r\n" +
            "\r\n" + content.read() + "\r\n"
  end

  def self.postToRestlet(url, paramsHash)
    paramsHash[:apikey] = API_KEY
    for param in paramsHash.keys
      if paramsHash[param].class.to_s.downcase.eql?("array")
        paramsHash[param] = paramsHash[param].join(",")
      end
    end
    res = Net::HTTP.post_form(URI.parse(url), paramsHash)
    return res.body
  end

  def self.putToRestlet(url, paramsHash)
    paramsHash[:apikey] = API_KEY
    paramsHash[:method] = "PUT"

    # Comma-separate lists
    for param in paramsHash.keys
      if paramsHash[param].class.to_s.downcase.eql?("array")
        paramsHash[param] = paramsHash[param].join(",")
      end
      paramsHash[param] = CGI.escape(paramsHash[param].to_s)
    end

    params = []
    paramsHash.each {|k,v| params << "#{k}=#{v}"}

    uri = URI.parse(url)
    uri.port = $REST_PORT

    response = nil
    Net::HTTP.start(uri.host, uri.port) do |http|
      headers = {'Content-Type' => 'application/x-www-form-urlencoded; charset=utf-8'}
      put_data = params.join("&")
      response = http.send_request('POST', uri.request_uri, put_data, headers)
    end

    return response.body
  end

  def self.deleteToRestlet(url, paramsHash)
    paramsHash[:apikey] = API_KEY
    paramsHash[:method] = "DELETE"

    # Comma-separate lists
    for param in paramsHash.keys
      if paramsHash[param].class.to_s.downcase.eql?("array")
        paramsHash[param] = paramsHash[param].join(",")
      end
    end

    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, $REST_PORT)
    response = Net::HTTP.post_form(uri, paramsHash)
    return response.body
  end

  def self.parseSearchResults(searchContents)

    searchResults = SearchResults.new
    searchResultList = searchContents.elements["searchResultList"]

    unless searchResultList.nil?
      searchResultList.elements.each("searchBean"){|searchBean|
        search_item = {}
        search_item[:ontologyDisplayLabel]=searchBean.elements["ontologyDisplayLabel"].get_text.value.strip
        search_item[:ontologyVersionId]=searchBean.elements["ontologyVersionId"].get_text.value.strip
        search_item[:ontologyId]=searchBean.elements["ontologyId"].get_text.value.strip
        search_item[:ontologyDisplayLabel]=searchBean.elements["ontologyDisplayLabel"].get_text.value.strip
        search_item[:recordType]=searchBean.elements["recordType"].get_text.value.strip
        search_item[:conceptId]=searchBean.elements["conceptId"].get_text.value.strip
        search_item[:conceptIdShort]=searchBean.elements["conceptIdShort"].get_text.value.strip
        search_item[:preferredName]=searchBean.elements["preferredName"].get_text.value.strip
        search_item[:contents]=searchBean.elements["contents"].get_text.value.strip
        search_item[:definition]=searchBean.elements["definition"].get_text.value.strip rescue ""
        searchResults<< search_item
      }
    end

    ontologyHitCounts = searchContents.elements["ontologyHitList"]

    unless ontologyHitCounts.nil?
      ontologyHitCounts.elements.each("ontologyHitBean") { |ontHits|
        hits = {}
        hits[:ontologyVersionId] = ontHits.elements["ontologyVersionId"].get_text.value.strip.to_i
        hits[:ontologyId] = ontHits.elements["ontologyId"].get_text.value.strip.to_i
        hits[:ontologyDisplayLabel] = ontHits.elements["ontologyDisplayLabel"].get_text.value.strip rescue ""
        hits[:numHits] = ontHits.elements["numHits"].get_text.value.strip.to_i
        searchResults.ontology_hit_counts[hits[:ontologyId]] = hits
      }
    end

    return searchResults
  end

  def self.parseCategory(categorybeanXML)
    category ={}
    category[:name]=categorybeanXML.elements["name"].get_text.value.strip rescue ""
    category[:id]=categorybeanXML.elements["id"].get_text.value.strip rescue ""
    category[:parentId]=categorybeanXML.elements["parentId"].get_text.value.strip rescue ""
    return category
  end

  def self.parseGroup(groupbeanXML)
    group = {}
    group[:id] = groupbeanXML.elements["id"].get_text.value.strip.to_i rescue ""
    group[:name] = groupbeanXML.elements["name"].get_text.value.strip rescue ""
    group[:acronym] = groupbeanXML.elements["acronym"].get_text.value.strip rescue ""

    return group
  end

  def self.parseUser(userbeanXML)
    user = UserWrapper.new

    user.id = userbeanXML.elements["id"].get_text.value.strip
    user.username = userbeanXML.elements["username"].get_text.value.strip
    user.email = userbeanXML.elements["email"].get_text.value.strip
    user.firstname = userbeanXML.elements["firstname"].get_text.value.strip rescue ""
    user.lastname = userbeanXML.elements["lastname"].get_text.value.strip rescue ""
    user.phone = userbeanXML.elements["phone"].get_text.value.strip rescue ""

    roles = []
    begin
      userbeanXML.elements["roles"].elements.each("string"){ |role|
        roles << role.get_text.value.strip
      }
    rescue Exception=>e
      LOG.add :debug, e.inspect
    end

    user.roles = roles

    return user
  end

  def self.parseAuthenticatedUser(user_security_xml)
    userbeanXML = user_security_xml.elements["userBean"]
    user = self.parseUser(userbeanXML)

    user.apikey = user_security_xml.elements["apiKey"].get_text.value.strip rescue ""

    return user
  end

  def self.parseOntology(ontologybeanXML)

    ontology = OntologyWrapper.new
    ontology.id = ontologybeanXML.elements["id"].get_text.value.strip
    ontology.displayLabel= ontologybeanXML.elements["displayLabel"].get_text.value.strip rescue "No Label"
    ontology.ontologyId = ontologybeanXML.elements["ontologyId"].get_text.value.strip
    ontology.parentId = ontologybeanXML.elements["parentId"].get_text.value.strip rescue ""
    ontology.format = ontologybeanXML.elements["format"].get_text.value.strip rescue  ""
    ontology.versionNumber = ontologybeanXML.elements["versionNumber"].get_text.value.strip rescue ""
    ontology.internalVersion = ontologybeanXML.elements["internalVersionNumber"].get_text.value.strip
    ontology.versionStatus = ontologybeanXML.elements["versionStatus"].get_text.value.strip rescue ""
    ontology.isCurrent = ontologybeanXML.elements["isCurrent"].get_text.value.strip rescue ""
    ontology.isRemote = ontologybeanXML.elements["isRemote"].get_text.value.strip rescue ""
    ontology.isReviewed = ontologybeanXML.elements["isReviewed"].get_text.value.strip rescue ""
    ontology.statusId = ontologybeanXML.elements["statusId"].get_text.value.strip rescue ""
    ontology.dateReleased =  Date.parse(ontologybeanXML.elements["dateReleased"].get_text.value).strftime('%m/%d/%Y') rescue ""
    ontology.contactName = ontologybeanXML.elements["contactName"].get_text.value.strip rescue ""
    ontology.contactEmail = ontologybeanXML.elements["contactEmail"].get_text.value.strip rescue ""
    ontology.urn = ontologybeanXML.elements["urn"].get_text.value.strip rescue ""
    ontology.isFoundry = ontologybeanXML.elements["isFoundry"].get_text.value.strip rescue ""
    ontology.isManual = ontologybeanXML.elements["isManual"].get_text.value.strip rescue ""
    ontology.filePath = ontologybeanXML.elements["filePath"].get_text.value.strip rescue ""
    ontology.homepage = ontologybeanXML.elements["homepage"].get_text.value.strip rescue ""
    ontology.documentation = ontologybeanXML.elements["documentation"].get_text.value.strip rescue ""
    ontology.publication = ontologybeanXML.elements["publication"].get_text.value.strip rescue ""
    ontology.dateCreated = Date.parse(ontologybeanXML.elements["dateCreated"].get_text.value).strftime('%m/%d/%Y') rescue ""
    ontology.preferredNameSlot = ontologybeanXML.elements["preferredNameSlot"].get_text.value.strip rescue ""
    ontology.documentationSlot = ontologybeanXML.elements["documentationSlot"].get_text.value.strip rescue ""
    ontology.authorSlot = ontologybeanXML.elements["authorSlot"].get_text.value.strip rescue ""
    ontology.synonymSlot = ontologybeanXML.elements["synonymSlot"].get_text.value.strip rescue ""
    ontology.description = ontologybeanXML.elements["description"].get_text.value.strip rescue ""
    ontology.abbreviation = ontologybeanXML.elements["abbreviation"].get_text.value.strip rescue ""
    ontology.targetTerminologies = ontologybeanXML.elements["targetTerminologies"].get_text.value.strip rescue ""
    ontology.isMetadataOnly = ontologybeanXML.elements["isMetadataOnly"].get_text.value.strip.to_i rescue ""
    ontology.downloadLocation = ontologybeanXML.elements["downloadLocation"].get_text.value.strip rescue ""
    ontology.versionStatus = ontologybeanXML.elements["versionStatus"].get_text.value.strip rescue ""

    ontology.userId = []
    unless ontologybeanXML.elements["userIds"].nil?
      ontologybeanXML.elements["userIds"].elements.each do |element|
        ontology.userId << element.get_text.value.strip rescue ""
      end
    end

    ontology.categories = []
    ontologybeanXML.elements["categoryIds"].elements.each do |element|
      ontology.categories << element.get_text.value.strip rescue ""
    end

    ontology.groups = []
    ontologybeanXML.elements["groupIds"].elements.each do |element|
      ontology.groups << element.get_text.value.strip.to_i rescue ""
    end

    # View-related parsing
    ontology.isView = ontologybeanXML.elements["isView"].get_text.value.strip rescue ""
    ontology.viewOnOntologyVersionId = ontologybeanXML.elements['viewOnOntologyVersionId'].elements['int'].get_text.value rescue ""
    ontology.viewDefinition = ontologybeanXML.elements["viewDefinition"].get_text.value.strip rescue ""
    ontology.viewGenerationEngine = ontologybeanXML.elements["viewGenerationEngine"].get_text.value.strip rescue ""
    ontology.viewDefinitionLanguage = ontologybeanXML.elements["viewDefinitionLanguage"].get_text.value.strip rescue ""

    ontology.view_ids = []
    ontology.virtual_view_ids=[]
    begin
      ontologybeanXML.elements["hasViews"].elements.each{|element|
        ontology.view_ids << element.get_text.value.strip rescue ""
      }
      ontologybeanXML.elements['virtualViewIds'].elements.each{|element|
        ontology.virtual_view_ids << element.get_text.value.strip rescue ""
      }
    rescue
    end

    return ontology
  end

  ##
  # Parses data from the ontology metrics bean XML, returns an OntologyMetricsWrapper object.
  ##
  def self.parseOntologyMetrics(ontologybeanXML)

    ontologyMetrics = OntologyMetricsWrapper.new
    ontologyMetrics.id = ontologybeanXML.elements["id"].get_text.value.strip rescue ""
    ontologyMetrics.ontologyId = ontologybeanXML.elements["ontologyId"].get_text.value.strip rescue ""
    ontologyMetrics.numberOfAxioms = ontologybeanXML.elements["numberOfAxioms"].get_text.value.strip.to_i rescue ""
    ontologyMetrics.numberOfClasses = ontologybeanXML.elements["numberOfClasses"].get_text.value.strip.to_i rescue ""
    ontologyMetrics.numberOfIndividuals = ontologybeanXML.elements["numberOfIndividuals"].get_text.value.strip.to_i rescue ""
    ontologyMetrics.numberOfProperties = ontologybeanXML.elements["numberOfProperties"].get_text.value.strip.to_i rescue ""
    ontologyMetrics.maximumDepth = ontologybeanXML.elements["maximumDepth"].get_text.value.strip.to_i rescue ""
    ontologyMetrics.maximumNumberOfSiblings = ontologybeanXML.elements["maximumNumberOfSiblings"].get_text.value.strip.to_i rescue ""
    ontologyMetrics.averageNumberOfSiblings = ontologybeanXML.elements["averageNumberOfSiblings"].get_text.value.strip.to_i rescue ""

    begin
      ontologybeanXML.elements["classesWithOneSubclass"].elements.each { |element|
        ontologyMetrics.classesWithOneSubclass << element.get_text.value.strip rescue ""
        unless defined? first
          ontologyMetrics.classesWithOneSubclassAll = element.get_text.value.strip.eql?("alltriggered")
          ontologyMetrics.classesWithOneSubclassLimitPassed = element.get_text.value.strip.include?("limitpassed") ? element.get_text.value.strip.split(":")[1].to_i : false
          first = false
        end
      }

      ontologybeanXML.elements["classesWithMoreThanXSubclasses"].elements.each { |element|
        class_name = element.elements['string[1]'].get_text.value rescue ""
        class_count = element.elements['string[2]'].get_text.value.to_i rescue ""
        ontologyMetrics.classesWithMoreThanXSubclasses[class_name] = class_count
        unless defined? first
          ontologyMetrics.classesWithMoreThanXSubclassesAll = element.elements['string[1]'].get_text.value.strip.eql?("alltriggered")
          ontologyMetrics.classesWithMoreThanXSubclassesLimitPassed = element.elements['string[1]'].get_text.value.strip.include?("limitpassed") ? element.elements['string[2]'].get_text.value.strip.to_i : false
          first = false
        end
      }

      ontologybeanXML.elements["classesWithNoDocumentation"].elements.each { |element|
        ontologyMetrics.classesWithNoDocumentation << element.get_text.value.strip rescue ""
        unless defined? first
          ontologyMetrics.classesWithNoDocumentationAll = element.get_text.value.strip.eql?("alltriggered")
          ontologyMetrics.classesWithNoDocumentationLimitPassed = element.get_text.value.strip.include?("limitpassed") ?
              element.get_text.value.strip.split(":")[1].to_i : false
          first = false
        end
      }

      ontologybeanXML.elements["classesWithNoAuthor"].elements.each { |element|
        ontologyMetrics.classesWithNoAuthor << element.get_text.value.strip rescue ""
        unless defined? first
          ontologyMetrics.classesWithNoAuthorAll = element.get_text.value.strip.eql?("alltriggered")
          ontologyMetrics.classesWithNoAuthorLimitPassed = element.get_text.value.strip.include?("limitpassed") ? element.get_text.value.strip.split(":")[1].to_i : false
          first = false
        end
      }

      ontologybeanXML.elements["classesWithMoreThanOnePropertyValue"].elements.each { |element|
        ontologyMetrics.classesWithMoreThanOnePropertyValue << element.get_text.value.strip rescue ""
        unless defined? first
          ontologyMetrics.classesWithMoreThanOnePropertyValueAll = element.get_text.value.strip.eql?("alltriggered")
          ontologyMetrics.classesWithMoreThanOnePropertyValueLimitPassed = element.get_text.value.strip.include?("limitpassed") ? element.get_text.value.strip.split(":")[1].to_i : false
          first = false
        end
      }

      # Stop exception checking
    rescue Exception=>e
      LOG.add :debug, e.inspect
    end

    return ontologyMetrics
  end

  def self.errorCheck(doc)
    response = nil
    errorHolder = {}

    begin
      doc.elements.each("errorStatus"){ |element|
        errorHolder[:error] = true
        errorHolder[:shortMessage] = element.elements["shortMessage"].get_text.value.strip
        errorHolder[:longMessage] = element.elements["longMessage"].get_text.value.strip
        response = errorHolder
      }
    rescue
    end

    return response
  end

  def self.errorCheckLibXML(doc)
    self.generic_parse(:xml => doc, :path => "/errorStatus")
  end

  def self.buildPathToRootTree(classbeanXML, ontology)

    node = getConceptBasicInfo(classbeanXML, ontology)

    # look for child nodes and process if found
    search = classbeanXML.path + "/relations/entry[string='SubClass']/list/classBean"
    results = classbeanXML.first.find(search)
    unless results.empty?
      results.each do |child|
        # If we're about to process a path we've seen, don't continue.
        if @seen_paths[child.path]
          next
        end
        @seen_paths[child.path] = 1
        node.children << buildPathToRootTree(child,ontology)
        node.children.sort! { |a,b| a.name.downcase <=> b.name.downcase }
      end
    end

    return node
  end

  def self.getConceptBasicInfo(classbeanXML, ontology)
    # build a node object
    node = NodeWrapper.new
    # set default child size
    node.child_size=0
    # get node.id
    id = classbeanXML.first.find(classbeanXML.path + "/id")
    node.id = id.first.content unless id.first.nil?
    # get fullId
    fullId = classbeanXML.first.find(classbeanXML.path + "/fullId")
    node.fullId = fullId.first.content unless fullId.first.nil?
    # get label
    label = classbeanXML.first.find(classbeanXML.path + "/label")
    node.name = label.first.content unless label.first.nil?
    # get type
    type = classbeanXML.first.find(classbeanXML.path + "/type")
    node.type = type.first.content unless type.first.nil?
    # get childcount info
    childcount = classbeanXML.first.find(classbeanXML.path + "/relations/entry[string='ChildCount']/int")
    node.child_size = childcount.first.content.to_i unless childcount.first.nil?
    # get isBrowsable info
    # Replaced in the short term with a method in the model
    #node.is_browsable = node.type.downcase.eql?("class") rescue ""
    # get synonyms
    synonyms = classbeanXML.first.find(classbeanXML.path + "/synonyms/string")
    node.synonyms = []
    synonyms.each do |synonym|
      node.synonyms << synonym.content
    end
    # get definitions
    definitions = classbeanXML.first.find(classbeanXML.path + "/definitions/string")
    node.definitions = []
    definitions.each do |definition|
      node.definitions << definition.content
    end


    node.version_id = ontology
    node.children = []
    node.properties = {}

    return node
  end

  ###################### Generic Parser #########################
  ## The following methods are part of a generic parser, which
  ## promises a simpler, faster parsing implementation. For now
  ## these methods are contained here, but future plans would
  ## bring the parser into the models, making it so that data
  ## is defined and dealt with in one location.
  ##
  ## Right now a hash is produced that matches the provided REST XML.
  ## When calling generic_parse you can provide the model type
  ## (NodeWrapper, OntologyWrapper, etc) and then overwrite the
  ## model's intialize method to convert the hash into a proper object.
  ## For an example, see the NodeWrapper model and getPathToRoot method.
  ##
  ## Parameters
  ## :type => object type
  ## :xml => IO object containing XML data
  ## Additional parameters can be added and will be passed to the model initializer
  ##
  ## Usage
  ## generic_parse(:xml => xml, :type => "OntologyWrapper", :ontology_id => ontology_id
  ####
  def self.generic_parse(params)
    type = params[:type] rescue nil
    xml = params[:xml]
    path = params[:path]

    if xml.nil?
      return nil
    end

    doc = self.parse_xml(xml)

    if path.nil?
      root = doc.find_first("/success/data")
    else
      root = doc.find_first(path)
    end

    # Check to see if we have any data, if not return an empty hash
    return Hash.new if root.nil? || root.first.nil? || !root.first.element?

    parsed = self.parse(root)

    # We end up with an extra hash at the root, this should get rid of that
    attributes = ActiveSupport::OrderedHash.new
    if parsed.key?("data")
      parsed.each do |k,v|
        if v.is_a?(Hash)
          attributes = {}
          v.each{ |k,v| attributes[k] = v }
        elsif v.is_a?(Array)
          attributes = v
        end
      end
    else
      attributes = parsed
    end

    if type
      if attributes.is_a?(Array)
        list = []
        attributes.each do |hash|
          list << Kernel.const_get(type).new(hash, params)
        end
        return list
      else
        return Kernel.const_get(type).new(attributes, params)
      end
    else
      return attributes
    end
  end

  def self.parse_xml(xml)
    if xml.kind_of?(String)
      parser = XML::Parser.string(xml, :options => LibXML::XML::Parser::Options::NOBLANKS)
    else
      parser = XML::Parser.io(xml, :options => LibXML::XML::Parser::Options::NOBLANKS)
    end

    parser.parse
  end

  def self.parse(node)
    a = ActiveSupport::OrderedHash.new

    attr_suffix = 1

    node.each_element do |child|
      case child.name
        when "entry"
          a[child.first.content] = process_entry(child)
        when "list"
          a[node.name] = process_list(child)
        when "int"
          return child.content.to_i
        when "string"
          return child.content
        when "synonyms", "categoryIds", "groupIds", "hasViews", "virtualViewIds"
          elements = []
          child.each_element { |element| elements << element.content }
          a[child.name] = elements
        when "associated", "userAcl", "roles", "classesWithNoDocumentation", "classesWithOneSubclass","classesWithNoAuthor",
             "userIds"
          a[child.name] = process_list(child)
      else
        if !child.first.nil? && child.first.element?
          # Make sure that duplicate key names are handled properly
          if a.has_key?(child.name)
            name = child.name + attr_suffix.to_s
            attr_suffix += 1
          else
            name = child.name
          end

          a[name] = parse(child)
        else
          # Make sure that duplicate key names are handled properly
          if a.has_key?(child.name)
            name = child.name + attr_suffix.to_s
            attr_suffix += 1
          else
            name = child.name
          end

          a[name] = child.content
        end
      end
    end
    a
  end

  # Entries are generally key/value pairs, sometimes the value is a list
  def self.process_entry(entry)
    children = []
    entry.each_element{|c| children << c}

    entry_key = children[0].content
    entry_values = children[1]
    entry_hash = ActiveSupport::OrderedHash.new

    # Check to see if entry contains data as a list or single
    if entry_values.name.eql?("list") && !entry_values.empty?
      values = process_list(entry_values)
      entry_hash[entry_key] = values
    else
      entry_hash[entry_key] = entry_values.content
    end
  end

  # Processes a list of items, returns an array of values
  def self.process_list(list)
    return if list.children.empty?
    list_type = list.first.name
    values = []

    if list_type.eql?("int")
      list.each{ |entry| values << entry.content.to_i }
    elsif list_type.eql?("string")
      list.each{ |entry| values << entry.content.to_s }
    elsif !list.first.nil? && list.first.element?
      list.each{ |entry| values << parse(entry) }
    else
      list.each{ |entry| values << entry.content }
    end
    values
  end


end
