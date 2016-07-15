class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception (:exception).
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session
  #before_filter :store_current_location, :unless => :devise_controller?
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) << :role_id
    devise_parameter_sanitizer.for(:sign_up) << :username
    devise_parameter_sanitizer.for(:invite) << :first_name
    devise_parameter_sanitizer.for(:invite) << :beta_tester
    devise_parameter_sanitizer.for(:invite) << :getting_started_step
    devise_parameter_sanitizer.for(:accept_invitation) << :first_name
    devise_parameter_sanitizer.for(:accept_invitation) << :username
    devise_parameter_sanitizer.for(:accept_invitation) << :role_id
    devise_parameter_sanitizer.for(:account_update) { |u| 
      u.permit(:password, :password_confirmation, :current_password) 
    }
  end
  
  private
  
  #def store_current_location
  #  store_location_for(:user, request.url)
  #end
  
  def authenticate_user_from_token!
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
    
  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = "Access denied!"
    redirect_to root_url
  end
  
  def after_sign_in_path_for(resource)
    @user = current_user
    if current_user.role_id == 1 || current_user.role_id == 5
      session[:retail_id] = UserLocation.where(user_id: current_user.id).pluck(:location_id)[0]
    end
    # set a different first view based on the user type
    if !session["user_return_to"].nil?
      @first_view = session["user_return_to"]
    elsif current_user.role_id == 1
      @first_view = admin_breweries_path
    elsif  current_user.role_id == 5
      @first_view = retailer_path(session[:retail_id])
    else
      if @user.getting_started_step < 10
        @first_view = getting_started_path('category')
      else
        @first_view = user_supply_path(current_user.id, 'cooler')
      end
      
    end
    return @first_view
  end
  
  def after_sign_out_path_for(resource_or_scope)
    root_path
  end
end
