#!/usr/bin/env ruby

require 'base64'
require_relative '../../lib/sparkpost'

# read file and base64 encoding
attachment = Base64.encode64(
        File.open(File.expand_path('../attachment.txt', __FILE__), 'r', &:read))

# prepare attachment data to pass to send_message method
options = {
  attachments: [{
    name: 'Sparky.txt',
    type: 'text/plain',
    data: attachment
  }]
}

sp = SparkPost::Client.new # pass api key or get api key from ENV

# send message with attachment
response = sp.transmission.send_message(
    'RECIPIENT_EMAIL',
    'SENDER_EMAIL',
    'test email',
    '<h1>Message with attachment</h1>',
    options)

puts response
