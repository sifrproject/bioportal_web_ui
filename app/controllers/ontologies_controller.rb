class OntologiesController < ApplicationController

  require "multi_json"
  require 'cgi'

  helper :concepts
  layout :resolve_layout

  before_action :authorize_and_redirect, :only=>[:edit,:update,:create,:new]

  KNOWN_PAGES = Set.new(["terms", "classes", "mappings", "notes", "widgets", "summary", "properties"])
  EXTERNAL_MAPPINGS_GRAPH = "http://data.bioontology.org/metadata/ExternalMappings"
  INTERPORTAL_MAPPINGS_GRAPH = "http://data.bioontology.org/metadata/InterportalMappings"

  # GET /ontologies
  # GET /ontologies.xml
  def index_old
    @ontologies = LinkedData::Client::Models::Ontology.all(include: LinkedData::Client::Models::Ontology.include_params)
    @submissions = LinkedData::Client::Models::OntologySubmission.all
    @submissions_map = Hash[@submissions.map {|sub| [sub.ontology.acronym, sub] }]
    @categories = LinkedData::Client::Models::Category.all
    @groups = LinkedData::Client::Models::Group.all

    # Count the number of classes in each ontology
    metrics_hash = get_metrics_hash
    @class_counts = {}
    @ontologies.each do |o|
      @class_counts[o.id] = metrics_hash[o.id].classes if metrics_hash[o.id]
      @class_counts[o.id] ||= 0
    end

    @mapping_counts = {}
    @note_counts = {}
    respond_to do |format|
      format.html # index.rhtml
    end
  end

  include ActionView::Helpers::NumberHelper
  include OntologiesHelper
  def index
    @app_name = "FacetedBrowsing"
    @app_dir = "/browse"
    @base_path = @app_dir
    ontologies = LinkedData::Client::Models::Ontology.all(include: LinkedData::Client::Models::Ontology.include_params + ",viewOf", include_views: true, display_context: false)
    ontologies_hash = Hash[ontologies.map {|o| [o.id, o] }]
    @admin = session[:user] ? session[:user].admin? : false
    @development = Rails.env.development?

    # We could get naturalLanguages, isOfType and formalityLevels from the API, but for performance we are storing it in config/bioportal_config_production.rb
    #json_metadata = JSON.parse(Net::HTTP.get(URI.parse("#{REST_URI}/submission_metadata?apikey=#{API_KEY}")))
    #@metadata = json_metadata

    # The attributes used when retrieving the submission. We are not retrieving all attributes to be faster
    browse_attributes = "ontology,acronym,submissionStatus,description,pullLocation,creationDate,released,name,naturalLanguage,hasOntologyLanguage,hasFormalityLevel,isOfType,contact"
    submissions = LinkedData::Client::Models::OntologySubmission.all(include_views: true, display_links: false, display_context: false, include: browse_attributes)
    submissions_map = Hash[submissions.map {|sub| [sub.ontology.acronym, sub] }]

    @categories = LinkedData::Client::Models::Category.all(display_links: false, display_context: false)
    @categories_hash = Hash[@categories.map {|c| [c.id, c] }]

    @groups = LinkedData::Client::Models::Group.all(display_links: false, display_context: false)
    @groups_hash = Hash[@groups.map {|g| [g.id, g] }]

    analytics = LinkedData::Client::Analytics.last_month
    @analytics = Hash[analytics.onts.map {|o| [o[:ont].to_s, o[:views]]}]

    reviews = {}
    LinkedData::Client::Models::Review.all(display_links: false, display_context: false).each do |r|
      reviews[r.reviewedOntology] ||= []
      reviews[r.reviewedOntology] << r
    end

    metrics_hash = get_metrics_hash

    @formats = Set.new

    @ontologies = []
    ontologies.each do |ont|
      o = {}

      if metrics_hash[ont.id]
        o[:class_count] = metrics_hash[ont.id].classes
        o[:individual_count] = metrics_hash[ont.id].individuals
      else
        o[:class_count] = 0
        o[:individual_count] = 0
      end
      o[:class_count_formatted] = number_with_delimiter(o[:class_count], :delimiter => ",")
      o[:individual_count_formatted] = number_with_delimiter(o[:individual_count], :delimiter => ",")

      o[:id]               = ont.id
      o[:type]             = ont.viewOf.nil? ? "ontology" : "ontology_view"
      o[:show]             = ont.viewOf.nil? ? true : false # show ontologies only by default
      o[:reviews]          = reviews[ont.id] || []
      o[:groups]           = ont.group || []
      o[:categories]       = ont.hasDomain || []
      o[:note_count]       = ont.notes.length
      o[:review_count]     = ont.reviews.length
      o[:project_count]    = ont.projects.length
      o[:private]          = ont.private?
      o[:popularity]       = @analytics[ont.acronym] || 0
      o[:submissionStatus] = []
      o[:administeredBy]   = ont.administeredBy
      o[:name]             = ont.name
      o[:acronym]          = ont.acronym
      o[:projects]         = ont.projects
      o[:notes]            = ont.notes

      o[:viewOfOnt] = {
        name: ontologies_hash[ont.viewOf].name,
        acronym: ontologies_hash[ont.viewOf].acronym
      } if o[:type].eql?("ontology_view")

      o[:artifacts] = []
      o[:artifacts] << "notes" if ont.notes.length > 0
      o[:artifacts] << "reviews" if ont.reviews.length > 0
      o[:artifacts] << "projects" if ont.projects.length > 0
      o[:artifacts] << "summary_only" if ont.summaryOnly

      sub = submissions_map[ont.acronym]
      if sub
        o[:submissionStatus]          = sub.submissionStatus
        o[:submission]                = true
        o[:pullLocation]              = sub.pullLocation
        o[:description]               = sub.description
        o[:creationDate]              = sub.creationDate
        o[:released]                  = sub.released
        o[:naturalLanguage]           = sub.naturalLanguage
        o[:hasFormalityLevel]         = sub.hasFormalityLevel
        o[:isOfType]                  = sub.isOfType
        o[:submissionStatusFormatted] = submission_status2string(sub).gsub(/\(|\)/, "")

        o[:format] = sub.hasOntologyLanguage
        @formats << sub.hasOntologyLanguage
      else
        # Used to sort ontologies without submissions to the end when sorting on upload date
        o[:creationDate] = DateTime.parse("19900601")
      end

      @ontologies << o
    end

    @ontologies.sort! {|a,b| b[:popularity] <=> a[:popularity]}

    render 'browse'
  end

  # GET /visualize/:ontology
  def classes
    # Hack to make ontologyid and conceptid work in addition to id and ontology params
    params[:id] = params[:id].nil? ? params[:ontologyid] : params[:id]
    params[:ontology] = params[:ontology].nil? ? params[:id] : params[:ontology]
    # Set the ontology we are viewing
    # Note: find_by_acronym includes ontology views
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology]).first
    # Get the latest 'ready' submission, or fallback to any latest submission
    @submission = get_ontology_submission_ready(@ontology)  # application_controller

    get_class(params)   # application_controller::get_class

    if request.accept.to_s.eql?("application/ld+json") || request.accept.to_s.eql?("application/json")
      headers['Content-Type'] = request.accept.to_s
      render text: @concept.to_jsonld
      return
    end

    # set the current PURL for this class
    @current_purl = @concept.purl if $PURL_ENABLED

    begin
      @mappings = @concept.explore.mappings
    rescue Exception => e
      msg = ''
      if @concept.instance_of?(LinkedData::Client::Models::Class) &&
          @ontology.instance_of?(LinkedData::Client::Models::Ontology)
        msg = "Failed to explore mappings for #{@concept.id} in #{@ontology.id}"
      end
      LOG.add :error, msg + "\n" + e.message
      @mappings = []
    end
    @delete_mapping_permission = check_delete_mapping_permission(@mappings)

    begin
      @notes = @concept.explore.notes
    rescue Exception => e
      msg = ''
      if @concept.instance_of?(LinkedData::Client::Models::Class) &&
          @ontology.instance_of?(LinkedData::Client::Models::Ontology)
        msg = "Failed to explore notes for #{@concept.id} in #{@ontology.id}"
      end
      LOG.add :error, msg + "\n" + e.message
      @notes = []
    end

    unless @concept.id.to_s.empty?
      # Update the tab with the current concept
      update_tab(@ontology,@concept.id)
    end
    if request.xhr?
      return render 'visualize', :layout => false
    else
      return render 'visualize', :layout => "ontology_viewer"
    end
  end

  def properties
    # Hack to make ontologyid and conceptid work in addition to id and ontology params
    params[:id] = params[:id].nil? ? params[:ontologyid] : params[:id]
    params[:ontology] = params[:ontology].nil? ? params[:id] : params[:ontology]
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology]).first
    if request.xhr?
      return render 'properties', :layout => false
    else
      return render 'properties', :layout => "ontology_viewer"
    end
  end

  def create
    if params['commit'] == 'Cancel'
      redirect_to "/ontologies"
      return
    end
    @ontology = LinkedData::Client::Models::Ontology.new(values: params[:ontology])
    @ontology_saved = @ontology.save
    if !@ontology_saved || @ontology_saved.errors
      @categories = LinkedData::Client::Models::Category.all
      @user_select_list = LinkedData::Client::Models::User.all.map {|u| [u.username, u.id]}
      @user_select_list.sort! {|a,b| a[1].downcase <=> b[1].downcase}
      @errors = response_errors(@ontology_saved)
      #@errors = {acronym: "Acronym already exists, please use another"} if @ontology_saved.status == 409
      render "new"
    else
      # TODO_REV: Enable subscriptions
      # if params["ontology"]["subscribe_notifications"].eql?("1")
      #  DataAccess.createUserSubscriptions(@ontology.administeredBy, @ontology.ontologyId, NOTIFICATION_TYPES[:all])
      # end
      if @ontology_saved.summaryOnly
        redirect_to "/ontologies/success/#{@ontology.acronym}"
      else
        redirect_to new_ontology_submission_url(ontology_id: @ontology.acronym)
      end
    end
  end

  def edit
    # Note: find_by_acronym includes ontology views
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:id]).first
    redirect_to_home unless session[:user] && @ontology.administeredBy.include?(session[:user].id) || session[:user].admin?
    @categories = LinkedData::Client::Models::Category.all
    @groups = LinkedData::Client::Models::Group.all
    @user_select_list = LinkedData::Client::Models::User.all.map {|u| [u.username, u.id]}
    @user_select_list.sort! {|a,b| a[1].downcase <=> b[1].downcase}
  end

  def mappings
    # Note: find_by_acronym includes ontology views
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:id]).first
    counts = LinkedData::Client::HTTP.get("#{LinkedData::Client.settings.rest_url}/mappings/statistics/ontologies/#{params[:id]}")
    @ontologies_mapping_count = []
    unless counts.nil?
      counts.members.each do |acronym|
        count = counts[acronym]
        # Note: find_by_acronym includes ontology views
        ontology = LinkedData::Client::Models::Ontology.find_by_acronym(acronym.to_s).first
        if ontology
          onto_info = {:id => ontology.id, :name => ontology.name, :viewOf => ontology.viewOf}
        else
          if acronym.to_s.start_with?(EXTERNAL_MAPPINGS_GRAPH)
            onto_info = {:id => acronym.to_s, :name => "External Mappings", :viewOf => nil}
            @ontologies_mapping_count << {'ontology' => onto_info, 'count' => count}
          elsif acronym.to_s.start_with?(INTERPORTAL_MAPPINGS_GRAPH)
            onto_info = {:id => acronym.to_s, :name => "Interportal Mappings - #{acronym.to_s.split("/")[-1].upcase}", :viewOf => nil}
            @ontologies_mapping_count << {'ontology' => onto_info, 'count' => count}
          end
        end
        next unless ontology
        @ontologies_mapping_count << {'ontology' => onto_info, 'count' => count}
      end
      @ontologies_mapping_count.sort! {|a,b| a['ontology'][:name].downcase <=> b['ontology'][:name].downcase } unless @ontologies_mapping_count.nil? || @ontologies_mapping_count.length == 0
    end
    @ontology_id = @ontology.acronym
    @ontology_label = @ontology.name
    if request.xhr?
      render :partial => 'mappings', :layout => false
    else
      render :partial => 'mappings', :layout => "ontology_viewer"
    end
  end

  def new
    if (params[:id].nil?)
      @ontology = LinkedData::Client::Models::Ontology.new(values: params[:ontology])
      @ontology.administeredBy = [session[:user].id]
    else
      # Note: find_by_acronym includes ontology views
      @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology]).first
    end
    @categories = LinkedData::Client::Models::Category.all
    @groups = LinkedData::Client::Models::Group.all
    @user_select_list = LinkedData::Client::Models::User.all.map {|u| [u.username, u.id]}
    @user_select_list.sort! {|a,b| a[1].downcase <=> b[1].downcase}
  end

  def notes
    # Note: find_by_acronym includes ontology views
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:id]).first
    # Get the latest 'ready' submission, or fallback to any latest submission
    @submission = get_ontology_submission_ready(@ontology)  # application_controller
    @notes = @ontology.explore.notes
    @notes_deletable = false
    # TODO_REV: Handle notes deletion
    # @notes.each {|n| @notes_deletable = true if n.deletable?(session[:user])} if @notes.kind_of?(Array)
    @note_link = "/ontologies/#{@ontology.acronym}/notes/"
    if request.xhr?
      render :partial => 'notes', :layout => false
    else
      render :partial => 'notes', :layout => "ontology_viewer"
    end
  end

  # GET /ontologies/ACRONYM
  # GET /ontologies/1.xml
  def show
    # Hack to make ontologyid and conceptid work in addition to id and ontology params
    params[:id] = params[:id].nil? ? params[:ontologyid] : params[:id]
    params[:ontology] = params[:ontology].nil? ? params[:id] : params[:ontology]

    # Hash to convert Lexvo URI to flag code
    $LEXVO_TO_FLAG = {"http://lexvo.org/id/iso639-3/aar" => "aa", "http://lexvo.org/id/iso639-3/abk" => "ab",
                      "http://lexvo.org/id/iso639-3/ave" => "ae", "http://lexvo.org/id/iso639-3/afr" => "af",
                      "http://lexvo.org/id/iso639-3/aka" => "ak", "http://lexvo.org/id/iso639-3/amh" => "am",
                      "http://lexvo.org/id/iso639-3/arg" => "an", "http://lexvo.org/id/iso639-3/ara" => "ar", "http://lexvo.org/id/iso639-3/asm" => "as", "http://lexvo.org/id/iso639-3/ava" => "av", "http://lexvo.org/id/iso639-3/aym" => "ay", "http://lexvo.org/id/iso639-3/aze" => "az", "http://lexvo.org/id/iso639-3/bak" => "ba", "http://lexvo.org/id/iso639-3/bel" => "be", "http://lexvo.org/id/iso639-3/bul" => "bg", "http://lexvo.org/id/iso639-3/bis" => "bi", "http://lexvo.org/id/iso639-3/bam" => "bm", "http://lexvo.org/id/iso639-3/ben" => "bn", "http://lexvo.org/id/iso639-3/bod" => "bo", "http://lexvo.org/id/iso639-3/bre" => "br", "http://lexvo.org/id/iso639-3/bos" => "bs", "http://lexvo.org/id/iso639-3/cat" => "ca", "http://lexvo.org/id/iso639-3/che" => "ce", "http://lexvo.org/id/iso639-3/cha" => "ch", "http://lexvo.org/id/iso639-3/cos" => "co", "http://lexvo.org/id/iso639-3/cre" => "cr", "http://lexvo.org/id/iso639-3/ces" => "cs", "http://lexvo.org/id/iso639-3/chu" => "cu", "http://lexvo.org/id/iso639-3/chv" => "cv", "http://lexvo.org/id/iso639-3/cym" => "cy", "http://lexvo.org/id/iso639-3/dan" => "da", "http://lexvo.org/id/iso639-3/deu" => "de", "http://lexvo.org/id/iso639-3/div" => "dv", "http://lexvo.org/id/iso639-3/dzo" => "dz", "http://lexvo.org/id/iso639-3/ewe" => "ee", "http://lexvo.org/id/iso639-3/ell" => "el", "http://lexvo.org/id/iso639-3/eng" => "en", "http://lexvo.org/id/iso639-3/epo" => "eo", "http://lexvo.org/id/iso639-3/spa" => "es", "http://lexvo.org/id/iso639-3/est" => "et", "http://lexvo.org/id/iso639-3/eus" => "eu", "http://lexvo.org/id/iso639-3/fas" => "fa", "http://lexvo.org/id/iso639-3/ful" => "ff", "http://lexvo.org/id/iso639-3/fin" => "fi", "http://lexvo.org/id/iso639-3/fij" => "fj", "http://lexvo.org/id/iso639-3/fao" => "fo", "http://lexvo.org/id/iso639-3/fra" => "fr", "http://lexvo.org/id/iso639-3/fry" => "fy", "http://lexvo.org/id/iso639-3/gle" => "ga", "http://lexvo.org/id/iso639-3/gla" => "gd", "http://lexvo.org/id/iso639-3/glg" => "gl", "http://lexvo.org/id/iso639-3/grn" => "gn", "http://lexvo.org/id/iso639-3/guj" => "gu", "http://lexvo.org/id/iso639-3/glv" => "gv", "http://lexvo.org/id/iso639-3/hau" => "ha", "http://lexvo.org/id/iso639-3/heb" => "he", "http://lexvo.org/id/iso639-3/hin" => "hi", "http://lexvo.org/id/iso639-3/hmo" => "ho", "http://lexvo.org/id/iso639-3/hrv" => "hr", "http://lexvo.org/id/iso639-3/hat" => "ht", "http://lexvo.org/id/iso639-3/hun" => "hu", "http://lexvo.org/id/iso639-3/hye" => "hy", "http://lexvo.org/id/iso639-3/her" => "hz", "http://lexvo.org/id/iso639-3/ina" => "ia", "http://lexvo.org/id/iso639-3/ind" => "id", "http://lexvo.org/id/iso639-3/ile" => "ie", "http://lexvo.org/id/iso639-3/ibo" => "ig", "http://lexvo.org/id/iso639-3/iii" => "ii", "http://lexvo.org/id/iso639-3/ipk" => "ik", "http://lexvo.org/id/iso639-3/ido" => "io", "http://lexvo.org/id/iso639-3/isl" => "is", "http://lexvo.org/id/iso639-3/ita" => "it", "http://lexvo.org/id/iso639-3/iku" => "iu", "http://lexvo.org/id/iso639-3/jpn" => "ja", "http://lexvo.org/id/iso639-3/jav" => "jv", "http://lexvo.org/id/iso639-3/kat" => "ka", "http://lexvo.org/id/iso639-3/kon" => "kg", "http://lexvo.org/id/iso639-3/kik" => "ki", "http://lexvo.org/id/iso639-3/kua" => "kj", "http://lexvo.org/id/iso639-3/kaz" => "kk", "http://lexvo.org/id/iso639-3/kal" => "kl", "http://lexvo.org/id/iso639-3/khm" => "km", "http://lexvo.org/id/iso639-3/kan" => "kn", "http://lexvo.org/id/iso639-3/kor" => "ko", "http://lexvo.org/id/iso639-3/kau" => "kr", "http://lexvo.org/id/iso639-3/kas" => "ks", "http://lexvo.org/id/iso639-3/kur" => "ku", "http://lexvo.org/id/iso639-3/kom" => "kv", "http://lexvo.org/id/iso639-3/cor" => "kw", "http://lexvo.org/id/iso639-3/kir" => "ky", "http://lexvo.org/id/iso639-3/lat" => "la", "http://lexvo.org/id/iso639-3/ltz" => "lb", "http://lexvo.org/id/iso639-3/lug" => "lg", "http://lexvo.org/id/iso639-3/lim" => "li", "http://lexvo.org/id/iso639-3/lin" => "ln", "http://lexvo.org/id/iso639-3/lao" => "lo", "http://lexvo.org/id/iso639-3/lit" => "lt", "http://lexvo.org/id/iso639-3/lub" => "lu", "http://lexvo.org/id/iso639-3/lav" => "lv", "http://lexvo.org/id/iso639-3/mlg" => "mg", "http://lexvo.org/id/iso639-3/mah" => "mh", "http://lexvo.org/id/iso639-3/mri" => "mi", "http://lexvo.org/id/iso639-3/mkd" => "mk", "http://lexvo.org/id/iso639-3/mal" => "ml", "http://lexvo.org/id/iso639-3/mon" => "mn", "http://lexvo.org/id/iso639-3/mar" => "mr", "http://lexvo.org/id/iso639-3/msa" => "ms", "http://lexvo.org/id/iso639-3/mlt" => "mt", "http://lexvo.org/id/iso639-3/mya" => "my", "http://lexvo.org/id/iso639-3/nau" => "na", "http://lexvo.org/id/iso639-3/nob" => "nb", "http://lexvo.org/id/iso639-3/nde" => "nd", "http://lexvo.org/id/iso639-3/nep" => "ne", "http://lexvo.org/id/iso639-3/ndo" => "ng", "http://lexvo.org/id/iso639-3/nld" => "nl", "http://lexvo.org/id/iso639-3/nno" => "nn", "http://lexvo.org/id/iso639-3/nor" => "no", "http://lexvo.org/id/iso639-3/nbl" => "nr", "http://lexvo.org/id/iso639-3/nav" => "nv", "http://lexvo.org/id/iso639-3/nya" => "ny", "http://lexvo.org/id/iso639-3/oci" => "oc", "http://lexvo.org/id/iso639-3/oji" => "oj", "http://lexvo.org/id/iso639-3/orm" => "om", "http://lexvo.org/id/iso639-3/ori" => "or", "http://lexvo.org/id/iso639-3/oss" => "os", "http://lexvo.org/id/iso639-3/pan" => "pa", "http://lexvo.org/id/iso639-3/pli" => "pi", "http://lexvo.org/id/iso639-3/pol" => "pl", "http://lexvo.org/id/iso639-3/pus" => "ps", "http://lexvo.org/id/iso639-3/por" => "pt", "http://lexvo.org/id/iso639-3/que" => "qu", "http://lexvo.org/id/iso639-3/roh" => "rm", "http://lexvo.org/id/iso639-3/run" => "rn", "http://lexvo.org/id/iso639-3/ron" => "ro", "http://lexvo.org/id/iso639-3/rus" => "ru", "http://lexvo.org/id/iso639-3/kin" => "rw", "http://lexvo.org/id/iso639-3/san" => "sa", "http://lexvo.org/id/iso639-3/srd" => "sc", "http://lexvo.org/id/iso639-3/snd" => "sd", "http://lexvo.org/id/iso639-3/sme" => "se", "http://lexvo.org/id/iso639-3/sag" => "sg", "http://lexvo.org/id/iso639-3/hbs" => "sh", "http://lexvo.org/id/iso639-3/sin" => "si", "http://lexvo.org/id/iso639-3/slk" => "sk", "http://lexvo.org/id/iso639-3/slv" => "sl", "http://lexvo.org/id/iso639-3/smo" => "sm", "http://lexvo.org/id/iso639-3/sna" => "sn", "http://lexvo.org/id/iso639-3/som" => "so", "http://lexvo.org/id/iso639-3/sqi" => "sq", "http://lexvo.org/id/iso639-3/srp" => "sr", "http://lexvo.org/id/iso639-3/ssw" => "ss", "http://lexvo.org/id/iso639-3/sot" => "st", "http://lexvo.org/id/iso639-3/sun" => "su", "http://lexvo.org/id/iso639-3/swe" => "sv", "http://lexvo.org/id/iso639-3/swa" => "sw", "http://lexvo.org/id/iso639-3/tam" => "ta", "http://lexvo.org/id/iso639-3/tel" => "te", "http://lexvo.org/id/iso639-3/tgk" => "tg", "http://lexvo.org/id/iso639-3/tha" => "th", "http://lexvo.org/id/iso639-3/tir" => "ti", "http://lexvo.org/id/iso639-3/tuk" => "tk", "http://lexvo.org/id/iso639-3/tgl" => "tl", "http://lexvo.org/id/iso639-3/tsn" => "tn", "http://lexvo.org/id/iso639-3/ton" => "to", "http://lexvo.org/id/iso639-3/tur" => "tr", "http://lexvo.org/id/iso639-3/tso" => "ts", "http://lexvo.org/id/iso639-3/tat" => "tt", "http://lexvo.org/id/iso639-3/twi" => "tw", "http://lexvo.org/id/iso639-3/tah" => "ty", "http://lexvo.org/id/iso639-3/uig" => "ug", "http://lexvo.org/id/iso639-3/ukr" => "uk", "http://lexvo.org/id/iso639-3/urd" => "ur", "http://lexvo.org/id/iso639-3/uzb" => "uz", "http://lexvo.org/id/iso639-3/ven" => "ve", "http://lexvo.org/id/iso639-3/vie" => "vi", "http://lexvo.org/id/iso639-3/vol" => "vo", "http://lexvo.org/id/iso639-3/wln" => "wa", "http://lexvo.org/id/iso639-3/wol" => "wo", "http://lexvo.org/id/iso639-3/xho" => "xh", "http://lexvo.org/id/iso639-3/yid" => "yi", "http://lexvo.org/id/iso639-3/yor" => "yo", "http://lexvo.org/id/iso639-3/zha" => "za", "http://lexvo.org/id/iso639-3/zho" => "zh", "http://lexvo.org/id/iso639-3/zul" => "zu"}

    # PURL-specific redirect to handle /ontologies/{ACR}/{CLASS_ID} paths
    if params[:purl_conceptid]
      params[:purl_conceptid] = "root" if params[:purl_conceptid].eql?("classes")
      if params[:conceptid]
        params.delete(:purl_conceptid)
      else
        params[:conceptid] = params.delete(:purl_conceptid)
      end
      redirect_to "/ontologies/#{params[:acronym]}?p=classes#{params_string_for_redirect(params, prefix: "&")}", :status => :moved_permanently
      return
    end

    if params[:ontology].to_i > 0
      acronym = BPIDResolver.id_to_acronym(params[:ontology])
      if acronym
        redirect_new_api
        return
      end
    end

    # Fix parameters to only use known pages
    params[:p] = nil unless KNOWN_PAGES.include?(params[:p])

    # This action is now a router using the 'p' parameter as the page to show
    case params[:p]
      when "terms"
        params[:p] = 'classes'
        redirect_to "/ontologies/#{params[:ontology]}#{params_string_for_redirect(params)}", :status => :moved_permanently
        return
      when "classes"
        self.classes #rescue self.summary
        return
      when "mappings"
        self.mappings #rescue self.summary
        return
      when "notes"
        self.notes #rescue self.summary
        return
      when "widgets"
        self.widgets #rescue self.summary
        return
      when "properties"
        self.properties #rescue self.summary
        return
      when "summary"
        self.summary
        return
      else
        self.summary
        return
    end
  end

  def submit_success
    @acronym = params[:id]
    # Force the list of ontologies to be fresh by adding a param with current time
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:id], cache_invalidate: Time.now.to_i).first
    render :partial => "submit_success", :layout => "ontology"
  end

  # Main ontology description page (with metadata): /ontologies/ACRONYM
  def summary
    # Note: find_by_acronym includes ontology views
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:id]).first
    not_found if @ontology.nil?
    # Check to see if user is requesting RDF+XML, return the file from REST service if so
    if request.accept.to_s.eql?("application/ld+json") || request.accept.to_s.eql?("application/json")
      headers['Content-Type'] = request.accept.to_s
      render text: @ontology.to_jsonld
      return
    end
    # Explore the ontology links
    @metrics = @ontology.explore.metrics rescue []
    @reviews = @ontology.explore.reviews.sort {|a,b| b.created <=> a.created} || []
    @projects = @ontology.explore.projects.sort {|a,b| a.name.downcase <=> b.name.downcase } || []
    @analytics = LinkedData::Client::HTTP.get(@ontology.links["analytics"])
    # retrieve submissions in descending submissionId order, should be reverse chronological order.
    # Only include metadata that we need for all other ontologies (faster)
    @submissions = @ontology.explore.submissions({include: "submissionId,creationDate,released,submissionStatus,hasOntologyLanguage,version"}).sort {|a,b| b.submissionId.to_i <=> a.submissionId.to_i } || []
    LOG.add :error, "No submissions for ontology: #{@ontology.id}" if @submissions.empty?
    # Get the latest submission, not necessarily the latest 'ready' submission
    @submission_latest = @ontology.explore.latest_submission rescue @ontology.explore.latest_submission(include: "")
    @views = @ontology.explore.views.sort {|a,b| a.acronym.downcase <=> b.acronym.downcase } || []
    if request.xhr?
      render :partial => 'metadata', :layout => false
    else
      render :partial => 'metadata', :layout => "ontology_viewer"
    end
  end

  def update
    if params['commit'] == 'Cancel'
      acronym = params['id']
      redirect_to "/ontologies/#{acronym}"
      return
    end
    # Note: find_by_acronym includes ontology views
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology][:acronym] || params[:id]).first
    @ontology.update_from_params(params[:ontology])
    error_response = @ontology.update
    if error_response
      @categories = LinkedData::Client::Models::Category.all
      @user_select_list = LinkedData::Client::Models::User.all.map {|u| [u.username, u.id]}
      @user_select_list.sort! {|a,b| a[1].downcase <=> b[1].downcase}
      @errors = response_errors(error_response)
      @errors = {acronym: "Acronym already exists, please use another"} if error_response.status == 409
    else
      # TODO_REV: Enable subscriptions
      # if params["ontology"]["subscribe_notifications"].eql?("1")
      #  DataAccess.createUserSubscriptions(@ontology.administeredBy, @ontology.ontologyId, NOTIFICATION_TYPES[:all])
      # end
      redirect_to "/ontologies/#{@ontology.acronym}"
    end
  end

  def virtual
    redirect_new_api
  end

  def visualize
    redirect_new_api(true)
  end

  def widgets
    # Note: find_by_acronym includes ontology views
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:id]).first
    if request.xhr?
      render :partial => 'widgets', :layout => false
    else
      render :partial => 'widgets', :layout => "ontology_viewer"
    end
  end

  private

  def resolve_layout
    case action_name
    when 'index'
      'angular'
    else
      'ontology'
    end
  end

end
