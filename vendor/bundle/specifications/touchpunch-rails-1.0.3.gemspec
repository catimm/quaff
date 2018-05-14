# -*- encoding: utf-8 -*-
# stub: touchpunch-rails 1.0.3 ruby lib

Gem::Specification.new do |s|
  s.name = "touchpunch-rails".freeze
  s.version = "1.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Geo".freeze]
  s.date = "2014-07-03"
  s.description = "Simple asset gem containing jquery mobile ui touch punch. This allows for enabling touch drag and drop for jquery sortable.".freeze
  s.email = ["geo.marshall@gmail.com".freeze]
  s.homepage = "".freeze
  s.rubygems_version = "2.7.6".freeze
  s.summary = "Simple asset gem containing jquery mobile ui touch punch.".freeze

  s.installed_by_version = "2.7.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<railties>.freeze, [">= 3.1"])
    else
      s.add_dependency(%q<railties>.freeze, [">= 3.1"])
    end
  else
    s.add_dependency(%q<railties>.freeze, [">= 3.1"])
  end
end
