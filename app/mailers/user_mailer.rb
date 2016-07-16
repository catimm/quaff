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

  def customer_delivery_review(customer, delivery_info, delivery_drinks, total_quantity)
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
        delivery_date: (delivery_info.delivery_date).strftime("%A, %B #{delivery_info.delivery_date.day.ordinalize}"),
        admin_note: delivery_info.admin_note,
        review_date: @review_date,
        drink: delivery_drinks,
        total_quantity: total_quantity,
        total_price: delivery_info.total_price
      }
    }
    #Rails.logger.debug("email payload: #{payload.inspect}")
    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of customer_delivery_review email
  
  def customer_delivery_review_with_changes(customer_name, customer_email, delivery_date, changed_drinks)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV

    payload  = {
      recipients: [
        {
          address: { email: customer_email },
        }
      ],
      content: {
        template_id: 'customer-delivery-review-with-changes'
      },
      substitution_data: {
        customer_name: customer_name,
        delivery_date: (delivery_date).strftime("%A, %B #{delivery_date.day.ordinalize}"),
        drink: changed_drinks
      }
    }
    #Rails.logger.debug("email payload: #{payload.inspect}")
    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of customer_delivery_review_with_changes email
  
  def customer_delivery_review_no_changes(customer_name, customer_email)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV

    payload  = {
      recipients: [
        {
          address: { email: customer_email },
        }
      ],
      content: {
        template_id: 'customer-delivery-review-no-changes'
      },
      substitution_data: {
        customer_name: customer_name
      }
    }
    #Rails.logger.debug("email payload: #{payload.inspect}")
    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of customer_delivery_review_no_changes email
  
  def delivery_confirmation_email(customer, delivery_info, drink_quantity)
    #Rails.logger.debug("customer info: #{customer.inspect}")
    sp = SparkPost::Client.new() # pass api key or get api key from ENV
     
    payload  = {
      recipients: [
        {
          address: { email: customer.email },
        }
      ],
      content: {
        template_id: 'delivery-confirmation-email'
      },
      substitution_data: {
        customer_name: customer.first_name,
        delivery_date: (delivery_info.delivery_date).strftime("%A, %b #{delivery_info.delivery_date.day.ordinalize}"),
        total_quantity: drink_quantity,
        total_subtotal: "%.2f" % (delivery_info.subtotal),
        total_tax: delivery_info.sales_tax,
        total_price: delivery_info.total_price
      }
    }
    
    response = sp.transmission.send_payload(payload)
    p response
  end # end of select_invite_email email
  
  
  def welcome_email(customer, membership_name, subscription_fee, renewal_date, membership_length)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV
     
    payload  = {
      recipients: [
        {
          address: { email: customer.email },
        }
      ],
      content: {
        template_id: 'welcome-email'
      },
      substitution_data: {
        customer_first_name: customer.first_name,
        customer_id: customer.id,
        membership_name: membership_name,
        subscription_fee: subscription_fee,
        renewal_date: renewal_date,
        membership_length: membership_length
      }
    }

    response = sp.transmission.send_payload(payload)
    p response

  end # end of select_invite_email email  

  def expiring_trial_email(owner, location)
    #Rails.logger.debug("Owner info: #{owner.first_name.inspect}")
    #Rails.logger.debug("Location info: #{location.name.inspect}")
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
