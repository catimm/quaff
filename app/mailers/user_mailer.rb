class UserMailer < ActionMailer::Base
  require 'sparkpost'
  require 'open-uri'
  @host = open('https://api.sparkpost.com')
  
  def select_invite_email(invited, inviter)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV
     
    payload  = {
      recipients: [
        {
          address: { email: invited.email },
        }
      ],
      content: {
        template_id: 'select-invite-email'
      },
      substitution_data: {
        invited: invited.first_name,
        inviter: inviter.first_name,
        inviter_email: inviter.email,
        token: invited.raw_invitation_token
      }
    }
    
    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of select_invite_email email

  def customer_delivery_review(customer, delivery_info, delivery_drinks)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV
    @review_date = (delivery_info.delivery_date - 1.day)
    @review_date = @review_date.strftime("%A, %b #{@review_date.day.ordinalize}")
    payload  = {
      recipients: [
        {
          address: { email: customer.email },
        }
      ],
      content: {
        template_id: 'customer-delivery-review'
      },
      substitution_data: {
        customer_name: customer.first_name,
        delivery_date: (delivery_info.delivery_date).strftime("%A, %b #{delivery_info.delivery_date.day.ordinalize}"),
        review_date: @review_date,
        drink: delivery_drinks,
        total_quantity: delivery_drinks.count,
        total_subtotal: "%.2f" % (delivery_info.subtotal),
        total_tax: delivery_info.sales_tax,
        total_price: delivery_info.total_price
      }
    }
    #Rails.logger.debug("email payload: #{payload.inspect}")
    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of select_invite_email email
    
  def welcome_email(user)
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
