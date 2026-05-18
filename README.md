# CleanMock - Ruby test object creation library

CleanMock replaces fixtures in tests. You define mock blueprints for your models, then call `mock.build`, `mock.create`, or `mock.fetch` to produce test objects on the fly.

Adding and removing fields is easy because mocks use your existing classes (ActiveRecord, Sequel, plain Ruby, etc.) directly.

Similar to FactoryBot but without any `method_missing` magic. A pointer to the newly created object is passed to your block and you are free to do with it as you please. This means no unexpected behavior and nothing to work around.

## Installation

```
gem install clean-mock
```

or in Gemfile

```ruby
gem 'clean-mock'
```

then require it

```ruby
require 'clean-mock'
```

### Dependency

CleanMock requires `String#classify`, `String#constantize`, and `String#singularize` to be defined.

These are available via ActiveSupport or as a lightweight alternative:

```ruby
require 'dry/inflector'

class String
  def classify;    Dry::Inflector.new.classify self; end
  def constantize; Dry::Inflector.new.constantize self; end
  def singularize; Dry::Inflector.new.singularize self; end
end
```

## Defining mocks

There are three equivalent ways to define mocks:

```ruby
# block style - define multiple mocks at once
mock do
  define :user do |user, opts|
    # ...
  end

  define :org do |org, opts|
    # ...
  end
end

# explicit style
mock.define :user do |user, opts|
  # ...
end

# shorthand style
mock :user do |user, opts|
  # ...
end
```

### Class resolution

The second argument to `define` controls which class is instantiated:

```ruby
# default - class is resolved from name: :user -> User
mock.define(:user) do |user, opts|
  # user is User.new
end

# explicit class
mock.define(:admin_user, class: User) do |user, opts|
  # user is User.new
end

# dynamic class from symbol - creates the class if it doesn't exist
mock.define(:thing, class: :thing) do |thing, opts|
  # thing is Thing.new (class created via Object.const_set if needed)
end

# no class - return anything you want
mock.define(:random_name, class: false) do |opts|
  ['John', 'Josh', 'Mike'].sample
end
```

When `class: false`, only `opts` is passed to the block (no model argument), and whatever the block returns becomes the mock value.

## Instance methods inside define block

These helpers are available inside the `define` block:

### trait(name, &block)

Create named variants of an object. Traits are activated by passing their names to `build`/`create`/`fetch`.

```ruby
mock.define :user do |user, opts|
  user.is_admin = false

  trait :admin do
    user.is_admin = true
  end
end

mock.build(:user).is_admin         # false
mock.build(:user, :admin).is_admin # true
```

Multiple traits can be combined:

```ruby
mock.build(:user, :admin, :with_org)
```

Passing an undefined trait raises an error:

```ruby
mock.build(:user, :nonexistent) # RuntimeError: Trait [nonexistent] not found
```

### func(name, &block)

Define or overload a singleton method on the model instance.

```ruby
mock.define :user do |user, opts|
  func :full_greeting do
    "Hello, I am #{name}"
  end
end

mock.build(:user).full_greeting # "Hello, I am ..."
```

### sequence(name = nil, start = nil)

Auto-incrementing integer sequence. Each name tracks its own counter independently.

```ruby
mock.define :user do |user, opts|
  user.name  = 'User %s' % sequence(:user)   # User 1, User 2, User 3...
  user.email = 'user-%s@test.com' % sequence  # uses default :seq name
end
```

With a custom start value:

```ruby
mock.define :item do |item, opts|
  item.position = sequence(:pos, 100)  # 101, 102, 103...
end
```

### create(name, field = nil)

Create and link another mock object. Calls `CleanMock.create` on the related mock and assigns its `id` to the current model.

```ruby
mock.define :user do |user, opts|
  trait :with_org do
    create :org  # equivalent to: user.org_id = mock.create(:org).id
  end
end
```

The field name defaults to `name.singularize + '_id'`. Pass an explicit field to override:

```ruby
create :org, 'organization_id'  # user.organization_id = mock.create(:org).id
```

### after_save(&block) / after_create(&block)

Register a callback that runs after `create_mock` saves the model. Only fires when using `mock.create` or `mock.fetch`, not `mock.build`.

```ruby
mock.define :user do |user, opts|
  after_create do
    # runs after save
    # user has been persisted at this point
  end
end
```

`after_create` is an alias for `after_save`.

## Public API

### mock.build(:name, *traits, **opts)

Instantiate the mock object without saving.

```ruby
user = mock.build(:user)
user = mock.build(:user, :admin, email: 'foo@bar.com')
```

### mock.create(:name, *traits, **opts)

Instantiate and call `.save` on the model (if it responds to `save`), then run any `after_save` callbacks.

```ruby
user = mock.create(:user, :admin)
user.id # set by your ORM after save
```

### mock.fetch(:name, *traits, **opts)

Like `create`, but memoized - returns the same object when called with identical arguments.

```ruby
org = mock.fetch(:org)
org2 = mock.fetch(:org)
org.equal?(org2) # true - same object

# different args produce different objects
a = mock.fetch(:user, email: 'a@a.com')
b = mock.fetch(:user, email: 'b@b.com')
a.equal?(b) # false
```

### mock.attributes_for(:name, *traits, **opts)

Build the object and return its `.attributes` hash, filtered to present values. Useful with ActiveRecord models.

```ruby
attrs = mock.attributes_for(:user, :admin)
# { name: 'User 1', email: 'john@example.com', is_admin: true }
```

## Full example

```ruby
mock :user do |user, opts|
  user.name    = 'User %s' % sequence(:user)
  user.address = 'Somewhere %s' % sequence
  user.email   = opts[:email] || Faker::Internet.email
  user.is_admin = false

  func :say_ok do
    'ok'
  end

  trait :admin do
    user.is_admin = true
  end

  trait :with_org do
    create :org
  end

  after_create do
    # runs after save, user is persisted
  end
end

mock.define(:org) {}

mock.define :foo, class: false do
  Class.new do
    def foo
      :bar
    end
  end.new
end

# build - no save
user = mock.build(:user)
user.class    # User
user.name     # 'User 1'
user.is_admin # false

# create - with save
user = mock.create(:user, :admin, email: 'foo@bar.baz')
user.name     # 'User 2'
user.email    # 'foo@bar.baz'
user.is_admin # true

# create with linked object
user = mock.create(:user, :with_org)
user.org_id   # 11 (or whatever org.id returns)

# fetch - memoized create
org1 = mock.fetch(:org)
org2 = mock.fetch(:org)
org1.equal?(org2) # true

# class: false
mock.build(:foo).foo # :bar
```

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rspec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dux/clean-mock.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
