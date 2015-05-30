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
    super
  end
end