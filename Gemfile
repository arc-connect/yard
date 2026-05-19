# frozen_string_literal: true
source 'https://rubygems.org'

group :development do
  gem 'rspec'
  gem 'rake'
  gem 'rdoc', RUBY_VERSION < '2.7.0' ? '~> 6.0' : nil
  gem 'json'
  gem 'simplecov' if RUBY_VERSION >= '2.7.0'
  gem 'coveralls_reborn', :require => false if RUBY_VERSION >= '2.7.0'
  gem 'webrick'
end

group :asciidoc do
  gem 'logger' if RUBY_VERSION >= '2.3.0'
  gem 'asciidoctor'
end

group :markdown do
  gem 'redcarpet'
  gem 'commonmarker'
end

group :textile do
  gem 'RedCloth'
end

group :server do
  gem 'rackup' if RUBY_VERSION >= '2.6.0'
  gem 'rack', '~> 2.0' if RUBY_VERSION < '2.6.0'
end

group :i18n do
  gem 'gettext'
end
