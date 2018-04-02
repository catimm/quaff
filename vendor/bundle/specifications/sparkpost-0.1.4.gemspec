# -*- encoding: utf-8 -*-
# stub: sparkpost 0.1.4 ruby lib

Gem::Specification.new do |s|
  s.name = "sparkpost".freeze
  s.version = "0.1.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["SparkPost".freeze, "Aimee Knight".freeze, "Mohammad Hossain".freeze]
  s.date = "2016-04-19"
  s.email = "developers@sparkpost.com".freeze
  s.executables = ["console".freeze, "setup".freeze]
  s.files = ["bin/console".freeze, "bin/setup".freeze]
  s.homepage = "https://github.com/SparkPost/ruby-sparkpost".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.rubygems_version = "2.7.6".freeze
  s.summary = "SparkPost Ruby API client".freeze

  s.installed_by_version = "2.7.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<http>.freeze, ["= 0.9.8"])
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.5"])
      s.add_development_dependency(%q<rake>.freeze, ["< 11"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.3.0"])
      s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.11.1"])
      s.add_development_dependency(%q<webmock>.freeze, ["~> 1.22.3"])
      s.add_development_dependency(%q<coveralls>.freeze, [">= 0"])
      s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.37.2"])
    else
      s.add_dependency(%q<http>.freeze, ["= 0.9.8"])
      s.add_dependency(%q<bundler>.freeze, ["~> 1.5"])
      s.add_dependency(%q<rake>.freeze, ["< 11"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.3.0"])
      s.add_dependency(%q<simplecov>.freeze, ["~> 0.11.1"])
      s.add_dependency(%q<webmock>.freeze, ["~> 1.22.3"])
      s.add_dependency(%q<coveralls>.freeze, [">= 0"])
      s.add_dependency(%q<rubocop>.freeze, ["~> 0.37.2"])
    end
  else
    s.add_dependency(%q<http>.freeze, ["= 0.9.8"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.5"])
    s.add_dependency(%q<rake>.freeze, ["< 11"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.3.0"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.11.1"])
    s.add_dependency(%q<webmock>.freeze, ["~> 1.22.3"])
    s.add_dependency(%q<coveralls>.freeze, [">= 0"])
    s.add_dependency(%q<rubocop>.freeze, ["~> 0.37.2"])
  end
end
