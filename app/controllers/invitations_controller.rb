class InvitationsController < Devise::InvitationsController
  
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
    # send original email invitation
    UserMailer.select_invite_email(@invited_user, current_user).deliver_now  
    
    redirect_to locations_path
  end
  
  def update
    raw_invitation_token = update_resource_params[:invitation_token]
    self.resource = accept_resource
    invitation_accepted = resource.errors.empty?

    yield resource if block_given?

    if invitation_accepted
      # add default notification preferences for new user
      @default_notification_preference = UserNotificationPreference.new(user_id: resource.id, notification_one: "user high rating availability notice",
                                          preference_one: true, threshold_one: 9.5, notification_two: "highly recommended availability notice",
                                          preference_two: true, threshold_two: 9.5)
      @default_notification_preference.save!
      Rails.logger.debug("Resource info: #{resource.inspect}")
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
end