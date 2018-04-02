# -*- encoding: utf-8 -*-
# stub: google_directions 0.1.6.2 ruby lib

Gem::Specification.new do |s|
  s.name = "google_directions".freeze
  s.version = "0.1.6.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Josh Crews".freeze]
  s.date = "2014-02-26"
  s.description = "Ruby-wrapper for Google Directions API.  Can return the drive time and driving distance between to places".freeze
  s.email = "josh@joshcrews.com".freeze
  s.extra_rdoc_files = ["README.textile".freeze, "lib/google_directions.rb".freeze]
  s.files = ["README.textile".freeze, "lib/google_directions.rb".freeze]
  s.homepage = "http://github.com/joshcrews/Google-Directions-Ruby".freeze
  s.rdoc_options = ["--line-numbers".freeze, "--title".freeze, "Google_directions".freeze, "--main".freeze, "README.textile".freeze]
  s.rubyforge_project = "google_directions".freeze
  s.rubygems_version = "2.7.6".freeze
  s.summary = "Ruby-wrapper for Google Directions API.  Can return the drive time and driving distance between to places".freeze

  s.installed_by_version = "2.7.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<nokogiri>.freeze, [">= 1.4.1"])
    else
      s.add_dependency(%q<nokogiri>.freeze, [">= 1.4.1"])
    end
  else
    s.add_dependency(%q<nokogiri>.freeze, [">= 1.4.1"])
  end
end
