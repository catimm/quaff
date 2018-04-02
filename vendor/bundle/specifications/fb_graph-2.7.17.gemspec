# -*- encoding: utf-8 -*-
# stub: fb_graph 2.7.17 ruby lib

Gem::Specification.new do |s|
  s.name = "fb_graph".freeze
  s.version = "2.7.17"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["nov matake".freeze]
  s.date = "2014-10-16"
  s.description = "A full-stack Facebook Graph API wrapper in Ruby.".freeze
  s.email = "nov@matake.jp".freeze
  s.extra_rdoc_files = ["LICENSE".freeze, "README.rdoc".freeze]
  s.files = ["LICENSE".freeze, "README.rdoc".freeze]
  s.homepage = "http://github.com/nov/fb_graph".freeze
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.rubygems_version = "2.7.6".freeze
  s.summary = "A full-stack Facebook Graph API wrapper in Ruby.".freeze

  s.installed_by_version = "2.7.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<httpclient>.freeze, [">= 2.4"])
      s.add_runtime_dependency(%q<rack-oauth2>.freeze, [">= 0.14.4"])
      s.add_runtime_dependency(%q<tzinfo>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<multi_json>.freeze, [">= 1.3"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0.8"])
      s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec>.freeze, ["< 2.99"])
      s.add_development_dependency(%q<fb_graph-mock>.freeze, [">= 1.0.3"])
      s.add_development_dependency(%q<actionpack>.freeze, [">= 3.0.6"])
    else
      s.add_dependency(%q<httpclient>.freeze, [">= 2.4"])
      s.add_dependency(%q<rack-oauth2>.freeze, [">= 0.14.4"])
      s.add_dependency(%q<tzinfo>.freeze, [">= 0"])
      s.add_dependency(%q<multi_json>.freeze, [">= 1.3"])
      s.add_dependency(%q<rake>.freeze, [">= 0.8"])
      s.add_dependency(%q<simplecov>.freeze, [">= 0"])
      s.add_dependency(%q<rspec>.freeze, ["< 2.99"])
      s.add_dependency(%q<fb_graph-mock>.freeze, [">= 1.0.3"])
      s.add_dependency(%q<actionpack>.freeze, [">= 3.0.6"])
    end
  else
    s.add_dependency(%q<httpclient>.freeze, [">= 2.4"])
    s.add_dependency(%q<rack-oauth2>.freeze, [">= 0.14.4"])
    s.add_dependency(%q<tzinfo>.freeze, [">= 0"])
    s.add_dependency(%q<multi_json>.freeze, [">= 1.3"])
    s.add_dependency(%q<rake>.freeze, [">= 0.8"])
    s.add_dependency(%q<simplecov>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, ["< 2.99"])
    s.add_dependency(%q<fb_graph-mock>.freeze, [">= 1.0.3"])
    s.add_dependency(%q<actionpack>.freeze, [">= 3.0.6"])
  end
end
