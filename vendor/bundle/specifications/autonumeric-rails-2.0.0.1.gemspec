# -*- encoding: utf-8 -*-
# stub: autonumeric-rails 2.0.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "autonumeric-rails".freeze
  s.version = "2.0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["randoum".freeze]
  s.date = "2017-01-20"
  s.description = "autoNumeric.js library automatically formats currency and numbers. With an ujs flavor it is now directly usable in a rails project. All credits for autoNumeric.js library its-self go to its creator BobKnothe".freeze
  s.email = ["randoum@gmail.com".freeze]
  s.homepage = "https://github.com/randoum/autonumeric-rails".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.7.6".freeze
  s.summary = "autoNumeric.js library with an ujs flavor, ready-to-use for rails.".freeze

  s.installed_by_version = "2.7.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<jquery-rails>.freeze, [">= 2.0.2"])
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.3"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<rails>.freeze, ["~> 4.2.0"])
      s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec-rails>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec-html-matchers>.freeze, [">= 0"])
      s.add_development_dependency(%q<database_cleaner>.freeze, [">= 0"])
      s.add_development_dependency(%q<capybara>.freeze, [">= 0"])
      s.add_development_dependency(%q<selenium-webdriver>.freeze, ["= 2.53.4"])
      s.add_development_dependency(%q<headless>.freeze, [">= 0"])
    else
      s.add_dependency(%q<jquery-rails>.freeze, [">= 2.0.2"])
      s.add_dependency(%q<bundler>.freeze, ["~> 1.3"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<rails>.freeze, ["~> 4.2.0"])
      s.add_dependency(%q<sqlite3>.freeze, [">= 0"])
      s.add_dependency(%q<rspec-rails>.freeze, [">= 0"])
      s.add_dependency(%q<rspec-html-matchers>.freeze, [">= 0"])
      s.add_dependency(%q<database_cleaner>.freeze, [">= 0"])
      s.add_dependency(%q<capybara>.freeze, [">= 0"])
      s.add_dependency(%q<selenium-webdriver>.freeze, ["= 2.53.4"])
      s.add_dependency(%q<headless>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<jquery-rails>.freeze, [">= 2.0.2"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.3"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rails>.freeze, ["~> 4.2.0"])
    s.add_dependency(%q<sqlite3>.freeze, [">= 0"])
    s.add_dependency(%q<rspec-rails>.freeze, [">= 0"])
    s.add_dependency(%q<rspec-html-matchers>.freeze, [">= 0"])
    s.add_dependency(%q<database_cleaner>.freeze, [">= 0"])
    s.add_dependency(%q<capybara>.freeze, [">= 0"])
    s.add_dependency(%q<selenium-webdriver>.freeze, ["= 2.53.4"])
    s.add_dependency(%q<headless>.freeze, [">= 0"])
  end
end
