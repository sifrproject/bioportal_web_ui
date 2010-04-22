# This require is here to prevent problems when trying to get models
# from the cache. Sometimes, even in the production env, Rails wouldn't have
# the model cached and an exception would be thrown saying that the
# model was unknown/undefined.
require_dependency 'groups'

class HomeController < ApplicationController
  
  layout 'ontology'
  
  def index  
    @ontologies = DataAccess.getOntologyList() # -- Gets list of ontologies
    @groups = DataAccess.getGroups()
    
    active_onts_by_notes_query = "select ontology_id,count(ontology_id) as note_count from margin_notes as note  group by ontology_id order by note_count desc"
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
    @active_totals = @active_totals.sort{|x,y| y[3].to_i<=>x[3].to_i}

    @active_totals = @active_totals[0,5]

    @categories = DataAccess.getCategories()
    @last_notes= MarginNote.find(:all,:order=>'created_at desc',:limit=>5)    
    @last_mappings = Mapping.find(:all,:order=>'created_at desc',:limit=>5)
    
    
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
    #puts @category_tree.inspect
    
    
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
    
     if !params[:ver].nil?
       render :action=> "index#{params[:ver]}"
     end     
     
  end

  def release
    
  end

  def recommender
    
  end

  def annotate
    
  end

  def all_resources
    @concept=params[:concept]
    @ontology=params[:ontology]
    @search=params[:search]
  end
  
  def feedback
    # We're using a hidden form field to trigger for error checking
    # If sim_submit is nil, we know the form hasn't been submitted and we should
    # bypass form processing.
    if params[:sim_submit].nil?
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
    if ENV['USE_RECAPTCHA'] == 'true'
      if !verify_recaptcha
        @errors << "Please fill in the proper text from the supplied image"
      end
    end

    unless @errors.empty?
      return
    end
    
    Notifier.deliver_feedback(params[:name],params[:email],params[:comment])   
    flash[:notice]="Feedback has been sent"
    redirect_to_home
  end



end
