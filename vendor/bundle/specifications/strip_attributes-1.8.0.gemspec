# -*- encoding: utf-8 -*-
# stub: strip_attributes 1.8.0 ruby lib

Gem::Specification.new do |s|
  s.name = "strip_attributes".freeze
  s.version = "1.8.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ryan McGeary".freeze]
  s.date = "2016-06-02"
  s.description = "StripAttributes automatically strips all ActiveRecord model attributes of leading and trailing whitespace before validation. If the attribute is blank, it strips the value to nil.".freeze
  s.email = ["ryan@mcgeary.org".freeze]
  s.homepage = "https://github.com/rmm5t/strip_attributes".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.7.6".freeze
  s.summary = "Whitespace cleanup for ActiveModel attributes".freeze

  s.installed_by_version = "2.7.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activemodel>.freeze, ["< 6.0", ">= 3.0"])
      s.add_development_dependency(%q<active_attr>.freeze, ["~> 0.9"])
      s.add_development_dependency(%q<minitest>.freeze, ["< 6.0", ">= 5.0"])
      s.add_development_dependency(%q<minitest-matchers_vaccine>.freeze, ["~> 1.0"])
      s.add_development_dependency(%q<minitest-reporters>.freeze, [">= 0.14.24"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    else
      s.add_dependency(%q<activemodel>.freeze, ["< 6.0", ">= 3.0"])
      s.add_dependency(%q<active_attr>.freeze, ["~> 0.9"])
      s.add_dependency(%q<minitest>.freeze, ["< 6.0", ">= 5.0"])
      s.add_dependency(%q<minitest-matchers_vaccine>.freeze, ["~> 1.0"])
      s.add_dependency(%q<minitest-reporters>.freeze, [">= 0.14.24"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<activemodel>.freeze, ["< 6.0", ">= 3.0"])
    s.add_dependency(%q<active_attr>.freeze, ["~> 0.9"])
    s.add_dependency(%q<minitest>.freeze, ["< 6.0", ">= 5.0"])
    s.add_dependency(%q<minitest-matchers_vaccine>.freeze, ["~> 1.0"])
    s.add_dependency(%q<minitest-reporters>.freeze, [">= 0.14.24"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
  end
end
