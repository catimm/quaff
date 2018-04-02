# -*- encoding: utf-8 -*-
# stub: bootstrap-modal-rails 2.2.5 ruby lib

Gem::Specification.new do |s|
  s.name = "bootstrap-modal-rails".freeze
  s.version = "2.2.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Vicente Reig".freeze]
  s.date = "2014-04-29"
  s.description = "Rails gemified bootstrap-modal extension".freeze
  s.email = ["vicente.reig@gmail.com".freeze]
  s.homepage = "http://github.com/vicentereig/bootstrap-modal-rails".freeze
  s.rubygems_version = "2.7.6".freeze
  s.summary = "Rails gemified bootstrap-modal extension by Jordan Schroter.".freeze

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
