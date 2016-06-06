Gem::Specification.new do |s|
  s.name        = "kaizen-cli"
  s.version     = "0.0.1"
  s.date        = "2016-06-06"
  s.summary     = "Kaizen CLI is a utility that allows you to easily install the latest Kaizen front end framework"
  s.description = "Kaizen is a simple-as-possible responsive Sass (built with Bourbon) starter framework with just the right amount of features to get a project started in minutes."
  s.authors     = ["Sean Nieuwoudt", "Nico Van Zyl"]
  s.email       = "sean@wixelhq.com"
  s.files       = `git ls-files -z`.split("\x0")
  s.license     = "MIT"
  s.homepage    = 'https://wixelhq.com'
  s.executables << 'kzn'
  s.require_paths = ["lib"]

  s.add_development_dependency 'minitest', '~> 5.7', '>= 5.7.0'
  s.add_development_dependency 'rake', '~> 10.4', '>= 10.4.2'
  s.add_development_dependency 'bundler', '~> 1.7'
  s.add_development_dependency 'rubyzip', '~> 1.2', '>= 1.2.0'
  s.add_development_dependency 'paint', '~> 1.0', '>= 1.0.1'
  s.add_development_dependency 'sass', '~> 3.4', '>= 3.4.22'
  s.add_development_dependency 'rubocop', '~> 0.40', '>= 0.40.0'
end
