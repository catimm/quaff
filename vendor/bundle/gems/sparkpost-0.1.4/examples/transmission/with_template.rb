#!/usr/bin/env ruby

require_relative '../../lib/sparkpost'

# prepare the payload as required by SparkPost API endpoint
payload = {
  recipients: [{ address: { email: 'RECIPIENT_EMAIL' } }],
  content: {
    from: 'SENDER_EMAIL',
    subject: 'test email',
    template_id: 'YOUR_TEMPLATE_ID'
  }
}

sp = SparkPost::Client.new # api key was set in ENV
response = sp.transmission.send_payload(payload)

puts response
