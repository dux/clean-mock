# regex, not YAML: requiring yaml here activates the default psych before Bundler pins the app's
version  = File.read(File.expand_path('.version', __dir__))[/^version:[ \t]*(\S+)/, 1]
gem_name = 'clean-mock'

Gem::Specification.new gem_name, version do |gem|
  gem.summary     = 'Ruby object creation helper/mocking lib used for testing.'
  gem.description = 'Clean and efficient ruby testing object creation helper/mocking library with interface similar to FactoryBot'
  gem.authors     = ["Dino Reic"]
  gem.email       = 'reic.dino@gmail.com'
  gem.files       = Dir['./lib/**/*.rb']+['./.version']
  gem.homepage    = 'https://github.com/dux/%s' % gem_name
  gem.license     = 'MIT'

  # gem.add_runtime_dependency 'dry-inflector'
end