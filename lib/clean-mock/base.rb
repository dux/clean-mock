class CleanMock
  attr_reader :model

  @@fetched   ||= {}
  @@mock_data ||= {}
  @@sequence  ||= {}
  @@classes   ||= {}

  class << self
    # defined mocked model
    def define name, opts={}, &block
      @@mock_data[name] = [block, opts]
    end

    def attributes_for *args
      build(*args).attributes.select{ |k,v| v.present? }
    end

    # create a new model without save
    def build *args
      new(*args).model
    end

    # save if responds to save
    def create *args
      build(*args).tap do |model|
        model.save if model.respond_to?(:save)
      end
    end

    # create only once
    def fetch *args, &block
      code = Digest::SHA1.hexdigest(args.to_s)
      @@fetched[code] ||= create(*args, &block)
    end
  end

  ###

  def initialize *args
    opts    = args.last.is_a?(Hash) ? args.pop : {}
    @kind   = args.shift
    @traits = args

    block, mock_opts = @@mock_data[@kind] || raise(ArgumentError, 'Mock model "%s" not defined' % @kind)

    @model =
    case mock_opts[:class]
    when FalseClass
      # define :foo, class: false
      nil
    when NilClass
      # define :foo
      @kind.to_s.classify.constantize.new
    when Symbol
      # define :foo, class: foo
      name = mock_opts[:class].to_s.classify

      if Object.const_defined?(name)
        name.constantize.new
      else
        Object.const_set(name, Class.new).new
      end
    else
      # define :foo, class: FooBar
      mock_opts[:class].new
    end

    if @model
      instance_exec @model, opts, &block
    else
      @model = instance_exec opts, &block
    end

    raise 'Trait [%s] not found' % @traits.join(', ') if @traits.first
  end

  # block to execute and modify model
  def trait name, &block
    if @traits.delete(name)
      instance_exec(@model, &block)
    end
  end

  # define or overlod current instance method
  def func name, &block
    @model.define_singleton_method(name, &block)
  end

  # simple sequence generator by name
  def sequence name=nil, start=nil
    name ||= :seq
    @@sequence[name] ||= start || 0
    @@sequence[name] += 1
  end

  # helper to create and link model
  # create :org -> @model.org_id = mock.create(org).id
  def create name, field=nil
    field ||= name.to_s.singularize + '_id'
    new_model = CleanMock.create(name)
    @model.send('%s=' % field, new_model.id)
    new_model
  end
end
