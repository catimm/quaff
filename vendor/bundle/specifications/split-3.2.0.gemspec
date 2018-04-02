# -*- encoding: utf-8 -*-
# stub: split 3.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "split".freeze
  s.version = "3.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 2.0.0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/splitrb/split/issues", "changelog_uri" => "https://github.com/splitrb/split/blob/master/CHANGELOG.md", "homepage_uri" => "https://github.com/splitrb/split", "mailing_list_uri" => "https://groups.google.com/d/forum/split-ruby", "source_code_uri" => "https://github.com/splitrb/split", "wiki_uri" => "https://github.com/splitrb/split/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andrew Nesbitt".freeze]
  s.date = "2017-09-21"
  s.email = ["andrewnez@gmail.com".freeze]
  s.homepage = "https://github.com/splitrb/split".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubyforge_project = "split".freeze
  s.rubygems_version = "2.7.6".freeze
  s.summary = "Rack based split testing framework".freeze

  s.installed_by_version = "2.7.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<redis>.freeze, [">= 2.1"])
      s.add_runtime_dependency(%q<sinatra>.freeze, [">= 1.2.6"])
      s.add_runtime_dependency(%q<simple-random>.freeze, [">= 0.9.3"])
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.14"])
      s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.12"])
      s.add_development_dependency(%q<rack-test>.freeze, ["~> 0.6"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 12"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.4"])
      s.add_development_dependency(%q<pry>.freeze, ["~> 0.10"])
      s.add_development_dependency(%q<fakeredis>.freeze, ["~> 0.6.0"])
    else
      s.add_dependency(%q<redis>.freeze, [">= 2.1"])
      s.add_dependency(%q<sinatra>.freeze, [">= 1.2.6"])
      s.add_dependency(%q<simple-random>.freeze, [">= 0.9.3"])
      s.add_dependency(%q<bundler>.freeze, ["~> 1.14"])
      s.add_dependency(%q<simplecov>.freeze, ["~> 0.12"])
      s.add_dependency(%q<rack-test>.freeze, ["~> 0.6"])
      s.add_dependency(%q<rake>.freeze, ["~> 12"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.4"])
      s.add_dependency(%q<pry>.freeze, ["~> 0.10"])
      s.add_dependency(%q<fakeredis>.freeze, ["~> 0.6.0"])
    end
  else
    s.add_dependency(%q<redis>.freeze, [">= 2.1"])
    s.add_dependency(%q<sinatra>.freeze, [">= 1.2.6"])
    s.add_dependency(%q<simple-random>.freeze, [">= 0.9.3"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.14"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.12"])
    s.add_dependency(%q<rack-test>.freeze, ["~> 0.6"])
    s.add_dependency(%q<rake>.freeze, ["~> 12"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.4"])
    s.add_dependency(%q<pry>.freeze, ["~> 0.10"])
    s.add_dependency(%q<fakeredis>.freeze, ["~> 0.6.0"])
  end
end
