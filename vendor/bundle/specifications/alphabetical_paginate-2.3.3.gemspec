# -*- encoding: utf-8 -*-
# stub: alphabetical_paginate 2.3.3 ruby lib

Gem::Specification.new do |s|
  s.name = "alphabetical_paginate".freeze
  s.version = "2.3.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["lingz".freeze]
  s.date = "2018-02-20"
  s.description = "Alphabetical Pagination".freeze
  s.email = ["lz781@nyu.edu".freeze]
  s.homepage = "https://github.com/lingz/alphabetical_paginate".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.7.6".freeze
  s.summary = "Pagination".freeze

  s.installed_by_version = "2.7.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.3"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 2.6"])
      s.add_development_dependency(%q<rails>.freeze, [">= 0"])
    else
      s.add_dependency(%q<bundler>.freeze, ["~> 1.3"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 2.6"])
      s.add_dependency(%q<rails>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 1.3"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 2.6"])
    s.add_dependency(%q<rails>.freeze, [">= 0"])
  end
end
