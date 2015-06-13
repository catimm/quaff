class BeerUpdates < ActionMailer::Base
  
  def mandrill_client
    @mandrill_client ||= Mandrill::API.new ENV['MANDRILL_APIKEY']
  end
  
  def new_beers_email(location, beers)
    # Rails.logger.debug("Location: #{location.inspect}")
    # Rails.logger.debug("Beer info in email: #{beers.inspect}")
    template_name = "new-beers-email"
    template_content = []
    message = {
      merge: true,
      merge_language: "handlebars",
      to: [
        {:email => "tinez55@hotmail.com"}
      ],
      inline_css: true,
      merge_vars: [
        { rcpt: "tinez55@hotmail.com",
          vars: [
             {name: "location", content: location},
             {name: "beers", content: beers}
           ]
         }
      ]
    }
    mandrill_client.messages.send_template template_name, template_content, message
  end
  
end
