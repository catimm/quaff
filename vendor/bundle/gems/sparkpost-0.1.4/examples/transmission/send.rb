#!/usr/bin/env ruby

require_relative '../../lib/sparkpost'

sp = SparkPost::Client.new # api key was set in ENV
response = sp.transmission.send_message(
    'RECIPIENT_EMAIL',
    'SENDER_EMAIL',
    'test email',
    '<h1>HTML message</h1>')

puts response
