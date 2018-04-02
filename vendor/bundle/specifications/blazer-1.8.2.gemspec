# -*- encoding: utf-8 -*-
# stub: blazer 1.8.2 ruby lib

Gem::Specification.new do |s|
  s.name = "blazer".freeze
  s.version = "1.8.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andrew Kane".freeze]
  s.date = "2018-02-22"
  s.email = ["andrew@chartkick.com".freeze]
  s.homepage = "https://github.com/ankane/blazer".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.7.6".freeze
  s.summary = "Explore your data with SQL. Easily create charts and dashboards, and share them with your team.".freeze

  s.installed_by_version = "2.7.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<railties>.freeze, [">= 4"])
      s.add_runtime_dependency(%q<activerecord>.freeze, [">= 4"])
      s.add_runtime_dependency(%q<chartkick>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<safely_block>.freeze, [">= 0.1.1"])
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.7"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
    else
      s.add_dependency(%q<railties>.freeze, [">= 4"])
      s.add_dependency(%q<activerecord>.freeze, [">= 4"])
      s.add_dependency(%q<chartkick>.freeze, [">= 0"])
      s.add_dependency(%q<safely_block>.freeze, [">= 0.1.1"])
      s.add_dependency(%q<bundler>.freeze, ["~> 1.7"])
      s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    end
  else
    s.add_dependency(%q<railties>.freeze, [">= 4"])
    s.add_dependency(%q<activerecord>.freeze, [">= 4"])
    s.add_dependency(%q<chartkick>.freeze, [">= 0"])
    s.add_dependency(%q<safely_block>.freeze, [">= 0.1.1"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.7"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
  end
end
