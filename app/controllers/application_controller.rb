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
    if current_user.role_id == 1
        # admin route
        @first_view = admin_breweries_path
    else # non-admin logic
      @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first
      if !session[:user_return_to].nil? && !@user_subscription.blank?
        session[:user_subscription_id] = @user_subscription.subscription_id
      end
      
      # set a different first view based on the user type
      if !session[:user_return_to].nil? && @user.getting_started_step >= 7
        @first_view = session[:user_return_to]
      else
        # if user hasn't moved beyond picking a drink category
        if @user.getting_started_step == 0
          @first_view = drink_profile_categories_path
        end
        if @user.getting_started_step == 12
          @first_view = delivery_frequency_getting_started_path
        elsif @user.getting_started_step == 13
          @first_view = delivery_address_getting_started_path
        elsif @user.getting_started_step == 14
          @first_view = delivery_preferences_getting_started_path
        end
        if @user.getting_started_step >= 7
          if !@user_subscription.blank?
            @first_view = user_deliveries_path
          else
            @first_view = free_curation_path
          end
        elsif  @user.getting_started_step == 1
          @first_view = drink_profile_beer_styles_path
        elsif  @user.getting_started_step == 2
          @first_view = drink_profile_beer_costs_path
        elsif  @user.getting_started_step == 3
          @first_view = drink_profile_cider_styles_path
        elsif @user.getting_started_step == 4
          @first_view = drink_profile_cider_costs_path
        elsif @user.getting_started_step == 5
          @first_view = drink_profile_wine_styles_path
        elsif @user.getting_started_step == 6
          @first_view = choose_signup_path
        end
      end # end of selecting path
      
    end # end of check whether user is admin
    return @first_view
  end
  
  def after_sign_out_path_for(resource_or_scope)
    Rails.logger.debug("Signout hit")
    session.delete(:user_return_to)
    root_path
  end
end
