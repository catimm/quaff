# -*- encoding: utf-8 -*-
# stub: bootstrap-select-rails 1.12.4 ruby lib

Gem::Specification.new do |s|
  s.name = "bootstrap-select-rails".freeze
  s.version = "1.12.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Maciej Krajowski-Kukiel".freeze]
  s.date = "2017-12-20"
  s.description = "assets for bootstrap-select".freeze
  s.email = ["maciej.krajowski@gmail.com".freeze]
  s.homepage = "https://github.com/Slashek/bootstrap-select-rails".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.7.6".freeze
  s.summary = "assets for bootstrap-select".freeze

  s.installed_by_version = "2.7.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.3"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    else
      s.add_dependency(%q<bundler>.freeze, ["~> 1.3"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 1.3"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
  end
end
