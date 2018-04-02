# -*- encoding: utf-8 -*-
# stub: gon 5.2.3 ruby lib

Gem::Specification.new do |s|
  s.name = "gon".freeze
  s.version = "5.2.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["gazay".freeze]
  s.date = "2014-11-04"
  s.description = "If you need to send some data to your js files and you don't want to do this with long way trough views and parsing - use this force!".freeze
  s.email = ["alex.gaziev@gmail.com".freeze]
  s.homepage = "https://github.com/gazay/gon".freeze
  s.licenses = ["MIT".freeze]
  s.rubyforge_project = "gon".freeze
  s.rubygems_version = "2.7.6".freeze
  s.summary = "Get your Rails variables in your JS".freeze

  s.installed_by_version = "2.7.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<actionpack>.freeze, [">= 2.3.0"])
      s.add_runtime_dependency(%q<request_store>.freeze, [">= 1.0.5"])
      s.add_runtime_dependency(%q<json>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<multi_json>.freeze, [">= 0"])
      s.add_development_dependency(%q<rabl>.freeze, [">= 0"])
      s.add_development_dependency(%q<rabl-rails>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
      s.add_development_dependency(%q<jbuilder>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    else
      s.add_dependency(%q<actionpack>.freeze, [">= 2.3.0"])
      s.add_dependency(%q<request_store>.freeze, [">= 1.0.5"])
      s.add_dependency(%q<json>.freeze, [">= 0"])
      s.add_dependency(%q<multi_json>.freeze, [">= 0"])
      s.add_dependency(%q<rabl>.freeze, [">= 0"])
      s.add_dependency(%q<rabl-rails>.freeze, [">= 0"])
      s.add_dependency(%q<rspec>.freeze, [">= 0"])
      s.add_dependency(%q<jbuilder>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<actionpack>.freeze, [">= 2.3.0"])
    s.add_dependency(%q<request_store>.freeze, [">= 1.0.5"])
    s.add_dependency(%q<json>.freeze, [">= 0"])
    s.add_dependency(%q<multi_json>.freeze, [">= 0"])
    s.add_dependency(%q<rabl>.freeze, [">= 0"])
    s.add_dependency(%q<rabl-rails>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<jbuilder>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
  end
end
