class ReloadsController < ApplicationController
  before_filter :verify_admin
    include UserLikesDrinkTypes
    include TypeBasedGuess
    include BestGuess
    
  def index
    # find early users who need to complete registration  
    @early_users = User.where(cohort: 'f_&_f', role_id: 4).where.not(invitation_token: nil)
    Rails.logger.debug("Early user info: #{@early_users.inspect}")
    @admin = User.find_by_id(1)
    @early_users.each do |customer|
      UserMailer.early_user_complete_signup(customer).deliver_now
    end
      
  end # end index action
  
  private
  
  def verify_admin
      redirect_to root_url unless current_user.role_id == 1
    end
    
end