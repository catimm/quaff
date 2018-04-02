# -*- encoding: utf-8 -*-
# stub: maxminddb 0.1.15 ruby lib

Gem::Specification.new do |s|
  s.name = "maxminddb".freeze
  s.version = "0.1.15"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["yhirose".freeze]
  s.date = "2017-12-19"
  s.description = "Pure Ruby MaxMind DB (GeoIP2) binary file reader.".freeze
  s.email = ["yuji.hirose.bug@gmail.com".freeze]
  s.homepage = "https://github.com/yhirose/maxminddb".freeze
  s.licenses = ["MIT".freeze]
  s.post_install_message = "MIT".freeze
  s.rubygems_version = "2.7.6".freeze
  s.summary = "MaxMind DB binary file reader.".freeze

  s.installed_by_version = "2.7.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.5"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec-its>.freeze, [">= 0"])
    else
      s.add_dependency(%q<bundler>.freeze, ["~> 1.5"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<rspec>.freeze, [">= 0"])
      s.add_dependency(%q<rspec-its>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 1.5"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<rspec-its>.freeze, [">= 0"])
  end
end
