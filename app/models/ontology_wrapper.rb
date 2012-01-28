class OntologyWrapper

  attr_accessor :displayLabel
  attr_accessor :id
  attr_accessor :ontologyId
  attr_accessor :userId
  attr_accessor :parentId
  attr_accessor :format
  attr_accessor :versionNumber
  attr_accessor :versionStatus
  attr_accessor :internalVersion
  attr_accessor :versionStatus
  attr_accessor :isCurrent
  attr_accessor :isRemote
  attr_accessor :isReviewed
  attr_accessor :statusId
  attr_accessor :dateReleased
  attr_accessor :contactName
  attr_accessor :contactEmail
  attr_accessor :isFoundry
  attr_accessor :isManual
  attr_accessor :filePath
  attr_accessor :urn
  attr_accessor :homepage
  attr_accessor :documentation
  attr_accessor :publication
  attr_accessor :dateCreated
  attr_accessor :downloadLocation
  attr_accessor :isMetadataOnly
  attr_accessor :viewingRestriction

  attr_accessor :useracl
  # This data structure holds information about the users in the ACL, mainly whether or not they own the ontology
  attr_accessor :useracl_full

  attr_accessor :description
  attr_accessor :abbreviation
  attr_accessor :categories
  attr_accessor :groups

  attr_accessor :synonymSlot
  attr_accessor :preferredNameSlot
  attr_accessor :documentationSlot
  attr_accessor :authorSlot

  # RRF-specific metadata
  attr_accessor :targetTerminologies

  attr_accessor :reviews
  attr_accessor :projects
  attr_accessor :versions

  attr_accessor :view_ids
  attr_accessor :virtual_view_ids
  attr_accessor :view_beans
  attr_accessor :isView
  attr_accessor :viewDefinition
  attr_accessor :viewGenerationEngine
  attr_accessor :viewDefinitionLanguage
  attr_accessor :viewOnOntologyVersionId

  attr_accessor :licenseInformation

  attr_accessor :obsoleteParent
  attr_accessor :obsoleteProperty


  FILTERS = {
    "All"=>0,
    "OBO Foundry"=>1,
    "UMLS"=>2,
    "WHO" =>3,
    "HL7"=>4
  }

  STATUS = {
    "Waiting For Parsing"=>1,
    "Parsing"=>2,
    "Ready"=>3,
    "Error"=>4,
    "Not Applicable"=>5
  }

  FORMAT = ["OBO","OWL-DL","OWL-FULL","OWL-LITE","PROTEGE","LEXGRID-XML","RRF","LOINC","RXNORM","UMLS-RELA"]

  LEXGRID_FORMAT = ["OBO","LEXGRID-XML","RRF","LOINC","RXNORM","UMLS-RELA"]

  PROTEGE_FORMAT = ["OWL","OWL-DL","OWL-FULL","OWL-LITE","PROTEGE"]

  def initialize(hash = nil, params = nil)
    return if hash.nil?
    hash = hash["ontologyBean"] if hash["ontologyBean"]

    self.displayLabel             = hash['displayLabel']
    self.id                       = hash['id']
    self.ontologyId               = hash['ontologyId']
    self.userId                   = hash['userIds']
    self.parentId                 = hash['parentId']
    self.format                   = hash['format']
    self.versionNumber            = hash['versionNumber']
    self.versionStatus            = hash['versionStatus']
    self.internalVersion          = hash['internalVersionNumber']
    self.versionStatus            = hash['versionStatus']
    self.isCurrent                = hash['isCurrent']
    self.isRemote                 = hash['isRemote']
    self.isReviewed               = hash['isReviewed']
    self.statusId                 = hash['statusId']
    self.dateReleased             = Date.parse(hash['dateReleased']).strftime('%m/%d/%Y') unless hash['dateReleased'].nil?
    self.contactName              = hash['contactName']
    self.contactEmail             = hash['contactEmail']
    self.isFoundry                = hash['isFoundry']
    self.isManual                 = hash['isManual']
    self.filePath                 = hash['filePath']
    self.urn                      = hash['urn']
    self.homepage                 = hash['homepage']
    self.documentation            = hash['documentation']
    self.publication              = hash['publication']
    self.dateCreated              = Date.parse(hash['dateCreated']).strftime('%m/%d/%Y') unless hash['dateCreated'].nil?
    self.downloadLocation         = hash['downloadLocation']
    self.isMetadataOnly           = hash['isMetadataOnly']
    self.description              = hash['description']
    self.abbreviation             = hash['abbreviation']
    self.categories               = hash['categoryIds']
    self.groups                   = hash['groupIds']
    self.synonymSlot              = hash['synonymSlot']
    self.preferredNameSlot        = hash['preferredNameSlot']
    self.documentationSlot        = hash['documentationSlot']
    self.authorSlot               = hash['authorSlot']
    self.targetTerminologies      = hash['targetTerminologies']
    self.reviews                  = hash['reviews']
    self.projects                 = hash['projects']
    self.versions                 = hash['versions']
    self.view_ids                 = hash['hasViews']
    self.virtual_view_ids         = hash['virtualViewIds']
    self.isView                   = hash['isView']
    self.viewDefinition           = hash['viewDefinition']
    self.viewGenerationEngine     = hash['viewGenerationEngine']
    self.viewDefinitionLanguage   = hash['viewDefinitionLanguage']
    self.viewOnOntologyVersionId  = hash['viewOnOntologyVersionId']
    self.viewingRestriction       = hash['viewingRestriction']
    self.useracl_full             = hash['userAcl']
    self.licenseInformation       = hash['licenseInformation']
    self.obsoleteParent           = hash['obsoleteParent']
    self.obsoleteProperty         = hash['obsoleteProperty']

    self.useracl                  = []
    if !self.useracl_full.nil?
      self.useracl_full.each do |user|
        self.useracl << user["userId"]
      end
    end
  end

  def views
    return DataAccess.getViews(self.ontologyId)
  end

  def from_params(params)
    self.displayLabel = params[:displayLabel]
    self.id= params[:id]
    self.ontologyId= params[:ontologyId]
    self.userId= params[:userIds]
    self.parentId= params[:parentId]
    self.format= params[:format]
    self.versionNumber= params[:versionNumber]
    self.internalVersion= params[:internalVersion]
    self.versionStatus= params[:versionStatus]
    self.isCurrent= params[:isCurrent]
    self.isRemote= params[:isRemote]
    self.isReviewed= params[:isReviewed]
    self.statusId= params[:statusId]
    self.dateReleased= params[:dateReleased]
    self.contactName= params[:contactName]
    self.contactEmail= params[:contactEmail]
    self.isFoundry= params[:isFoundry]
    self.filePath= params[:filePath]
    self.urn= params[:urn]
    self.homepage= params[:homepage]
    self.documentation= params[:documentation]
    self.publication= params[:publication]
    self.isManual = params[:isManual]
    self.description= params[:description]
    self.categories = params[:categories]
    self.abbreviation = params[:abbreviation]
    self.synonymSlot = params[:synonymSlot]
    self.preferredNameSlot = params[:preferredNameSlot]
    self.versionStatus = params[:versionStatus]
    self.useracl = params[:useracl]

    self.licenseInformation = params[:licenseInformation]
    self.obsoleteParent = params[:obsoleteParent]
    self.obsoleteProperty = params[:obsoleteProperty]

    # view items
    self.isView = params[:isView]
    self.viewOnOntologyVersionId = params[:viewOnOntologyVersionId]
    self.viewDefinition = params[:viewDefinition]
    self.viewDefinitionLanguage = params[:viewDefinitionLanguage]
    self.viewGenerationEngine = params[:viewGenerationEngine]

  end

  def map_count
    count = DataAccess.getMappingCountOntology(self.ontologyId) rescue 0
  end

  def getOntologyFromView
    return DataAccess.getOntology(self.viewOnOntologyVersionId)
  end

  # For use with select lists, always includes the admin by default
  def useracl_select
    select_opts = []
    return select_opts if self.userId.nil? || self.userId.empty? and (self.useracl.nil? or self.useracl.empty?)

    if self.useracl.nil? || self.useracl.empty?
      self.userId.each do |userId|
        select_opts << [DataAccess.getUser(userId).username, userId]
      end
    else
      self.useracl.each do |user|
        select_opts << [DataAccess.getUser(user).username, user]
      end
    end

    select_opts
  end

  def preload_ontology
     self.reviews = load_reviews
     self.projects = load_projects
  end

  def load_reviews
    if CACHE.get("#{self.ontologyId}::ReviewCount").nil?
      count = Review.count(:conditions=>{:ontology_id=>self.ontologyId})
      CACHE.set("#{self.ontologyId}::ReviewCount",count)
      return count
    else
      return CACHE.get("#{self.ontologyId}::ReviewCount")
    end
  end

  def load_projects
    if CACHE.get("#{self.ontologyId}::ProjectCount").nil?
      count = Project.count(:conditions=>"uses.ontology_id = '#{self.ontologyId}'",:include=>:uses)
      CACHE.set("#{self.ontologyId}::ProjectCount",count)
      return count
    else
      return CACHE.get("#{self.ontologyId}::ProjectCount")
    end
  end

  def to_param
     "#{self.id}"
  end

  def topLevelNodes(view=false)
     DataAccess.getTopLevelNodes(self.id,view)
  end

  def metrics
    return DataAccess.getOntologyMetrics(self.id)
  end

  # Queries for the latest version of this ontology and returns a comparison.
  def latest?
    latest = DataAccess.getLatestOntology(self.ontologyId)
    return latest.id.eql? self.id
  end

  # Generates a PURL address for this ontology
  def purl
    return "#{$PURL_PREFIX}/#{self.abbreviation}"
  end

  def admin?(user)
    return !user.nil? && (user.admin? || self.userId.include?(user.id.to_i))
  end

  def archived?
    return self.statusId.to_i == 6
  end

  # Check to see if ontology is stored remotely (IE metadata only)
  def metadata_only?
    return self.isMetadataOnly.to_i == 1
  end

  # Check criteria for browsable ontologies
  def terms_disabled?
    return self.metadata_only? || (!$NOT_EXPLORABLE.nil? && $NOT_EXPLORABLE.include?(self.ontologyId.to_i))
  end

  # Is this ontology just a huge bag of terms?
  def flat?
    return !$NOT_EXPLORABLE.nil? && $NOT_EXPLORABLE.include?(self.ontologyId.to_i)
  end

  def viewing_restricted?
    !self.viewingRestriction.nil? && !self.viewingRestriction.empty?
  end

  def private?
    !self.viewingRestriction.nil? && self.viewingRestriction.downcase.eql?("private")
  end

  def licensed?
    !self.viewingRestriction.nil? && self.viewingRestriction.downcase.eql?("licensed")
  end

  def valid_tree_view?
    return self.statusId.to_i == 3 && !self.metadata_only?
  end

  def diffs
    DataAccess.getDiffs(self.ontologyId)
  end

  def versions_array
    DataAccess.getOntologyVersions(self.ontologyId).sort!{|x,y| y.internalVersion.to_i<=>x.internalVersion.to_i}
  end

  def is_in_search_index?
    begin
      result = DataAccess.searchQuery([self.ontologyId], "testingversionforontology")
      return result.ontology_hit_counts[self.ontologyId.to_i]["ontologyVersionId"] == self.id
    rescue
      false
    end
  end

  def lexgrid?
    LEXGRID_FORMAT.include?(self.format.upcase)
  end

  def protege?
    PROTEGE_FORMAT.include?(self.format.upcase)
  end

  def format_handler
    return :lexgrid if self.lexgrid?
    return :protege if self.protege?
    return :unknown
  end

  def synonym_label
    DataAccess.getLightNode(self.id, self.synonymSlot).label rescue ""
  end

  def preferred_name_label
    DataAccess.getLightNode(self.id, self.preferredNameSlot).label rescue ""
  end

  def definition_label
    DataAccess.getLightNode(self.id, self.documentationSlot).label rescue ""
  end

  def author_label
    DataAccess.getLightNode(self.id, self.authorSlot).label rescue ""
  end


  # Ontology Helper Methods
  def self.virtual_id?(ontology_id)
    ontology_id = ontology_id.to_i
    return ontology_id < $VIRTUAL_ID_UPPER_LIMIT && !$VERSIONS_IN_VIRTUAL_SPACE.include?(ontology_id)
  end

  def self.version_id?(ontology_id)
    ontology_id = ontology_id.to_i
    return ontology_id > $VIRTUAL_ID_UPPER_LIMIT || $VERSIONS_IN_VIRTUAL_SPACE.include?(ontology_id)
  end

end
