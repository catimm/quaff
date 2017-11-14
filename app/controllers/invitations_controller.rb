class InvitationsController < Devise::InvitationsController
  #before_filter :authenticate_user!
  before_filter :verify_admin, only: [:new, :create]
  
  def new
    super
  end
  
  def create
    # add invited person to User model
    @invited_user = User.invite!(invite_params, current_inviter) do |u|
      # Skip sending the default Devise Invitable e-mail
      u.skip_invitation = true
    end
    # Set the value for :invitation_sent_at because we skip calling the Devise Invitable method deliver_invitation which normally sets this value
    @invited_user.update_attribute :invitation_sent_at, Time.now.utc unless @invited_user.invitation_sent_at
    # show raw token for dev purposes
    #Rails.logger.debug("Raw invitation token: #{@invited_user.raw_invitation_token.inspect}")
    
    # send original email invitation
    UserMailer.select_invite_email(@invited_user, current_user).deliver_now  
    
    redirect_to new_user_invitation_path
  end
  
  def update
    raw_invitation_token = update_resource_params[:invitation_token]
    self.resource = accept_resource
    invitation_accepted = resource.errors.empty?

    yield resource if block_given?

    if invitation_accepted
      # add default notification preferences for new user
      #@default_notification_preference = UserNotificationPreference.new(user_id: resource.id, notification_one: "user high rating availability notice",
      #                                    preference_one: true, threshold_one: 9.5, notification_two: "highly recommended availability notice",
      #                                    preference_two: true, threshold_two: 9.5)
      #@default_notification_preference.save!
      #Rails.logger.debug("Resource info: #{resource.inspect}")
      
      if Devise.allow_insecure_sign_in_after_accept
        flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
        set_flash_message :notice, flash_message if is_flashing_format?
        sign_in(resource_name, resource)
        respond_with resource, :location => after_accept_path_for(resource)
      else
        set_flash_message :notice, :updated_not_active if is_flashing_format?
        respond_with resource, :location => new_session_path(resource_name)
      end
    else
      flash[:error] = resource.errors.full_messages.join(" ")
      resource.invitation_token = raw_invitation_token
      respond_with_navigational(resource){ render :edit }
    end
  end
  
  # method to allow account owner to invite a guest
  def invite_mate
    @invitor_id = params[:id]
    # create new user object
    @new_mate = User.new
    
  end # end of invite_guest action
  
  # method to allow account owner to invite a guest
  def invite_friend
    @invitor_id = params[:id]
    @invitation_code = SpecialCode.where(user_id: current_user.id)[0]
    # create new user object
    @new_mate = User.new
    
  end # end of invite_guest action
  
  def process_mate_invite
    # add invited person to User model
    @invited_user = User.invite!(invite_params, current_inviter) do |u|
      # Skip sending the default Devise Invitable e-mail
      u.skip_invitation = true
    end
    # show raw token for dev purposes
    #Rails.logger.debug("Raw invitation token: #{@invited_user.raw_invitation_token.inspect}")
    # get info on invitor
    @invitor = User.find_by_id(params[:user][:invited_by_id])
    # get invitor invitation code
    @invitation_code = SpecialCode.where(user_id: @invitor.id)[0]
    # get a random color for the user
    @user_color = ["light-aqua-blue", "light-orange", "faded-blue", "light-purple", "faded-green", "light-yellow", "faded-red"].sample
    # Set the value for :invitation_sent_at because we skip calling the Devise Invitable method deliver_invitation which normally sets this value
    @invited_user.attributes = {invitation_sent_at: Time.now.utc, role_id: 5, getting_started_step: 0, 
                                    cohort: "guest", user_color: @user_color, account_id: @invitor.account_id, special_code: @invitation_code.special_code}
    @invited_user.save(validate: false)                         
    
    # connect mate in friend table 
    Friend.create(user_id: @invitor.id, friend_id: @invited_user.id, confirmed: false, mate: true)
    
    # send original email invitation
    UserMailer.guest_invite_email(@invited_user, current_user).deliver_now  
    
    # redirect to mates page
    redirect_to account_settings_mates_user_path
         
  end # end of process_invite_guest action
  
  def process_friend_invite
    # add invited person to User model
    @invited_user = User.invite!(invite_params, current_inviter) do |u|
      # Skip sending the default Devise Invitable e-mail
      u.skip_invitation = true
    end
    # show raw token for dev purposes
    #Rails.logger.debug("Raw invitation token: #{@invited_user.raw_invitation_token.inspect}")
    # get info on invitor
    @invitor = User.find_by_id(params[:user][:invited_by_id])
    # get invitor invitation code
    @invitation_code = SpecialCode.where(user_id: @invitor.id)[0]
    # get a random color for the user
    @user_color = ["light-aqua-blue", "light-orange", "faded-blue", "light-purple", "faded-green", "light-yellow", "faded-red"].sample
    # Set the value for :invitation_sent_at because we skip calling the Devise Invitable method deliver_invitation which normally sets this value
    @invited_user.attributes = {invitation_sent_at: Time.now.utc, role_id: 4, getting_started_step: 0, 
                                    cohort: "guest", user_color: @user_color, special_code: @invitation_code.special_code}
    @invited_user.save(validate: false)                         
    
    # connect friend in friend table 
    Friend.create(user_id: @invitor.id, friend_id: @invited_user.id, confirmed: false, mate: false)
    
    # send original email invitation
    UserMailer.friend_invite_email(@invited_user, current_user).deliver_now 
    
    # redirect to mates page
    redirect_to manage_friends_path
         
  end # end of process_invite_guest action
  
  def check_invited_mate_status
    # find if invited user already has a paid account
    @invited_user = User.find_by_email(params[:id])
    
    if !@invited_user.blank?
      if @invited_user.account_id.nil?
        @status = "good"
      else
        @status = "bad"
      end
    else
      @status = "good"
    end
    
    respond_to do |format|
      format.js
    end # end of redirect to jquery
      
  end # end check_invited_status
  
  def check_invited_friend_status
    # find if invited user already has an account
    @invited_user = User.find_by_email(params[:id])
    
    if !@invited_user.blank?
      if @invited_user.role_id == 6
        @status = "good"
      else
        @status = "bad"
      end
    else
      @status = "good"
    end
    
    respond_to do |format|
      format.js
    end # end of redirect to jquery
      
  end # end check_invited_status
  
  private
  
  def after_accept_path_for(resource)
    edit_user_path(current_user.id)
  end
  
  def verify_admin
    redirect_to root_url unless current_user.role_id == 1
  end
  
end