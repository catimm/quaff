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
  
  def authenticate_user!(options={})
    if user_signed_in? 
      if current_user.getting_started_step == 11
        super(options)
      else
        sign_out current_user
        redirect_to new_user_session_path, :notice => 'Please log in first!'
      end
    else
      session[:user_return_to] = request.fullpath
      redirect_to new_user_session_path, :notice => 'Please log in first!'
      ## if you want render 404 page
      ## render :file => File.join(Rails.root, 'public/404'), :formats => [:html], :status => 404, :layout => false
    end
  end
  
  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = "Access denied!"
    redirect_to root_url
  end
  
  def after_sign_in_path_for(resource)
    #Rails.logger.debug("Original link: #{session[:user_return_to].inspect}")
    @user = current_user

    # set a different first view based on the user type
    if !session[:user_return_to].nil?
      @first_view = session[:user_return_to]
    elsif  @user.getting_started_step < 2
      @first_view = edit_user_path(@user.id)
    elsif  @user.getting_started_step == 2
      @first_view = delivery_address_getting_started_path
    elsif  @user.getting_started_step == 3
      @first_view = delivery_preferences_getting_started_path
    elsif  @user.getting_started_step == 4
      @first_view = drink_choice_getting_started_path
    elsif  @user.getting_started_step == 5
      @first_view = drink_journey_getting_started_path
    elsif  @user.getting_started_step == 6
      @first_view = drink_style_likes_getting_started_path
    elsif  @user.getting_started_step == 7
      @first_view = drink_style_dislikes_getting_started_path
    elsif  @user.getting_started_step == 8
      @first_view = drinks_weekly_getting_started_path
    elsif  @user.getting_started_step == 9
      @first_view = drinks_large_getting_started_path
    elsif  @user.getting_started_step == 10
      @first_view = account_membership_getting_started_path
    else
      if current_user.role_id == 1
        @first_view = admin_breweries_path
      else
        @first_view = user_deliveries_path
      end
    end
    return @first_view
  end
  
  def after_sign_out_path_for(resource_or_scope)
    session.delete(:user_return_to)
    root_path
  end
end
