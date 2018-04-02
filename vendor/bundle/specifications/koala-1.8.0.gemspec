# -*- encoding: utf-8 -*-
# stub: koala 1.8.0 ruby lib

Gem::Specification.new do |s|
  s.name = "koala".freeze
  s.version = "1.8.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Alex Koppel".freeze]
  s.date = "2014-01-23"
  s.description = "Koala is a lightweight, flexible Ruby SDK for Facebook.  It allows read/write access to the social graph via the Graph and REST APIs, as well as support for realtime updates and OAuth and Facebook Connect authentication.  Koala is fully tested and supports Net::HTTP and Typhoeus connections out of the box and can accept custom modules for other services.".freeze
  s.email = "alex@alexkoppel.com".freeze
  s.extra_rdoc_files = ["readme.md".freeze, "changelog.md".freeze]
  s.files = ["changelog.md".freeze, "readme.md".freeze]
  s.homepage = "http://github.com/arsduo/koala".freeze
  s.rdoc_options = ["--line-numbers".freeze, "--inline-source".freeze, "--title".freeze, "Koala".freeze]
  s.rubygems_version = "2.7.6".freeze
  s.summary = "A lightweight, flexible library for Facebook with support for the Graph API, the REST API, realtime updates, and OAuth authentication.".freeze

  s.installed_by_version = "2.7.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<multi_json>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<faraday>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<addressable>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    else
      s.add_dependency(%q<multi_json>.freeze, [">= 0"])
      s.add_dependency(%q<faraday>.freeze, [">= 0"])
      s.add_dependency(%q<addressable>.freeze, [">= 0"])
      s.add_dependency(%q<rspec>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<multi_json>.freeze, [">= 0"])
    s.add_dependency(%q<faraday>.freeze, [">= 0"])
    s.add_dependency(%q<addressable>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
  end
end
