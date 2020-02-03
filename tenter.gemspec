# frozen_string_literal: true

require "./lib/tenter/version"

Gem::Specification.new do |s|
  s.name        = "tenter"
  s.version     = Tenter::VERSION
  s.authors     = ["Michael Camilleri"]
  s.email       = ["mike@inqk.net"]
  s.summary     = "A web app for running user-defined commands"
  s.description = <<-desc.strip.gsub(/\s+/, " ")
    Tenter is a Sinatra-based application that provides webhooks for use by
    GitHub.
  desc
  s.homepage    = "https://github.com/pyrmont/tenter/"
  s.licenses    = "Unlicense"
  s.files       = Dir["Gemfile", "LICENSE", "tenter.gemspec", "lib/tenter.rb",
                      "lib/**/*.rb"]

  s.required_ruby_version         = ">= 2.5"
  s.require_paths                 = ["lib"]
  s.metadata["allowed_push_host"] = "https://rubygems.org"

  s.add_runtime_dependency "sinatra", "~> 2.0"
  s.add_runtime_dependency "thin", "~> 1.0"

  s.add_development_dependency "minitest", "~> 5.0"
  s.add_development_dependency "rack-test", "~> 1.0"
  s.add_development_dependency "rake", "~> 13.0"
  s.add_development_dependency "redcarpet", "~> 3.0"
  s.add_development_dependency "yard", "~> 0.0"
end
