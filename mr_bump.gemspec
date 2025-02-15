Gem::Specification.new do |s|
  s.name               = 'mr_bump'
  s.version            = '0.3.11'
  s.licenses           = ['MPL-2.0']
  s.default_executable = 'mr_bump'
  s.executables        = ['mr_bump']

  if s.respond_to? :required_rubygems_version=
    s.required_rubygems_version = Gem::Requirement.new('>= 0')
  end

  s.authors = ['Richard Fitzgerald', 'Josh Bryant', 'Lukasz Ozimek']
  s.date = '2016-08-18'
  s.description = 'Bump versions'
  s.email = ['richard.fitzgerald36@gmail.com', 'ozim10@gmail.com']
  s.files = [
    'lib/mr_bump.rb', 'lib/mr_bump/version.rb', 'lib/mr_bump/slack.rb', 'lib/mr_bump/config.rb',
    'bin/mr_bump', 'lib/mr_bump/git_config.rb', 'lib/mr_bump/git_api.rb', 'lib/mr_bump/change.rb',
    'lib/mr_bump/regex_template.rb', 'defaults.yml'
  ]
  s.test_files = Dir['spec/**/*']
  s.homepage = 'https://github.com/ozimeu/mr_bump'
  s.require_paths = ['lib']
  s.rubygems_version = '1.6.2'
  s.summary = 'BUMP!'
  s.add_dependency 'slack-notifier', '~> 1.0'
  s.add_dependency 'octokit', ['>= 3.0', '<= 5.0']
  s.add_dependency 'mustache', ['>= 0.99.3', '< 2.0']
  s.add_dependency 'OptionParser'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rb-readline'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'json', '~> 1.8'
  s.add_development_dependency 'tins', '~> 1.6.0'
  s.add_development_dependency 'term-ansicolor', '~>1.3.1'
  s.add_development_dependency 'coveralls'

  s.specification_version = 3 if s.respond_to? :specification_version
end
