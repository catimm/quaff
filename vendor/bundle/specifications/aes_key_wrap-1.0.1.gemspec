# -*- encoding: utf-8 -*-
# stub: aes_key_wrap 1.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "aes_key_wrap".freeze
  s.version = "1.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Tom Dalling".freeze]
  s.date = "2015-04-24"
  s.email = ["tom@tomdalling.com".freeze]
  s.homepage = "https://github.com/tomdalling/aes_key_wrap".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.7.6".freeze
  s.summary = "A Ruby implementation of AES Key Wrap, a.k.a RFC 3394, a.k.a NIST Key Wrap.".freeze

  s.installed_by_version = "2.7.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.2.0"])
    else
      s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.2.0"])
    end
  else
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.2.0"])
  end
end
