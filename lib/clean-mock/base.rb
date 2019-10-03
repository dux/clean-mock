class CleanMock
  attr_reader :object

  @@fetched   ||= {}
  @@mock_data ||= {}
  @@sequence  ||= {}
  @@classes   ||= {}

  class << self
    # defined mocked object
    def define name, opts={}, &block
      @@mock_data[name] = [block, opts]
    end

    def attributes_for *args
      build(*args).attributes.select{ |k,v| v.present? }
    end

    # create a new object, no save
    def build *args
      new(*args).object
    end

    # save if possible
    def create *args
      build(*args).tap do |object|
        object.save if object.respond_to?(:save)
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

    block, mock_opts = @@mock_data[@kind] || raise(ArgumentError, 'Mock object "%s" not defined' % @kind)

    @object =
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

    if @object
      instance_exec @object, opts, &block
    else
      @object = instance_exec opts, &block
    end

    raise 'Trait [%s] not found' % @traits.join(', ') if @traits.first
  end

  # block to execute and modify object
  def trait name, &block
    if @traits.delete(name)
      instance_exec(@object, &block)
    end
  end

  # define or overlod current instance method
  def func name, &block
    @object.define_singleton_method(name, &block)
  end

  # simple sequence generator by name
  def sequence name=nil, start=nil
    name ||= :seq
    @@sequence[name] ||= start || 0
    @@sequence[name] += 1
  end
end
