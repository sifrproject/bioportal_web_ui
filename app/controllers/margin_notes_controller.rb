class MarginNotesController < ApplicationController
  # GET /margin_notes
  # GET /margin_notes.xml
  
  layout 'ontology'
  
  skip_before_filter :verify_authenticity_token

    before_filter :authorize, :only=>[:create]
  
  def index
  
  end

  # GET /margin_notes/1
  # GET /margin_notes/1.xml
  def show
    if !params[:concept_id].nil? && params[:property].nil? #gets concept marginal note
      @margin_notes = MarginNote.find(:all, :conditions => {:ontology_version_id => params[:ontology_version_id],:concept_id =>params[:concept_id],:parent_id =>nil})
    elsif !params[:mapping_id].nil? # gets Mapping marginal note
      @margin_notes = MarginNote.find(:all, :conditions => {:mapping_id =>params[:mapping_id],:parent_id =>nil})
      @modal=true
    end
    
    #prepopulates marginal note
    @margin_note = MarginNote.new
    @margin_note.concept_id = params[:concept_id]
    @margin_note.mapping_id = params[:mapping_id]
 
    render :partial =>'show'
 
  end

 

  # POST /margin_notes
  # POST /margin_notes.xml
  def create
    @margin_note = MarginNote.new(params[:margin_note])
    @key = params[:key] # Timestamp passed from view -- needed to recreate unique form ID

    unless session[:user].nil?
      
      @margin_note.user_id = session[:user].id

    
      if @margin_note.save               
        flash[:notice] = 'Note was successfully created.'
        
      else
        flash[:notice] = 'Error creating Note'
      end
      
      #repopulates tab
      
      if !@margin_note.concept_id.nil? && @margin_note.mapping_id.nil? # fetches concept marginal notes
         @margin_notes = MarginNote.find(:all, :conditions => {:ontology_version_id => @margin_note.ontology_version_id,:concept_id =>@margin_note.concept_id, :parent_id =>nil})
      elsif !@margin_note.mapping_id.nil? # fetches mapping marginal notes
         @margin_notes = MarginNote.find(:all, :conditions => {:mapping_id =>@margin_note.mapping_id, :parent_id =>nil})
      end
    end    
   
      # Adds note to syndication
      event = EventItem.new
      event.event_type="Note"
      event.event_type_id=@margin_note.id
      event.ontology_id = @margin_note.ontology_id
      event.save
   
   
   
    #prepopulates new marginal note
    @margin_note = MarginNote.new
    @margin_note.concept_id = params[:concept_id]
    @margin_note.mapping_id = params[:mapping_id]
    
    
    
    
    
    
    render :partial =>'update' 
    
  end
  
  def ont_service
    ontology = DataAccess.getLatestOntology(params[:ontology])
    
    if params[:id]
      concept = DataAccess.getNode(ontology.id,params[:id])    
      notes =[]
      note_res = ActiveRecord::Base.connection().execute("SELECT * from margin_notes  where ontology_id =#{ontology.ontologyId} AND concept_id = '#{concept.id}'")
      note_res.each_hash(with_table=false) {|x| 
        x['note_type']= MarginNote::NOTE_TYPES[x['note_type'].to_i]
        notes<<x}
    else
      notes=[]
      note_res = ActiveRecord::Base.connection().execute("SELECT * from margin_notes  where ontology_id =#{ontology.ontologyId} AND mapping_id is null")
      note_res.each_hash(with_table=false) {|x| 
        x['note_type']= MarginNote::NOTE_TYPES[x['note_type'].to_i]
        notes<<x}

    end
    
    render :xml=> notes
  end
  
  def ver_service
    ontology = DataAccess.getOntology(params[:ontology])
    
    if params[:id]
      concept = DataAccess.getNode(ontology.id,params[:id])    
      notes =[]
      note_res = ActiveRecord::Base.connection().execute("SELECT * from margin_notes  where ontology_version_id =#{ontology.id} AND concept_id = '#{concept.id}'")
      note_res.each_hash(with_table=false) {|x| 
        x['note_type']= MarginNote::NOTE_TYPES[x['note_type'].to_i]
        notes<<x}
    else
      notes=[]
      note_res = ActiveRecord::Base.connection().execute("SELECT * from margin_notes  where ontology_version_id =#{ontology.id} AND mapping_id is null")
      note_res.each_hash(with_table=false) {|x| 
        x['note_type']= MarginNote::NOTE_TYPES[x['note_type'].to_i]
        notes<<x}

    end
    
    render :xml=> notes
  end
  
  
  
end
