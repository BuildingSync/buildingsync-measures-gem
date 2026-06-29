
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'openstudio/buildingsync_measures/version'

Gem::Specification.new do |spec|
  spec.name          = 'buildingsync-measures'
  spec.version       = OpenStudio::BuildingsyncMeasures::VERSION
  spec.authors       = ['Jie Xiong', 'Katherine Fleming']
  spec.email         = ['jie.xiong@nlr.gov', 'katherine.fleming@nlr.gov']

  spec.summary       = 'Library and measures for BuildingSync to OpenStudio Workflow'
  spec.description   = 'Library and measures for BuildingSync to OpenStudio Workflow'
  spec.homepage      = 'https://openstudio.net'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '~> 3.2.2'

  spec.add_dependency 'bundler', '~> 2.4.10'
  spec.add_dependency 'openstudio-extension', '~> 0.9.4'
  spec.add_dependency 'openstudio-standards', '0.8.2'

  spec.add_development_dependency 'rubocop', '1.50'
  spec.add_development_dependency 'rubocop-checkstyle_formatter', '0.6.0'
  spec.add_development_dependency 'rubocop-performance', '1.20.0'
  spec.add_development_dependency 'simplecov', '0.22.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.9'

end
