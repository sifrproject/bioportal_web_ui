
class UsersController < ApplicationController
  before_filter :authorize_owner, :only=>[:index,:edit,:destroy]

  layout 'ontology'

  # GET /users
  # GET /users.xml
  def index

    @users = DataAccess.getUsers

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @users.to_xml }
    end
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    if session[:user].nil? || !session[:user].id.eql?(params[:id])
      redirect_to :controller => 'login', :action => 'index', :redirect => "/accounts/#{params[:id]}"
    end

    @user = DataAccess.getUser(params[:id])

    @user_ontologies = session[:user_ontologies]
    @user_ontologies ||= {}

    # Get all ontologies that match this user
    @user_submitted_ontologies = []
    DataAccess.getOntologyList.each do |ont|
      begin
        @user_submitted_ontologies << ont if DataAccess.getOntology(ont.id).admin?(params[:id].to_i)
      rescue Exception => e
        next
      end
    end
  end

  # GET /users/new
  def new
    @user = UserWrapper.new
  end

  # GET /users/1;edit
  def edit
    if session[:user].nil? || !session[:user].id.eql?(params[:id])
      redirect_to :controller => 'login', :action => 'index', :redirect => "/accounts/#{params[:id]}"
    end

    @user = DataAccess.getUser(params[:id])
    @survey = Survey.find_by_user_id(params[:id])

    #  @user = User.find(params[:id])
    if(params[:password].eql?("true"))
      @user.validate_password = true
    end

    # Get all ontologies that match this user
    @user_ontologies = []
    DataAccess.getOntologyList.each do |ont|
      begin
        @user_ontologies << ont if ont.admin?(self)
      rescue Exception => e
        next
      end
    end

    render :action =>'edit'
  end

  # POST /users
  # POST /users.xml
  def create
    @errors = validate(params[:user])

    respond_to do |format|
      # Remove survey information from user object
      survey_params = params[:user][:survey]
      params[:user].delete(:survey)

      if @errors.size <1
        @user = DataAccess.createUser(params[:user])
        if @user.kind_of?(Hash) && @user[:error]
          @errors << @user[:longMessage]
          @user = UserWrapper.new
          @user.from_params(params[:user])
          format.html { render :action => "new" }
        else
          unless survey_params.nil?
            survey_params[:user_id] = @user.id
            survey_params[:ontologies_of_interest] = get_ontology_list(survey_params[:ont_list])
            survey_params.delete(:ont_list)
            @survey = Survey.create(survey_params)
          end

          # Attempt to register user to list
          if params[:user][:register_mail_list]
            Notifier.deliver_register_for_announce_list(@user.email) rescue nil
          end

          flash[:notice] = 'Account was successfully created.'
          session[:user]=@user
          format.html { redirect_to_browse }
          format.xml  { head :created, :location => user_url(@user) }
        end
      else
        @user = UserWrapper.new
        @user.from_params(params[:user])
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    @errors = validate_update(params[:user])

    # Remove survey information from user object
    survey_params = params[:user][:survey]
    params[:user].delete(:survey)

    if @errors.length > 0
      flash[:notice] = @user.nil? ? "Error, try again" : @user[:longMessage]
      redirect_to edit_user_path(params[:id])
    else
      @user = DataAccess.updateUser(params[:user],params[:id])
      if @user.nil? || @user.kind_of?(Hash) && @user[:error]
        flash[:notice] = @user.nil? ? "Error, try again" : @user[:longMessage]
        redirect_to params.merge!(:action => "edit", :errors => @errors)
        return
      end

      # Attempt to register user to list
      if params[:user][:register_mail_list]
        Notifier.deliver_register_for_announce_list(@user.email) rescue nil
      end

      unless survey_params.nil?
        @survey = Survey.find_by_user_id(params[:id])
        if @survey.nil?
          survey_params[:ontologies_of_interest] = get_ontology_list(survey_params[:ont_list])
          survey_params.delete(:ont_list)
          @survey = Survey.create(survey_params)
        else
          survey_params[:ontologies_of_interest] = get_ontology_list(survey_params[:ont_list])
          survey_params.delete(:ont_list)
          Survey.update(@survey.id, survey_params)
        end
      end

      flash[:notice] = 'Account was successfully updated.'
      redirect_to user_path(@user.id)
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to users_url }
      format.xml  { head :ok }
    end
  end


  def validate_username
    username = params[:username]

    userObj = DataAccess.getUserByUsername(username)

    if !userObj.nil?
      user = {}
      user[:username] = userObj.username
      user[:id] = userObj.id
      user[:email] = userObj.email
    else
      user = nil
    end

    render :json => { :userValid => !user.nil?, :user => user }
  end

  def submit_license
    user = session[:user]
    user.ontologylicensetext = params[:ontologylicensetext]
    user.ontologylicense = params[:ontologylicense]
    ontology_id = params[:ontologylicense]

    redirect_location = params[:redirect_location].nil? || params[:redirect_location].empty? ? :back : params[:redirect_location]

    if user.ontologylicensetext.length > 512
      redirect_to :back, :flash => { :error => "License information cannot be longer than 512 characters" }
      return
    end

    if user.ontologylicensetext.length < 2
      redirect_to :back, :flash => { :error => "License information must contain at least two characters" }
      return
    end

    begin
      updated_user = DataAccess.updateUser(user.to_h, user.id)
    rescue Exception => e
      redirect_to :back, :flash => { :error => "There was a problem submitting your license, please try again" }
      return
    end

    DataAccess.removeLatestOntologyFromCache(ontology_id)

    redirect_to redirect_location
  end

  def custom_ontologies
    ontologies = params["ontology"] ? params["ontology"]["ontologyId"].collect {|a| a.to_i} : nil

    custom_ontologies = CustomOntologies.find_or_create_by_user_id(session[:user].id)

    if ontologies.nil?
      custom_ontologies.destroy
      session[:user_ontologies] = nil
    else
      custom_ontologies.ontologies = ontologies
      custom_ontologies.save

      session[:user_ontologies] = {} if session[:user_ontologies].nil?
      session[:user_ontologies][:virtual_ids] = custom_ontologies.ontologies
    end

    flash[:notice] = 'Custom Ontologies were saved'
    redirect_to user_path(session[:user].id)
  end

