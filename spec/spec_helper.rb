require 'awesome_print'
require 'faker'

unless ''.respond_to?(:classify)
  require 'dry/inflector'

  class String
    def classify;     Dry::Inflector.new.classify self; end
    def constantize;  Dry::Inflector.new.constantize self; end
    def singularize; Dry::Inflector.new.singularize self; end
  end
end

require './lib/clean-mock'

require_relative './fixtures/models'
require_relative './fixtures/mocks'

class Object
  def rr data
    puts '- start: %s' % data.inspect
    ap data
    puts '- end'
  end
end

# basic config
RSpec.configure do |config|
  # Use color in STDOUT
  config.color = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :json, CustomFormatterClass
end


