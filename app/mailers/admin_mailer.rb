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
  
  def info_requested_email(admin_email, name, email)
    #Rails.logger.debug("Name: #{name.inspect}")
    #Rails.logger.debug("Email: #{email.inspect}")
    # determine if this is prod environment
    @prod = User.where(email: "carl@drinkknird.com")[0]
    # mandrill template info
    template_name = "info-requested-email"
    template_content = []
    message = {
      merge: true,
      to: [
        {:email => admin_email}
      ],
      inline_css: true,
      merge_vars: [
        { rcpt: admin_email,
          vars: [
             {name: "name", content: name},
             {name: "email", content: email}
           ]
         }
      ]
    }
    if !@prod.nil?
      mandrill_client.messages.send_template template_name, template_content, message
    end
  end # end of user added email
  
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
end
