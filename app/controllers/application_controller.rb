require 'uri'
require 'open-uri'
require 'net/http'
require 'net/https'
require 'net/ftp'

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
  before_filter  :preload_models, :set_global_thread_values

  def preload_models()
    Note
    NodeWrapper
    NodeLabel
    Annotation
    Mapping
    MappingPage
    MarginNote
    OntologyWrapper
    OntologyMetricsWrapper
    Resource
    TreeNode
    UserWrapper
    Groups
    SearchResults
  end

  def set_global_thread_values
    Thread.current[:session] = session
    Thread.current[:request] = request
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

  NOTIFICATION_TYPES = { :notes => "CREATE_NOTE_NOTIFICATION" }

  def to_param(name) # Paramaterizes URLs without encoding
    unless name.nil?
      name.to_s.gsub(' ',"_")
    end
  end

  def undo_param(name) #Undo Paramaterization
    unless name.nil?
      name.to_s.gsub('_'," ")
    end
  end

  def remote_file_exists?(url)
    begin
      url = URI.parse(url)

      if url.kind_of?(URI::FTP)
        check = check_ftp_file(url)
      else
        check = check_http_file(url)
      end

    rescue Exception => e
      return false
    end

    check
  end

  def check_http_file(url)
    session = Net::HTTP.new(url.host, url.port)
    session.use_ssl = true if url.port == 443
    session.start do |http|
      response_valid = http.head(url.request_uri).code.to_i < 400
      return response_valid
    end
  end

  def check_ftp_file(uri)
    ftp = Net::FTP.new(uri.host, uri.user, uri.password)
    ftp.login
    begin
      file_exists = ftp.size(uri.path) > 0
    rescue Exception => e
      # Check using another method
      path = uri.path.split("/")
      filename = path.pop
      path = path.join("/")
      ftp.chdir(path)
      files = ftp.dir
      # Dumb check, just see if the filename is somewhere in the list
      files.each { |file| return true if file.include?(filename) }
    end
    file_exists
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
      redirect_to uri_url(:ontology=>tab.ontology_id,:conceptid=>tab.concept)
    end
  end

  # Verifies if user is logged in
  def authorize
    unless session[:user]
      redirect_to_home
    end
  end

  # Verifies that a user owns an object
  def authorize_owner(id=nil)
    if id.nil?
      id = params[:id].to_i
    end

    if session[:user].nil?
      redirect_to_home
    else
      if id.kind_of?(Array)
        redirect_to_home if !session[:user].admin? && !id.include?(session[:user].id.to_i)
      else
        redirect_to_home if !session[:user].admin? && !session[:user].id.to_i.eql?(id)
      end
    end
  end

  # generates a new random password
  def newpass( len )
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("1".."9").to_a
    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
  end

  # updates the 'history' tab with the current selected concept
  def update_tab(ontology, concept)
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

  # Removes a 'history' tab
  def remove_tab(ontology_id)
    array = session[:ontologies]
    array.delete(find_tab(ontology_id))
    session[:ontologies]=array
  end

  # Returns a specific 'history' tab
  def find_tab(ontology_id)
    array = session[:ontologies]
    for item in array
      if item.ontology_id.eql?(ontology_id)
        return item
      end
    end
    return nil
  end

  def check_delete_mapping_permission(mappings)
    delete_mapping_permission = false
    if session[:user]
      delete_mapping_permission = true if session[:user].admin?
      mappings.each do |mapping|
        break if delete_mapping_permission
        delete_mapping_permission = true if session[:user].id.to_i == mapping.user_id
      end
    end

    delete_mapping_permission
  end

  # Notes-related helpers that could be useful elsewhere

  def convert_java_time(time_in_millis)
    time_in_millis.to_i / 1000
  end

  def time_from_java(java_time)
    Time.at(convert_java_time(java_time.to_i))
  end

  def time_formatted_from_java(java_time)
    time_from_java(java_time).strftime("%m/%d/%Y")
  end

end
