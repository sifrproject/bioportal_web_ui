class HomeController < ApplicationController
  require "OntrezService"


  layout 'ontology'

  def index
    @ontologies = DataAccess.getOntologyList() # -- Gets list of ontologies
    @groups = DataAccess.getGroups()

    active_onts_by_notes_query = "select ontology_id,count(ontology_id) as note_count from notes_indices as note group by ontology_id order by note_count desc"
    @active_totals = ActiveRecord::Base.connection.select_rows(active_onts_by_notes_query);

    active_onts_by_maps_query = "select source_ont,count(source_ont) as map_count from mappings group by source_ont order by map_count desc"
    active_maps = ActiveRecord::Base.connection.select_rows(active_onts_by_maps_query);

    for total in @active_totals
      total[3]=0
      total[2]=0
      if total[0].nil?
        next
      end
      for map in active_maps
        if map[0].to_i.eql?(total[0].to_i)
          total[2]=map[1].to_i
          total[3]=map[1].to_i+total[1].to_i
          active_maps.delete(map)
        end
      end
    end

    # ontologies with mappings but no notes
    for map in active_maps
      map[2]= map[1].to_i
      map[3]= map[1].to_i
      map[1]=0
      @active_totals << map
    end

    # ontologies with notes but no mappings
    for total in @active_totals
      if total[3].nil? || total[3].eql?(0)
        total[2]=0
        total[3]=total[1]
      end
    end

    # Show only notes from custom ontology set
    user_ontologies = session[:user_ontologies] ? session[:user_ontologies][:virtual_ids].to_a : []
    conditions = user_ontologies.empty? ? [] : ["ontology_id in (?)", user_ontologies]

    # Hide notes from private ontologies
    restricted_ontologies = DataAccess.getRestrictedOntologyList
    restricted_for_query = []
    restricted_ontologies.each do |ont|
      restricted_for_query << ont.ontologyId.to_i unless session[:user] && session[:user].has_access?(ont)
    end

    # Get a list of all ontology ids
    all_ontology_ids = []
    @ontologies.each do |ont|
      all_ontology_ids << ont.ontologyId.to_i
    end

    # Subtract the restricted onts from the non-restricted list
    okay_ontologies = all_ontology_ids - restricted_for_query

    restricted_condition = "ontology_id in (?)"
    if conditions.empty?
      conditions = [restricted_condition, okay_ontologies]
    else
      conditions[0] << " AND " + restricted_condition
      conditions.push(okay_ontologies)
    end

    @active_totals = @active_totals.sort{|x,y| y[3].to_i<=>x[3].to_i}
    @active_totals = @active_totals[0,5]

    @categories = DataAccess.getCategories()
    @last_notes = NotesIndex.find(:all, :order => 'created desc', :limit => 5, :conditions => conditions)
    @last_mappings = DataAccess.getRecentMappings

    #build hash for quick grabbing
    @ontology_hash = {}
    for ont in @ontologies
      @ontology_hash[ont.ontologyId]=ont
    end

    @sorted_ontologies={}
    @sorted_ontologies["0"]=[]

    for cat in @categories.keys
      @sorted_ontologies[cat]=[]
    end

    for ontology in @ontologies
      unless ontology.categories.nil?
        for cat in ontology.categories
          @sorted_ontologies[cat] << ontology
        end
      end

      if ontology.categories.nil? || ontology.categories.empty?
        @sorted_ontologies["0"] << ontology
      end
    end

    @category_tree = @categories.clone

    for value in @category_tree.values
      value[:children]=[]
    end

    for category in @categories.values
      if !category[:parentId].nil? && !category[:parentId].eql?("")
        @category_tree[category[:parentId]][:children]<<category
      end
    end

    for value in @categories.values
      if !value[:parentId].nil? && !value[:parentId].eql?("")
        @category_tree.delete(value[:id])
      end
    end

    @sorted_categories = @category_tree.values.sort{|a,b| a[:name] <=> b[:name]}

    # calculate number of total RI records that have been processed
    resources = OBDWrapper.getResourcesInfo
    @ri_record_count = 0
    resources.each do |resource|
      @ri_record_count += resource.record_count.to_i rescue 0
    end
    @ri_record_count = @ri_record_count == 0 ? 3212530 : @ri_record_count

    ri_stats = OBDWrapper.getResourceStats
    @direct_annotations = ri_stats[:mgrepAnnotations].to_i == 0 ? 1011241184 : ri_stats[:mgrepAnnotations]
    @direct_expanded_annotations = ri_stats[:mgrepAnnotations].to_i + ri_stats[:isaAnnotations].to_i + ri_stats[:mappingAnnotations].to_i
    @direct_expanded_annotations = @direct_expanded_annotations == 0 ? 10416891634 : @direct_expanded_annotations

    @number_of_resources = OBDWrapper.getResourcesInfo.length == 0 ? 24 : OBDWrapper.getResourcesInfo.length

    if !params[:ver].nil?
      render :action => "index#{params[:ver]}"
    end
  end

  def release
    redirect_to :controller => 'home', :action => 'help'
  end

  def help
    # Show the header/footer or not
    layout = params[:pop].eql?("true") ? "popup" : "ontology"
    render :layout => layout
  end

  def recommender

  end

  def annotate

  end

  def all_resources
    @conceptid = params[:conceptid]
    @ontologyid = params[:ontologyid]
    @ontologyversionid = params[:ontologyversionid]
    @search = params[:search]
  end

  def feedback
    # Show the header/footer or not
    feedback_layout = params[:pop].eql?("true") ? "popup" : "ontology"

    # We're using a hidden form field to trigger for error checking
    # If sim_submit is nil, we know the form hasn't been submitted and we should
    # bypass form processing.
    if params[:sim_submit].nil?
      render :layout => feedback_layout
      return
    end

    @errors = []

    if params[:name].nil? || params[:name].empty?
      @errors << "Please include your name"
    end
    if params[:email].nil? || params[:email].length <1 || !params[:email].match(/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i)
      @errors << "Please include your email"
    end
    if params[:comment].nil? || params[:comment].empty?
      @errors << "Please include your comment"
    end
    # verify_recaptcha is a method provided by the recaptcha plugin, returns true or false.
    if ENV['USE_RECAPTCHA'] == 'true' && !session[:user]
      if !verify_recaptcha
        @errors << "Please fill in the proper text from the supplied image"
      end
    end

    unless @errors.empty?
      render :layout => feedback_layout
      return
    end

    Notifier.deliver_feedback(params[:name],params[:email],params[:comment],params[:location])

    if params[:pop].eql?("true")
      render :action => "feedback_complete", :layout => "popup"
    else
      flash[:notice]="Feedback has been sent"
      redirect_to_home
    end
  end

  def robots
    if @subdomain_filter[:active]
      robots = <<-EOF.gsub(/^\s+/, "")
        User-agent: *\n
        Disallow: /
      EOF
      render :text => robots, :content_type => 'text/plain'
    else
      robots = <<-EOF.gsub(/^\s+/, "")
        User-Agent: *
        Disallow:
      EOF
      render :text => robots, :content_type => 'text/plain'
    end
  end

  def account
    @title = "Account Information"
    if session[:user].nil?
      redirect_to :controller => 'login', :action => 'index', :redirect => "/account"
      return
    end

    @user_ontologies = session[:user_ontologies]
    @user_ontologies ||= {}

    @user = session[:user]
    @survey = Survey.find_by_user_id(@user.id)
    if @survey.nil?
      redirect_to :controller => 'users', :action => 'edit', :id => @user.id
      return
    end

    render :partial => "users/details", :layout => "ontology"
  end

  def feedback_complete
  end

end
