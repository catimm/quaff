# -*- encoding: utf-8 -*-
# stub: securecompare 1.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "securecompare".freeze
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Samuel Kadolph".freeze]
  s.date = "2013-05-07"
  s.description = "securecompare borrows the secure_compare private method from ActiveSupport::MessageVerifier which lets you do safely compare strings without being vulnerable to timing attacks. Useful for Basic HTTP Authentication in your rack/rails application.".freeze
  s.email = ["samuel@kadolph.com".freeze]
  s.homepage = "https://github.com/samuelkadolph/securecompare".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "2.7.6".freeze
  s.summary = "securecompare is a gem that implements a constant time string comparison method safe for use in cryptographic functions.".freeze

  s.installed_by_version = "2.7.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

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
