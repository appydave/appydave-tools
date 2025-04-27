# frozen_string_literal: true

require_relative 'lib/appydave/tools/version'

Gem::Specification.new do |spec|
  spec.required_ruby_version  = '>= 2.7'
  spec.name                   = 'appydave-tools'
  spec.version                = Appydave::Tools::VERSION
  spec.authors                = ['David Cruwys']
  spec.email                  = ['david@ideasmen.com.au']

  spec.summary                = 'AppyDave YouTube Automation Tools'
  spec.description            = <<-TEXT
    AppyDave YouTube Automation Tools
  TEXT
  spec.homepage               = 'http://appydave.com/gems/appydave-tools'
  spec.license                = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.' unless spec.respond_to?(:metadata)

  # spec.metadata['allowed_push_host'] = "Set to 'http://mygemserver.com'"

  spec.metadata['homepage_uri']           = spec.homepage
  spec.metadata['source_code_uri']        = 'https://github.com/appydave/appydave-tools'
  spec.metadata['changelog_uri']          = 'https://github.com/appydave/appydave-tools/blob/main/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required']  = 'true'

  # The `git ls-files -z` loads the RubyGem files that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  # spec.extensions    = ['ext/appydave_tools/extconf.rb']

  spec.add_dependency 'activemodel', '~> 8'
  spec.add_dependency 'clipboard', '~> 2'
  spec.add_dependency 'csv', '~> 3'
  spec.add_dependency 'dotenv', '~> 3'
  spec.add_dependency 'google-api-client', '~> 0.53' # open code: gemo google-api-client
  spec.add_dependency 'i18n', '~> 1.14'
  spec.add_dependency 'k_log', '~> 0'
  spec.add_dependency 'ruby-openai', '~> 8'
  spec.add_dependency 'googleauth'
  spec.add_dependency 'webrick'

  # spec.add_dependency 'k_type', '~> 0'
  # spec.add_dependency 'k_util', '~> 0'
end
