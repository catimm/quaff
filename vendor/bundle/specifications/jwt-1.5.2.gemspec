# -*- encoding: utf-8 -*-
# stub: jwt 1.5.2 ruby lib

Gem::Specification.new do |s|
  s.name = "jwt".freeze
  s.version = "1.5.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jeff Lindsay".freeze]
  s.date = "2015-10-27"
  s.description = "JSON Web Token implementation in Ruby".freeze
  s.email = "progrium@gmail.com".freeze
  s.extra_rdoc_files = ["README.md".freeze, "LICENSE".freeze, "lib/jwt.rb".freeze, "lib/jwt/json.rb".freeze]
  s.files = ["LICENSE".freeze, "README.md".freeze, "lib/jwt.rb".freeze, "lib/jwt/json.rb".freeze]
  s.homepage = "http://github.com/progrium/ruby-jwt".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--line-numbers".freeze, "--title".freeze, "Jwt".freeze, "--main".freeze, "README.md".freeze]
  s.rubyforge_project = "jwt".freeze
  s.rubygems_version = "2.7.6".freeze
  s.summary = "JSON Web Token implementation in Ruby".freeze

  s.installed_by_version = "2.7.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<echoe>.freeze, [">= 4.6.3"])
    else
      s.add_dependency(%q<echoe>.freeze, [">= 4.6.3"])
    end
  else
    s.add_dependency(%q<echoe>.freeze, [">= 4.6.3"])
  end
end
