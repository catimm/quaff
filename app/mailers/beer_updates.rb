class BeerUpdates < ActionMailer::Base
  
  def mandrill_client
    @mandrill_client ||= Mandrill::API.new ENV['MANDRILL_APIKEY']
  end
  
  def new_beers_email(admin_email, location, beers)
    # determine if this is prod environment
    @prod = User.where(email: "carl@drinkknird.com")[0]
    # mandrill template info
    template_name = "new-beers-email"
    template_content = []
    message = {
      merge: true,
      merge_language: "handlebars",
      to: [
        {:email => admin_email}
      ],
      inline_css: true,
      merge_vars: [
        { rcpt: admin_email,
          vars: [
             {name: "location", content: location},
             {name: "beers", content: beers}
           ]
         }
      ]
    }
    
    if @prod.username == "CarlAdmin"
      mandrill_client.messages.send_template template_name, template_content, message
    end
  end
  
  def user_added_beers_email(admin_email, user, beers)
    # determine if this is prod environment
    @prod = User.where(email: "carl@drinkknird.com")[0]
    # mandrill template info
    template_name = "new-beers-email"
    template_content = []
    message = {
      merge: true,
      merge_language: "handlebars",
      to: [
        {:email => admin_email}
      ],
      inline_css: true,
      merge_vars: [
        { rcpt: admin_email,
          vars: [
             {name: "location", content: user},
             {name: "beers", content: beers}
           ]
         }
      ]
    }
    if @prod.username == "CarlAdmin"
      mandrill_client.messages.send_template template_name, template_content, message
    end
  end
  
  def tracking_beer_email(email, beer_name, beer_id, brewery_name, brewery_id, username, location)
    Rails.logger.debug("Email: #{email.inspect}")
    Rails.logger.debug("Beer name: #{beer_name.inspect}")
    Rails.logger.debug("Beer ID: #{beer_id.inspect}")
    Rails.logger.debug("Brewery name: #{brewery_name.inspect}")
    Rails.logger.debug("Brewery ID: #{brewery_id.inspect}")
    Rails.logger.debug("Usernam: #{username.inspect}")
    Rails.logger.debug("Location: #{location.inspect}")

    website = root_url
    template_name = "tracking-beer-email"
    template_content = []
    message = {
      merge: true,
      to: [
        {:email => email}
      ],
      inline_css: true,
      merge_vars: [
        { rcpt: email,
          vars: [
             {name: "beer_name", content: beer_name},
             {name: "beer_id", content: beer_id},
             {name: "brewery_name", content: brewery_name},
             {name: "brewery_id", content: brewery_id},
             {name: "username", content: username},
             {name: "location", content: location},
             {name: "website", content: website}
           ]
         }
      ]
    }
    mandrill_client.messages.send_template template_name, template_content, message
  end
  
end
