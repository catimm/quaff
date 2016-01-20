class UserMailer < ActionMailer::Base

  def mandrill_client
    @mandrill_client ||= Mandrill::API.new ENV['MANDRILL_APIKEY']
  end
 
  def select_invite_email(invited, inviter)
    url = "http://www.drinkknird.com/users/invitation/accept?invitation_token="
    template_name = "select-invite-email"
    template_content = []
    message = {
      to: [{email: invited.email}],
      inline_css: true,
      merge_vars: [
        {rcpt: invited.email,
         vars: [
           {name: "invited", content: invited.first_name},
           {name: "inviter", content: inviter.first_name},
           {name: "inviter_email", content: inviter.email},
           {name: "url", content: url},
           {name: "token", content: invited.raw_invitation_token}
         ]}
      ]
    }
    mandrill_client.messages.send_template template_name, template_content, message
  end
  
  def add_team_email(invited, inviter, location)
    template_name = "add-team-email"
    template_content = []
    message = {
      to: [{email: invited.email}],
      inline_css: true,
      merge_vars: [
        {rcpt: invited.email,
         vars: [
           {name: "invited", content: invited.first_name},
           {name: "inviter", content: inviter.first_name},
           {name: "inviter_email", content: inviter.email},
           {name: "location", content: location.name}
         ]}
      ]
    }
    mandrill_client.messages.send_template template_name, template_content, message
  end
  
  def new_team_email(invited, inviter, location)
    url = "http://www.drinkknird.com/users/invitation/accept?invitation_token="
    template_name = "new-team-email"
    template_content = []
    message = {
      to: [{email: invited.email}],
      inline_css: true,
      merge_vars: [
        {rcpt: invited.email,
         vars: [
           {name: "invited", content: invited.first_name},
           {name: "inviter", content: inviter.first_name},
           {name: "inviter_email", content: inviter.email},
           {name: "url", content: url},
           {name: "token", content: invited.raw_invitation_token},
           {name: "location", content: location.name}
         ]}
      ]
    }
    mandrill_client.messages.send_template template_name, template_content, message
  end
  
  def welcome_email(user)
    Rails.logger.debug("User info is: #{user.inspect}")
    url = "http://www.drinkknird.com/users/"
    template_name = "welcome-email"
    template_content = []
    message = {
      to: [{email: user.email}],
      inline_css: true,
      merge_vars: [
        {rcpt: user.email,
         vars: [
           {name: "user", content: user.first_name},
           {name: "link", content: url},
           {name: "id", content: user.id}
         ]}
      ]
    }
    mandrill_client.messages.send_template template_name, template_content, message
  end

  def expiring_trial_email(owner, location)
    Rails.logger.debug("Owner info: #{owner.first_name.inspect}")
    Rails.logger.debug("Location info: #{location.name.inspect}")
    template_name = "expiring-trial-email"
    template_content = []
    message = {
      to: [{email: owner.email}],
      inline_css: true,
      merge_vars: [
        {rcpt: owner.email,
         vars: [
           {name: "owner", content: owner.first_name},
           {name: "location", content: location.name}
         ]}
      ]
    }
    mandrill_client.messages.send_template template_name, template_content, message
  end
end
