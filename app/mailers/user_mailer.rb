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
    
  end # end of select_invite_email method
  
  def guest_invite_email(invited, invitor)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV
     
    payload  = {
      recipients: [
        {
          address: { email: invited.email },
        }
      ],
      content: {
        template_id: 'guest-invite-email'
      },
      substitution_data: {
        invited: invited.first_name,
        invitor: invitor.first_name,
        invitor_email: invitor.email,
        token: invited.raw_invitation_token
      }
    }
    
    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of guest_invite_email method
  
  def friend_invite_email(invited, invitor)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV
     
    payload  = {
      recipients: [
        {
          address: { email: invited.email },
        }
      ],
      content: {
        template_id: 'friend-invite-email'
      },
      substitution_data: {
        invited: invited.first_name,
        invitor: invitor.first_name,
        invitor_email: invitor.email,
        token: invited.raw_invitation_token
      }
    }
    
    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of guest_invite_email method
  
  def set_first_password_email(early_user)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV
     
    payload  = {
      recipients: [
        {
          address: { email: early_user.email },
        }
      ],
      content: {
        template_id: 'set-first-password'
      },
      substitution_data: {
        customer: early_user.first_name,
        token: early_user.tpw
      }
    }
    
    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of guest_invite_email method
  
  def early_signup_followup(customer, membership, invitation_code)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV

    payload  = {
      recipients: [
        {
          address: { email: customer.email },
        }
      ],
      content: {
        template_id: 'early-signup-invite'
      },
      substitution_data: {
        early_user: customer.first_name,
        membership: membership,
        invitation_code: invitation_code
      }
    }

    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of early_signup_followup email
  
  def early_user_complete_signup(customer)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV
     
    payload  = {
      recipients: [
        {
          address: { email: customer.email },
        }
      ],
      content: {
        template_id: 'early-user-complete-signup-email'
      },
      substitution_data: {
        customer: customer.first_name,
        token: customer.tpw
      }
    }
    
    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of early_user_complete_signup email
  
  def customer_delivery_review(customer, delivery_info, delivery_drinks, total_quantity, mates)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV
    @review_date = (delivery_info.delivery_date - 1.day)
    @review_date = @review_date.strftime("%A, %b #{@review_date.day.ordinalize}")
    #Rails.logger.debug("Drink info: #{delivery_drinks.inspect}")
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
        admin_note: delivery_info.admin_delivery_review_note,
        review_date: @review_date,
        drink: delivery_drinks,
        total_quantity: total_quantity,
        total_price: delivery_info.total_price,
        mates: mates
      }
    }
    #Rails.logger.debug("email payload: #{payload.inspect}")
    response = sp.transmission.send_payload(payload)
    p response
          
  end # end of customer_delivery_review email

  def customer_change_confirmation(customer, delivery, change_info)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV
    @review_date = (delivery.delivery_date - 1.day)
    @review_date = @review_date.strftime("%A, %b #{@review_date.day.ordinalize}")
    @customer_message = CustomerDeliveryMessage.where(delivery_id: delivery.id).first
    if !@customer_message.blank?
      @message = @customer_message.message
    end
    payload  = {
      recipients: [
        {
          address: { email: customer.email },
        }
      ],
      content: {
        template_id: 'customer-change-confirmation'
      },
      substitution_data: {
        customer_name: customer.first_name,
        delivery_date: (delivery.delivery_date).strftime("%A, %B %-d"),
        review_date: @review_date,
        customer_message: @message,
        admin_note: delivery.admin_delivery_confirmation_note,
        change: change_info
      }
    }

    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of customer_changes_confirmation email 
  
  def end_user_review_period_reminder(customer)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV
     
    payload  = {
      recipients: [
        {
          address: { email: customer.email },
        }
      ],
      content: {
        template_id: 'end-user-review-period-reminder'
      },
      substitution_data: {
        customer_name: customer.first_name
      }
    }
    #Rails.logger.debug("email payload: #{payload.inspect}")
    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of end_user_review_period_reminder email
  
  def customer_delivery_confirmation_with_changes(customer, delivery, drinks)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV
    # get the customer's message
    @customer_message = CustomerDeliveryMessage.where(delivery_id: delivery.id).first
    if !@customer_message.blank?
      @message = @customer_message.message
    end
    
    # find if customer has previous packaging
    @last_delivery = Delivery.where(user_id: customer.id, status: 'delivered').order('delivery_date DESC').first
    if !@last_delivery.nil?
      @previous_packaging = @last_delivery.customer_has_previous_packaging 
    end
    
    payload  = {
      recipients: [
        {
          address: { email: customer.email },
        }
      ],
      content: {
        template_id: 'customer-delivery-review-with-changes'
      },
      substitution_data: {
        customer_name: customer.first_name,
        delivery_date: (delivery.delivery_date).strftime("%A, %B #{delivery.delivery_date.day.ordinalize}"),
        customer_message: @message,
        previous_packaging: @previous_packaging,
        admin_note: delivery.admin_delivery_confirmation_note,
        drink: drinks
      }
    }
    #Rails.logger.debug("email payload: #{payload.inspect}")
    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of customer_delivery_confirmation_with_changes email
  
  def customer_delivery_confirmation_no_changes(customer, delivery, drinks)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV
    
    # find if customer has previous packaging
    @last_delivery = Delivery.where(user_id: customer.id, status: 'delivered').order('delivery_date DESC').first
    if !@last_delivery.nil?
      @previous_packaging = @last_delivery.customer_has_previous_packaging 
    end
    payload  = {
      recipients: [
        {
          address: { email: customer.email },
        }
      ],
      content: {
        template_id: 'customer-delivery-review-no-changes'
      },
      substitution_data: {
        customer_name: customer.first_name,
        delivery_date: (delivery.delivery_date).strftime("%A, %B #{delivery.delivery_date.day.ordinalize}"),
        previous_packaging: @previous_packaging,
        drink: drinks
      }
    }
    #Rails.logger.debug("email payload: #{payload.inspect}")
    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of customer_delivery_confirmation_no_changes email
  
  def top_of_mind_reminder(customer)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV
     
    payload  = {
      recipients: [
        {
          address: { email: customer.email },
        }
      ],
      content: {
        template_id: 'top-of-mind-reminder'
      },
      substitution_data: {
        customer_name: customer.first_name,
        customer_id: customer.id
      }
    }

    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of top_of_mind_reminder email
  
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
        customer_id: customer.id,
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
  
  def delivery_date_change_confirmation(customer, old_delivery_date, new_delivery_date)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV
    @user_subscription_info = UserSubscription.find_by_user_id(customer.id)
    @new_active_until = (@user_subscription_info.active_until).strftime("%B %-d, %Y")

    payload  = {
      recipients: [
        {
          address: { email: customer.email },
        }
      ],
      content: {
        template_id: 'delivery-date-change-confirmation'
      },
      substitution_data: {
        customer_name: customer.first_name,
        old_delivery_date: (old_delivery_date).strftime("%B #{old_delivery_date.day.ordinalize}"),
        new_delivery_date: (new_delivery_date).strftime("%B #{new_delivery_date.day.ordinalize}"),
        new_active_until: @new_active_until
      }
    }
    #Rails.logger.debug("email payload: #{payload.inspect}")
    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of delivery_date_change_confirmation email
  
  def delivery_zone_change_confirmation(customer, location_and_time, old_date, next_date, user_address_info, delivery_zone_info)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV
    if user_address_info.location_type == "Other"
      @location_name = user_address_info.other_name
    else
      @location_name = user_address_info.location_type
    end
    if !user_address_info.address_unit.nil?
      @street_address = user_address_info.address_street + ", " + user_address_info.address_unit
    else
      @street_address = user_address_info.address_street
    end
    @city_address = user_address_info.city + ", " + user_address_info.state + " " + user_address_info.zip
    @new_time = "Every other " + delivery_zone_info.day_of_week + ", " + (delivery_zone_info.start_time).strftime("%l:%M%P") + " - " + (delivery_zone_info.end_time).strftime("%l:%M%P")

    payload  = {
      recipients: [
        {
          address: { 
            email: customer.email 
            },
        }
      ],
      content: {
        template_id: 'delivery-zone-change-confirmation'
      },
      substitution_data: {
        customer_name: customer.first_name,
        location_and_time: location_and_time,
        old_date: old_date.strftime("%A, %B %-d"),
        next_date: next_date.strftime("%A, %B %-d"),
        location_name: @location_name,
        street_address: @street_address,
        city_address: @city_address,
        new_time: @new_time
      }
    }

    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of delivery_zone_change_confirmation email 
  
  def delivery_date_with_end_date_change_confirmation(customer, old_delivery_date, new_delivery_date)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV
    @user_subscription_info = UserSubscription.find_by_user_id(customer.id)
    @new_active_until = (@user_subscription_info.active_until).strftime("%B %-d, %Y")

    payload  = {
      recipients: [
        {
          address: { email: customer.email },
        }
      ],
      content: {
        template_id: 'delivery-date-change-confirmation'
      },
      substitution_data: {
        customer_name: customer.first_name,
        old_delivery_date: (old_delivery_date).strftime("%B #{old_delivery_date.day.ordinalize}"),
        new_delivery_date: (new_delivery_date).strftime("%B #{new_delivery_date.day.ordinalize}"),
        new_active_until: @new_active_until
      }
    }
    #Rails.logger.debug("email payload: #{payload.inspect}")
    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of delivery_date_with_end_date_change_confirmation email
  
  def welcome_email(customer, membership_name, subscription_fee, renewal_date, membership_length)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV
    
    @customer_delivery_preference = DeliveryPreference.find_by_user_id(customer.id)
    if @customer_delivery_preference.drink_option_id == 1
      @drink_preference = "beer"
    elsif @customer_delivery_preference.drink_option_id == 2
      @drink_preference = "cider"
    else
      @drink_preference = "beer/cider"
    end
    
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
        drink_preference: @drink_preference,
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
  
  def friend_request(customer, friend)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV

    payload  = {
      recipients: [
        {
          address: { email: customer.email },
        }
      ],
      content: {
        template_id: 'friend-request'
      },
      substitution_data: {
        customer_name: customer.first_name,
        customer_id: customer.id,
        friend_first_name: friend.first_name,
        friend_last_name: friend.last_name,
        friend_username: friend.username
      }
    }

    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of friend_request email
  
  def renewing_membership(customer, new_months, end_date)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV
     
    payload  = {
      recipients: [
        {
          address: { email: customer.email },
        }
      ],
      content: {
        template_id: 'renewing-membership'
      },
      substitution_data: {
        customer_name: customer.first_name,
        new_months: new_months,
        new_end_date: end_date
      }
    }
    #Rails.logger.debug("email payload: #{payload.inspect}")
    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of renewing_membership email
  
  def cancelled_membership(customer)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV
     
    payload  = {
      recipients: [
        {
          address: { email: customer.email },
        }
      ],
      content: {
        template_id: 'cancelled-membership'
      },
      substitution_data: {
        customer_name: customer.first_name
      }
    }
    #Rails.logger.debug("email payload: #{payload.inspect}")
    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of cancelled_membership email
  
  def seven_day_membership_expiration_notice(customer, subscription)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV
    if !subscription.auto_renew_subscription_id.blank?
      @renewal_status = true
      @new_membership = Subscription.find_by_id(subscription.auto_renew_subscription_id)
    else
      @renewal_status = false
    end
    
    payload  = {
      recipients: [
        {
          address: { email: customer.email },
        }
      ],
      content: {
        template_id: 'seven-day-membership-expiration-notice'
      },
      substitution_data: {
        customer_name: customer.first_name,
        number_of_deliveries: subscription.deliveries_this_period,
        knird_membership: subscription.subscription.subscription_name,
        expiration_date: (subscription.active_until).strftime("%B %-d, %Y"),
        renewal: @renewal_status,
        new_membership: @new_membership.subscription_name,
        customer_id: customer.id
      }
    }
    #Rails.logger.debug("email payload: #{payload.inspect}")
    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of seven_day_membership_expiration_notice email
  
  def three_day_membership_expiration_notice(customer, subscription)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV
    if !subscription.auto_renew_subscription_id.blank?
      @renewal_status = true
      @new_membership = Subscription.find_by_id(subscription.auto_renew_subscription_id)
    else
      @renewal_status = false
    end
    
    payload  = {
      recipients: [
        {
          address: { email: customer.email },
        }
      ],
      content: {
        template_id: 'three-day-membership-expiration-notice'
      },
      substitution_data: {
        customer_name: customer.first_name,
        number_of_deliveries: subscription.deliveries_this_period,
        knird_membership: subscription.subscription.subscription_name,
        expiration_date: (subscription.active_until).strftime("%B %-d, %Y"),
        renewal: @renewal_status,
        new_membership: @new_membership.subscription_name,
        customer_id: customer.id
      }
    }
    #Rails.logger.debug("email payload: #{payload.inspect}")
    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of three_day_membership_expiration_notice email
  
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
