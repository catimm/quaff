<a href="https://www.sparkpost.com"><img src="https://www.sparkpost.com/sites/default/files/attachments/SparkPost_Logo_2-Color_Gray-Orange_RGB.svg" width="200px"/></a>

[Sign up](https://app.sparkpost.com/sign-up?src=Dev-Website&sfdcid=70160000000pqBb) for a SparkPost account and visit our [Developer Hub](https://developers.sparkpost.com) for even more content.

# SparkPost Ruby API Client

[![Travis CI](https://travis-ci.org/SparkPost/ruby-sparkpost.svg?branch=master)](https://travis-ci.org/SparkPost/ruby-sparkpost) [![Coverage Status](https://coveralls.io/repos/SparkPost/ruby-sparkpost/badge.svg?branch=master&service=github)](https://coveralls.io/github/SparkPost/ruby-sparkpost?branch=master) [![Slack Status](http://slack.sparkpost.com/badge.svg)](http://slack.sparkpost.com)

The official Ruby client library for SparkPost

## Installation

Add this line to your application's Gemfile:

    gem 'sparkpost'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sparkpost

**Important: Implementations may change frequently until we reach v1.0.0**

## Usage

**Send an email**

```ruby
require 'sparkpost'

sp = SparkPost::Client.new() # api key was set in ENV through ENV['SPARKPOST_API_KEY']
response = sp.transmission.send_message('RECIPIENT_EMAIL', 'SENDER_EMAIL', 'test email', '<h1>HTML message</h1>')
puts response

# {"total_rejected_recipients"=>0, "total_accepted_recipients"=>1, "id"=>"123456789123456789"}
```

**Send email with substitution data**

```ruby
require 'sparkpost'

values = { substitution_data: { name: 'Sparky'}}
sp = SparkPost::Client.new() # pass api key or get api key from ENV
response = sp.transmission.send_message('RECIPIENT_EMAIL', 'SENDER_EMAIL', 'testemail', '<h1>HTML message from {{name}}</h1>', values)
puts response

# {"total_rejected_recipients"=>0, "total_accepted_recipients"=>1, "id"=>"123456789123456789"}
```

**Send email with attachment**

*You need to base64 encode of your attachment contents.*

```ruby
require 'sparkpost'

# assuming there is a file named attachment.txt in the same directory
attachment = Base64.encode64(File.open(File.expand_path('../attachment.txt', __FILE__), 'r') { |f| f.read })

# prepare attachment data to pass to send_message method
values = {
    attachments: [{
        name: 'attachment.txt',
        type: 'text/plain',
        data: attachment
    }]
}

sp = SparkPost::Client.new() # pass api key or get api key from ENV
sp.transmission.send_message('RECIPIENT_EMAIL', 'SENDER_EMAIL', 'testemail', '<h1>Email with an attachment</h1>', values)
```

See: [examples](examples)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( http://github.com/<my-github-username>ruby-sparkpost/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