private

  def get_ontology_list(ont_hash)
    ontologies = []
    ont_hash.each do |ont, checked|
      ontologies << ont if checked.to_i == 1
    end
    ontologies.join(";")
  end

  def validate(params)
    errors=[]
    if !params[:phone].nil? && params[:phone].length > 0
      if  !params[:phone].match(/^(1\s*[-\/\.]?)?(\((\d{3})\)|(\d{3}))\s*[-\/\.]?\s*(\d{3})\s*[-\/\.]?\s*(\d{4})\s*(([xX]|[eE][xX][tT])\.?\s*(\d+))*$/i)
        errors << "Please enter a valid phone number"
      end
    end
    if params[:email].nil? || params[:email].length <1 || !params[:email].match(/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i)
      errors << "Please enter an email address"
    end
    if !params[:email].eql?(params[:email_confirmation])
      errors << "Your Email and Email Confirmation do not match"
    end
    if !params[:username].nil? || !params[:username].length < 1
      existing_user = DataAccess.getUserByUsername(params[:username])
      if existing_user
        errors << "Account name exists, please choose a new one"
      end
    end
    if params[:username].nil? || params[:username].length < 1
      errors << "Please enter an account name"
    end
    if params[:password].nil? || params[:password].length < 1
      errors << "Please enter a password"
    end
    if !params[:password].eql?(params[:password_confirmation])
      errors << "Your Password and Password Confirmation do not match"
    end
    # verify_recaptcha is a method provided by the recaptcha plugin, returns true or false.
    if ENV['USE_RECAPTCHA'] == 'true'
      if !verify_recaptcha
        errors << "Please fill in the proper text from the supplied image"
      end
    end

    return errors
  end

  def validate_update(params)
    errors=[]
    if params[:email].nil? || params[:email].length <1 || !params[:email].match(/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i)
      errors << "Please enter an email address"
    end

    return errors
  end
end
