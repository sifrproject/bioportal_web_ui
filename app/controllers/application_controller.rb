require 'uri'
# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

# Custom 404 handling
class Error404 < StandardError; end
class PostNotFound < Error404; end

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  
  include ExceptionNotifiable
  
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'ba3e1ab68d3ab8bd1a1e109dfad93d30'
  
  # Needed for memcache to understand the models in storage
  before_filter  :preload_models

  def preload_models() 
    NodeWrapper
    Annotation
    Mapping
    MarginNote
    OntologyWrapper
    Resource
    TreeNode
    UserWrapper
  end
  
  # Custom 404 handling
  rescue_from Error404, :with => :render_404
  
  def render_404
    respond_to do |type| 
      #type.html { render :template => "errors/error_404", :status => 404, :layout => 'error' }
      type.html { render :file => "#{RAILS_ROOT}/public/404.html", :status => 404 }
      type.all  { render :nothing => true, :status => 404 } 
    end
    true
  end
  
  def to_param(name) # Paramaterizes URLs without encoding
    name.gsub(' ',"_")
  end
  
  def undo_param(name) #Undo Paramaterization   
    unless name.nil?
      name.gsub('_'," ")
    end
  end
  
  def redirect_to_browse # Redirect to the browse Ontologies page
    redirect_to "/ontologies"
  end
  
  def redirect_to_home # Redirect to Home Page
    redirect_to "/"
  end
  
  def redirect_to_history # Redirects to the correct tab through the history system
    if session[:redirect].nil?
      redirect_to_home    
    else
      tab = find_tab(session[:redirect][:ontology])
      session[:redirect]=nil
      redirect_to uri_url(:ontology=>tab.ontology_id,:id=>tab.concept)
    end
  end
  
  
  def authorize  # Verifies if user is logged in
    unless session[:user]      
      redirect_to_home
    end
  end
  
  def isAdmin # Verifies if user is an admin
    if session[:user].nil? || !session[:user].admin
      return false
    else
      return true
    end
    
  end
  
  def authorize_owner(id=nil) # Verifies that a user owns an object
    #puts id
    if id.nil? 
      #puts params[:id]
      id = params[:id].to_i
    end
    #puts "new id #{id}"
    if session[:user].nil?
      redirect_to_home
    else
      #puts "#{session[:user].id.to_i} vs #{id} "
      if !session[:user].id.to_i.eql?(id) && !session[:user].admin?
        redirect_to_home      
      end
    end
    
  end 
  
  
  def newpass( len ) # generates a new random password
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("1".."9").to_a
    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
  end
  
  def update_tab(ontology, concept)  #updates the 'history' tab with the current selected concept
    
    array = session[:ontologies] || []
    found = false
    for item in array
      if item.ontology_id.eql?(ontology.id)
        item.concept=concept
        found=true
      end
    end
    
    unless found
      array << History.new(ontology.id,ontology.displayLabel,concept)    
    end
    
    session[:ontologies]=array
  end
  
  def remove_tab(ontology_id) # Removes a 'history' tab
    array = session[:ontologies]    
    array.delete(find_tab(ontology_id))        
    session[:ontologies]=array   
  end
  
  def find_tab(ontology_id) # Returns a specific 'history' tab
    array = session[:ontologies]
    for item in array
      if item.ontology_id.eql?(ontology_id)
        return item        
      end
    end
    return nil
  end
  
end
