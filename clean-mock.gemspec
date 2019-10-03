version  = File.read File.expand_path '.version', File.dirname(__FILE__)
gem_name = 'clean-mock'

Gem::Specification.new gem_name, version do |gem|
  gem.summary     = 'Ruby testing object creation helper/mocking lib'
  gem.description = 'Clean and efficient ruby testing object creation helper/mocking library with interface similar to FactoryBot'
  gem.authors     = ["Dino Reic"]
  gem.email       = 'reic.dino@gmail.com'
  gem.files       = Dir['./lib/**/*.rb']+['./.version']
  gem.homepage    = 'https://github.com/dux/%s' % gem_name
  gem.license     = 'MIT'
end