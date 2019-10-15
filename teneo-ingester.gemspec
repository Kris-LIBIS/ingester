# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'teneo/ingester/version'

Gem::Specification.new do |spec|
  spec.name          = 'teneo-ingester'
  spec.version       = Teneo::Ingester::VERSION
  spec.authors       = ['Kris Dekeyser']
  spec.email         = ['kris.dekeyser@libis.be']

  spec.summary       = 'Ingester core for Teneo.'
  spec.description   = 'This is the part that will run the jobs and follow up on them.'
  spec.homepage      = 'http://teneo.libis.be'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'

    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://gihub.com/Kris-LIBIS/TeneoIngester'
    spec.metadata['changelog_uri'] = 'https://gihub.com/Kris-LIBIS/TeneoIngester/changes.md'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'

  spec.add_runtime_dependency 'libis-tools', '~> 1.0'
  spec.add_runtime_dependency 'libis-format', '~> 2.0'
  spec.add_runtime_dependency 'teneo-data_model', '~> 0.2'
  spec.add_runtime_dependency 'libis-workflow', '~> 3.0.beta'
  spec.add_runtime_dependency 'sidekiq', '~> 5.2'
  spec.add_runtime_dependency 'dotenv', '~> 2.7'
  # spec.add_runtime_dependency 'dynflow', '~> 1.2'
end
