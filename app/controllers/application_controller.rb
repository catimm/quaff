class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception (:exception).
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:role_id])
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
    devise_parameter_sanitizer.permit(:invite, keys: [:first_name])
    devise_parameter_sanitizer.permit(:invite, keys: [:cohort])
    devise_parameter_sanitizer.permit(:invite, keys: [:getting_started_step])
    devise_parameter_sanitizer.permit(:accept_invitation, keys: [:first_name])
    devise_parameter_sanitizer.permit(:accept_invitation, keys: [:username])
    devise_parameter_sanitizer.permit(:accept_invitation, keys: [:role_id])
    devise_parameter_sanitizer.permit(:account_update, keys: [:password, :password_confirmation, :current_password])
  end
  
  def resource_name
    :user
  end

  def resource
    @resource ||= User.new
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end
  
  helper_method :resource, :resource_name, :devise_mapping
  
  private
  
  def authenticate_user_from_token! # I think this refers to tokens provided to users invited to join
    email = params[:email].presence
    user = email && User.find_by_email(email)
  
    # Notice how we use Devise.secure_compare to compare the token
    # in the database with the token given in the params, mitigating
    # timing attacks.
    if user && Devise.secure_compare(user.authentication_token, params[:token])
      sign_in user, store: false
    else
      render :status => 401, :json => {:success => false, :errors => ["Unauthorized access"] }
    end
  end
  
  def require_admin
    # depending on your auth, maybe something like...
    if current_user && current_user.role_id == 1
      
    else
      render :file => File.join(Rails.root, 'public/404'), :formats => [:html], :status => 404, :layout => false
    end
  end

  def authenticate_user!(options={})
    if user_signed_in? 
      super(options)
    else
      session[:user_return_to] = request.fullpath
      redirect_to new_user_session_path, :notice => 'Please log in first!'
    end
  end
  
  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = "Access denied!"
    redirect_to root_url
  end
  
  def after_sign_in_path_for(resource)
    #Rails.logger.debug("Original link: #{session[:user_return_to].inspect}")
    @user = current_user
    if current_visit and !current_visit.user
      current_visit.user = current_user
      current_visit.save!
    end
    if current_user.role_id == 1
      # admin route
      @redirect_link = admin_breweries_path
    else # non-admin logic
      @redirect_link = user_orders_path
    end # end of check whether user is admin
    @redirect_link
  end
  
  def after_sign_out_path_for(resource_or_scope)
    #Rails.logger.debug("Signout hit")
    session.delete(:user_return_to)
    root_path
  end
end
