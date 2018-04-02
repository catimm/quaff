# -*- encoding: utf-8 -*-
# stub: sorted 2.0.3 ruby lib

Gem::Specification.new do |s|
  s.name = "sorted".freeze
  s.version = "2.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Rufus Post".freeze]
  s.date = "2015-09-17"
  s.description = "Data sorting library, used by other libs to construct queries and more".freeze
  s.email = ["rufuspost@gmail.com".freeze]
  s.homepage = "http://rubygems.org/gems/sorted".freeze
  s.licenses = ["MIT".freeze]
  s.rubyforge_project = "sorted".freeze
  s.rubygems_version = "2.7.6".freeze
  s.summary = "Data sorting library".freeze

  s.installed_by_version = "2.7.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<bundler>.freeze, [">= 1.0.0"])
      s.add_development_dependency(%q<rspec>.freeze, [">= 2.0.0"])
      s.add_development_dependency(%q<rubocop>.freeze, [">= 0.28"])
    else
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<bundler>.freeze, [">= 1.0.0"])
      s.add_dependency(%q<rspec>.freeze, [">= 2.0.0"])
      s.add_dependency(%q<rubocop>.freeze, [">= 0.28"])
    end
  else
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<bundler>.freeze, [">= 1.0.0"])
    s.add_dependency(%q<rspec>.freeze, [">= 2.0.0"])
    s.add_dependency(%q<rubocop>.freeze, [">= 0.28"])
  end
end
