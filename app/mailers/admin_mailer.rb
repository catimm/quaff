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
  
  def new_retailer_drink_email(email, retailer, maker, maker_id, drink, drink_id, source)
    SparkPost::Request.request(open('https://api.sparkpost.com/api/v1/transmissions'), ENV['SPARKPOST_API_KEY'], {
      recipients: [
        {
          address: { email: email },
          substitution_data: {
            retailer: retailer,
            maker: brewery_name,
            maker_id: brewery_id,
            drink: beer_name,
            drink_id: beer_id,
            source: source
          }
        }
      ],
      content: {
        template_id: 'new-retailer-drink-email'
      },
      #substitution_data: {
      #  title: 'Daily News'
      #}
    })
  end # end of new retailer drink email
  
  def retailer_drink_help(admin_email, retailer, drinks)
    sp = SparkPost::Client.new() # pass api key or get api key from ENV

    payload  = {
      recipients: [
        {
          address: { email: admin_email },
        }
      ],
      content: {
        template_id: 'retailer-drink-help-email'
      },
      substitution_data: {
        retailer: retailer,
        drinks: drinks,
      }
    }
    
    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of retailer_drink_help email
  
  def admin_message_review(messages, message_status)
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
        message: messages,
        status: message_status
      }
    }

    response = sp.transmission.send_payload(payload)
    p response
    
  end # end of admin_message_review email
  
  def admin_failed_invoice_payment_notice(customer, subscription)
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
        knird_subscription: subscription.id,
        stripe_subscription: subscription.stripe_subscription_number
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
end
