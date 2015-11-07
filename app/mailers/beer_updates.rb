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
    
    if !@prod.nil?
      mandrill_client.messages.send_template template_name, template_content, message
    end
  end # end of new beers added email
  
  def new_breweries_email(admin_email, location, breweries)
    # determine if this is prod environment
    @prod = User.where(email: "carl@drinkknird.com")[0]
    # mandrill template info
    template_name = "new-breweries-email"
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
             {name: "breweries", content: breweries}
           ]
         }
      ]
    }
    
    if !@prod.nil?
      mandrill_client.messages.send_template template_name, template_content, message
    end
  end # end of new beers added email
  
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
    if !@prod.nil?
      mandrill_client.messages.send_template template_name, template_content, message
    end
  end # end of user added email
  
  def tracking_beer_email(email, beer_name, beer_id, brewery_name, brewery_id, username, location)

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
  end # end of tracking beer email
  
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
  
    def new_retailer_drink_email(email, retailer, brewery_name, brewery_id, beer_name, beer_id, source)
    template_name = "new-retailer-drink-email"
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
             {name: "retailer", content: retailer},
             {name: "brewery_name", content: brewery_name},
             {name: "brewery_id", content: brewery_id},
             {name: "beer_name", content: beer_name},
             {name: "beer_id", content: beer_id},
             {name: "source", content: source}
           ]
         }
      ]
    }
    mandrill_client.messages.send_template template_name, template_content, message
  end # end of new retailer drink email
  
  def retailer_drink_help(admin_email, location, beers)
    # determine if this is prod environment
    @prod = User.where(email: "carl@drinkknird.com")[0]
    # mandrill template info
    template_name = "retailer-drink-help-email"
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
    
    if !@prod.nil?
      mandrill_client.messages.send_template template_name, template_content, message
    end
  end # end of retailer_drink_help email
end
