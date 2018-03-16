class AdminMailer < ActionMailer::Base
  require 'sparkpost'
  require 'open-uri'
  @host = open('https://api.sparkpost.com')
  
  def new_db_additions(admin_email, breweries, drinks)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV

    payload  = {
      recipients: [
        {
          address: { email: admin_email },
        }
      ],
      content: {
        template_id: 'new-db-additions-email'
      },
      substitution_data: {
        breweries: breweries,
        drinks: drinks,
      }
    }
    
    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of retailer_drink_help email
  
  def delivery_date_change_notice(admin_email, customer, old_delivery_date, new_delivery_date)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV

    payload  = {
      recipients: [
        {
          address: { email: admin_email },
        }
      ],
      content: {
        template_id: 'delivery-date-change-notice'
      },
      substitution_data: {
        customer_name: customer.first_name,
        customer_username: customer.username,
        old_delivery_date: (old_delivery_date).strftime("%B #{old_delivery_date.day.ordinalize}"),
        new_delivery_date: (new_delivery_date).strftime("%B #{new_delivery_date.day.ordinalize}")
      }
    }
    
    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of delivery_date_change_notice email
  
  def shipment_location_change_notice(customer, admin_email, next_delivery, old_zone, new_zone)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV
    @next_delivery_date = next_delivery.delivery_date.strftime("%A, %B %-d")
    payload  = {
      recipients: [
        {
          address: { email: admin_email },
        }
      ],
      content: {
        template_id: 'shipment-location-change-notice'
      },
      substitution_data: {
        customer_name: customer.first_name,
        customer_username: customer.username,
        account_id: customer.account_id,
        next_delivery_date: @next_delivery_date,
        old_zone: old_zone,
        new_zone: new_zone
      }
    }
    
    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of shipment_location_change_notice email
  
  def early_code_request(admin_email, requestor_name, requestor_email)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV

    payload  = {
      recipients: [
        {
          address: { email: admin_email },
        }
      ],
      content: {
        template_id: 'early-code-request'
      },
      substitution_data: {
        requestor_name: requestor_name,
        requestor_email: requestor_email
      }
    }
    
    response = sp.transmission.send_payload(payload)
    p response

  end # end of user added email
  
  def outside_seattle_interest(requestor, requestor_location)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV

    payload  = {
      recipients: [
        {
          address: { email: "carl@drinkknird.com" },
        }
      ],
      content: {
        template_id: 'outside-seattle-interest'
      },
      substitution_data: {
        requestor_name: requestor.first_name,
        requestor_email: requestor.email,
        requestor_id: requestor.id,
        requestor_city: requestor_location.city,
        requestor_zip: requestor_location.zip
      }
    }
    
    response = sp.transmission.send_payload(payload)
    p response

  end # end of user added email
  
  def delivery_zone_number_update(admin_email, delivery_zone_info)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV

    payload  = {
      recipients: [
        {
          address: { email: admin_email },
        }
      ],
      content: {
        template_id: 'delivery-zone-number-update'
      },
      substitution_data: {
        delivery_zone_id: delivery_zone_info.id,
        delivery_zone_zip: delivery_zone_info.zip_code,
        delivery_zone_max_number: delivery_zone_info.max_account_number,
        delivery_zone_current_number: delivery_zone_info.current_account_number
      }
    }
    
    response = sp.transmission.send_payload(payload)
    p response

  end # end of user delivery_zone_number_update email
  
  def delivery_zone_change_notice(customer, admin_email, location_and_time, old_date, next_date, user_address_info, delivery_zone_info)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV
    if old_date == "none"
      @old_date = "none"
    else
      @old_date = old_date.strftime("%A, %B %-d")
    end
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
    @new_time = delivery_zone_info.day_of_week + "s, " + (delivery_zone_info.start_time).strftime("%l:%M%P") + " - " + (delivery_zone_info.end_time).strftime("%l:%M%P")

    payload  = {
      recipients: [
        {
          address: { 
            email: admin_email 
            },
        }
      ],
      content: {
        template_id: 'delivery-zone-change-notice'
      },
      substitution_data: {
        customer_name: customer.first_name,
        customer_email: customer.email,
        location_and_time: location_and_time,
        old_date: @old_date,
        next_date: next_date.strftime("%A, %B %-d"),
        location_name: @location_name,
        street_address: @street_address,
        city_address: @city_address,
        new_time: @new_time
      }
    }

    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of delivery_zone_change_notice email 
  
  def porting_details_email(username, total_drinks, total_drinks_added, total_new_breweries, total_new_drinks, new_drink_info, new_drink_info_count, no_beer_type_id, no_beer_type_id_count)
    # determine if this is prod environment
    @prod = User.where(email: "carl@drinkknird.com")[0]
    # mandrill template info
    template_name = "porting-details-email"
    template_content = []
    message = {
      merge: true,
      merge_language: "handlebars",
      to: [
        {:email => @prod.email }
      ],
      inline_css: true,
      merge_vars: [
        { rcpt: @prod.email,
          vars: [
             {name: "username", content: username},
             {name: "total_drinks", content: total_drinks},
             {name: "total_drinks_added", content: total_drinks_added},
             {name: "total_new_breweries", content: total_new_breweries},
             {name: "total_new_drinks", content: total_new_drinks},
             {name: "new_drink_info", content: new_drink_info},
             {name: "new_drink_info_count", content: new_drink_info_count},
             {name: "no_beer_type_id", content: no_beer_type_id},
             {name: "no_beer_type_id_count", content: no_beer_type_id_count}
           ]
         }
      ]
    }
    
    if !@prod.nil?
      mandrill_client.messages.send_template template_name, template_content, message
    end
  end # end of porting email
  
  def admin_drink_change_review(user, next_delivery)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV

    payload  = {
      recipients: [
        {
          address: { email: "carl@drinkknird.com" },
        }
      ],
      content: {
        template_id: 'admin-drink-change-review'
      },
      substitution_data: {
        account_id: user.account_id,
        user_first_name: user.first_name,
        user_username: user.username,
        delivery_id: next_delivery.id,
        delivery_date: next_delivery.delivery_date
      }
    }

    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of admin_drink_change_review email

  def admin_message_review(user, message, delivery_id)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV

    payload  = {
      recipients: [
        {
          address: { email: "carl@drinkknird.com" },
        }
      ],
      content: {
        template_id: 'admin-message-review'
      },
      substitution_data: {
        account_id: user.account_id,
        user_first_name: user.first_name,
        user_username: user.username,
        delivery_id: delivery_id,
        message: message
      }
    }

    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of admin_message_review email

  def admin_customer_order(user, order)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV

    payload  = {
      recipients: [
        {
          address: { email: "carl@drinkknird.com" },
        }
      ],
      content: {
        template_id: 'admin-customer-order'
      },
      substitution_data: {
        user_first_name: user.first_name,
        user_username: user.username,
        order_id: order.id,
        delivery_date: order.delivery_date,
        additional_requests: order.additional_requests
      }
    }

    response = sp.transmission.send_payload(payload)
    p response
  end
    
  def admin_customer_delivery_request(admin_email, user, message)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV

    payload  = {
      recipients: [
        {
          address: { email: admin_email },
        }
      ],
      content: {
        template_id: 'admin-customer-delivery-request'
      },
      substitution_data: {
        user_id: user.id,
        user_first_name: user.first_name,
        user_username: user.username,
        message: message
      }
    }

    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of admin_customer_delivery_request email
  
  def admin_failed_invoice_payment_notice(customer, amount, subscription, payment_descriptor)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV

    payload  = {
      recipients: [
        {
          address: { email: "carl@drinkknird.com" },
        }
      ],
      content: {
        template_id: 'admin-failed-invoice-notice'
      },
      substitution_data: {
        customer_name: customer.first_name,
        customer_email: customer.email,
        customer_id: customer.id,
        amount: amount,
        knird_subscription: subscription.id,
        stripe_subscription: subscription.stripe_subscription_number,
        payment_descriptor: payment_descriptor
      }
    }

    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of admin_failed_invoice_payment_notice email
  
  def admin_failed_charge_notice(customer, delivery)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV

    payload  = {
      recipients: [
        {
          address: { email: "carl@drinkknird.com" },
        }
      ],
      content: {
        template_id: 'admin-failed-charge-notice'
      },
      substitution_data: {
        customer_name: customer.first_name,
        customer_email: customer.email,
        customer_id: customer.id,
        delivery_amount: delivery.total_price,
        delivery_id: delivery.id,
        delivery_date: delivery.delivery_date
      }
    }

    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of admin_failed_charge_notice email
  
  def disti_inventory_import_email(admin)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV

    payload  = {
      recipients: [
        {
          address: { email: admin },
        }
      ],
      content: {
        template_id: 'disti-inventory-import-email'
      }
    }

    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of disti_inventory_import_email
  
  def admin_disti_drink_order(disti, disti_order, admin_email, admin_name)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV
    #Rails.logger.debug("Drink info: #{delivery_drinks.inspect}")
    payload  = {
      recipients: [
        {
          address: { email: admin_email },
        }
      ],
      content: {
        template_id: 'admin-disti-drink-order'
      },
      substitution_data: {
        admin_name: admin_name,
        disti_name: disti.disti_name,
        contact_name: disti.contact_name,
        contact_email: disti.contact_email,
        contact_phone: disti.contact_phone,
        order: disti_order
      }
    }
    #Rails.logger.debug("email payload: #{payload.inspect}")
    response = sp.transmission.send_payload(payload)
    p response
          
  end # end of admin_disti_drink_order email
end
