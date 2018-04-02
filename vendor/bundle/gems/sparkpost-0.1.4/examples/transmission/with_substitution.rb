#!/usr/bin/env ruby

require_relative '../../lib/sparkpost'

values = { substitution_data: { name: 'Sparky' } }
sp = SparkPost::Client.new # pass api key or get api key from ENV
response = sp.transmission.send_message(
    'RECIPIENT_EMAIL',
    'SENDER_EMAIL',
    'test email',
    '<h1>HTML message from {{name}}</h1>',
    values)

puts response
