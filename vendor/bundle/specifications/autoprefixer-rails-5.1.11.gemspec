# -*- encoding: utf-8 -*-
# stub: autoprefixer-rails 5.1.11 ruby lib

Gem::Specification.new do |s|
  s.name = "autoprefixer-rails".freeze
  s.version = "5.1.11"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andrey Sitnik".freeze]
  s.date = "2015-04-20"
  s.email = "andrey@sitnik.ru".freeze
  s.extra_rdoc_files = ["README.md".freeze, "LICENSE".freeze, "ChangeLog.md".freeze]
  s.files = ["ChangeLog.md".freeze, "LICENSE".freeze, "README.md".freeze]
  s.homepage = "https://github.com/ai/autoprefixer-rails".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.7.6".freeze
  s.summary = "Parse CSS and add vendor prefixes to CSS rules using values from the Can I Use website.".freeze

  s.installed_by_version = "2.7.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<execjs>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<json>.freeze, [">= 0"])
    else
      s.add_dependency(%q<execjs>.freeze, [">= 0"])
      s.add_dependency(%q<json>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<execjs>.freeze, [">= 0"])
    s.add_dependency(%q<json>.freeze, [">= 0"])
  end
end
