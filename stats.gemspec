# frozen_string_literal: true
#
require_relative 'lib/stats/version'

Gem::Specification.new do |spec|
  spec.name        = 'stats'
  spec.version     = Stats::VERSION
  spec.required_ruby_version = '>= 3.2.2'
  spec.authors     = ['Andrey Eremeev']
  spec.email       = ['andrey@hexopay.com']
  spec.homepage    = 'https://github.com/hexopay/stats'
  spec.summary     = 'Implement Stats to update elastic'
  spec.description = 'Implement Stats to update elastic'
  spec.license     = 'MIT'
  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://rubygems.org'
  spec.metadata['changelog_uri'] = 'https://rubygems.org'
  spec.files = Dir['{app,config,db,lib}/**/*',
                   'MIT-LICENSE', 'Rakefile', 'README.md']

  spec.executables << 'stats'
end
