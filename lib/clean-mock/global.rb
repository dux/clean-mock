# mock do
#   define :org do |o|
#     o.name = 'Org %s' % sequence
#   end
# end
# mock.define :user do ...
# mock :user do ...
unless respond_to?(:mock)
  Object.class_eval do
    def mock *args, &block
      if args.first
        CleanMock.define *args, &block
      elsif block_given?
        CleanMock.instance_exec &block
      else
        CleanMock
      end
    end
  end
end