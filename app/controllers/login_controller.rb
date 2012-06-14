class LoginController < ApplicationController

  layout 'ontology'

  def index
    # Sets the redirect properties
    if params[:redirect]
      session[:redirect] = params[:redirect]
    else
      session[:redirect] = request.referer
    end
  end

  # logs in a user
  def create
    @errors = validate(params[:user])
    if @errors.size < 1
      logged_in_user = DataAccess.authenticateUser(params[:user][:username],params[:user][:password])
      if logged_in_user
        session[:user] = logged_in_user

        session[:user_ontologies] = user_ontologies(logged_in_user)

        custom_ontologies_text = session[:user_ontologies] ? "The display is now based on your <a href='/account#custom_ontology_set'>Custom Ontology Set</a>." : ""

        flash[:notice] = "Welcome <b>" + logged_in_user.username.to_s+"</b>. " + custom_ontologies_text
        redirect = "/"

        if session[:redirect]
          redirect = session[:redirect]
        end

        redirect_to redirect
      else
        @errors << "Invalid account name/password combination"
        render :action => 'index'
      end
    else
      render :action => 'index'
    end
  end

  # Login as the provided username (only for admin users)
  def login_as
    unless session[:user] && session[:user].admin?
      redirect_to "/"
      return
    end

    user = params[:login_as]
    new_user = DataAccess.getUserByUsername(user)

    if new_user
      session[:admin_user] = session[:user]
      session[:user] = new_user
      session[:user].apikey = session[:admin_user].apikey
      session[:user_ontologies] = user_ontologies(session[:user])
    end

    redirect_to request.referer rescue redirect_to "/"
  end

  # logs out a user
  def destroy
    if session[:admin_user]
      old_user = session[:user]
      session[:user] = session[:admin_user]
      session.delete(:admin_user)
      session[:user_ontologies] = user_ontologies(session[:user])
      flash[:notice] = "Logged out <b>#{old_user.username}</b>, returned to <b>#{session[:user].username}</b>"
    else
      session[:user] = nil
      session[:user_ontologies] = nil
      flash[:notice] = "Logged out"
    end
    redirect_to request.referer
  end

  def lost_password

  end

  # Sends a new password to the user
  def send_pass
    user = DataAccess.getUserByUsername(params[:user][:account_name])

    if !user.nil? && !user.email.downcase.eql?(params[:user][:email].downcase)
      user = nil
    end

    if user.nil?
      flash[:notice]="No account exists with that email address and account name combination"
      redirect_to :action=>'lost_password'
    else
      new_password = newpass(8)
      user.password = new_password
      updated_user = DataAccess.updateUser(user.to_h, user.id)

      if updated_user.kind_of?(UserWrapper)
        Notifier.deliver_lost_password(user,new_password)
        flash[:notice]="Your password has been sent to your email address"
        redirect_to_home
      else
        flash[:notice]="Error retrieving account information, please try again"
        redirect_to :action=>'lost_password'
      end
    end
  end

  private

  def validate(params)
    errors=[]

    if params[:username].nil? || params[:username].length <1
      errors << "Please enter an account name"
    end
    if params[:password].nil? || params[:password].length <1
      errors << "Please enter a password"
    end

    return errors
  end


end
