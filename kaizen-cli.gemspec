Gem::Specification.new do |s|
  s.name        = 'kaizen-cli'
  s.version     = '0.1.0'
  s.date        = '2016-06-06'
  s.summary     = 'Kaizen CLI is the command line tool for the Kaizen framework'
  s.description = 'Kaizen is a simple-as-possible responsive Sass framework.'
  s.authors     = ['Nico Van Zyl', 'Sean Nieuwoudt']
  s.email       = 'team@wixelhq.com'
  s.files       = `git ls-files -z`.split("\x0")
  s.license     = 'MIT'
  s.homepage    = 'https://github.com/Wixel/Kaizen'
  s.executables << 'kzn'
  s.require_paths = ['lib']

  s.add_runtime_dependency 'minitest', '~> 5.7', '>= 5.7.0'
  s.add_runtime_dependency 'rake', '~> 10.4', '>= 10.4.2'
  s.add_runtime_dependency 'bundler', '~> 1.7'
  s.add_runtime_dependency 'zip-zip', '~> 0.3'
  s.add_runtime_dependency 'rubyzip', '~> 1.2', '>= 1.2.0'
  s.add_runtime_dependency 'paint', '~> 1.0', '>= 1.0.1'
  s.add_runtime_dependency 'sass', '~> 3.4', '>= 3.4.22'
  s.add_runtime_dependency 'bourbon', '~> 4.2', '>= 4.2.7'
  s.add_development_dependency 'rubocop', '~> 0.40', '>= 0.40.0'

end
