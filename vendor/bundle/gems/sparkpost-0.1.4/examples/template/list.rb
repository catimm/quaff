#!/usr/bin/env ruby

require_relative '../../lib/sparkpost'

sp = SparkPost::Client.new # api key was set in ENV
templates = sp.template.list

puts templates
