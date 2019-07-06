# frozen_string_literal: true

require './lib/tenter/version'

Gem::Specification.new do |s|
  s.name = "tenter"
  s.version = Tenter.version
  s.authors = ["Michael Camilleri"]
  s.email = ["mike@inqk.net"]
  s.summary = "A simple application providing webhooks"
  s.description = <<-desc.strip.gsub(/\s+/, ' ')
    Tenter is a Sinatra-based application that provides webhooks for use by
    GitHub.
  desc
  s.homepage = "https://github.com/pyrmont/tenter/"
  s.files = Dir['Gemfile', 'LICENSE', 'tenter.gemspec', 'lib/**/*.rb',
                'lib/**/*.yml', 'bin/tenter']
  s.licenses = "Unlicense"
  s.required_ruby_version = '>= 2.5'
  
  s.metadata['allowed_push_host'] = 'https://rubygems.org'

  s.add_runtime_dependency "sinatra", "~> 2.0"
  s.add_runtime_dependency "thin", "~> 1.7"

  s.add_development_dependency "minitest", "~> 5.11"
  s.add_development_dependency "rack-test", "~> 1.1"
  s.add_development_dependency "rake", "~> 12.3"
end
