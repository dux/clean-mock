# CleanMock - AI/LLM Reference

## What this is

Ruby gem (clean-mock) for test object creation. Alternative to FactoryBot with zero `method_missing` magic.
Single class `CleanMock` in `lib/clean-mock/base.rb` (~117 lines). Global `mock` helper injected onto `Object` in `lib/clean-mock/global.rb`.

## Architecture

* All state is in class variables: `@@mock_data`, `@@fetched`, `@@sequence`, `@@classes` (unused)
* `@@mock_data` stores `{ name => [block, opts] }` pairs registered via `define`
* `build`/`create`/`fetch` all go through `CleanMock.new(*args).model` (or `.create_mock`)
* The define block runs via `instance_exec` on a CleanMock instance, so `self` inside the block is CleanMock (not the model)
* The model reference is passed as the first block argument, not as `self`

## Key call flow

```
mock.build(:user, :admin, email: 'x')
  -> CleanMock.new(:user, :admin, email: 'x').model
    -> args parsed: @kind=:user, @traits=[:admin], opts={email:'x'}
    -> class resolved from @@mock_data[:user] opts[:class]
    -> @model = resolved_class.new
    -> instance_exec(@model, opts, &stored_block)
    -> traits consumed via trait() calls inside block
    -> raises if any traits remain unconsumed
    -> returns @model

mock.create(:user)
  -> CleanMock.new(:user).create_mock
    -> same as build, then calls @model.save + @after_save

mock.fetch(:user)
  -> SHA1 of args as cache key -> @@fetched[key] ||= create(...)
```

## Class resolution (initialize)

| `opts[:class]` value | Behavior |
|---|---|
| nil (default) | `@kind.to_s.classify.constantize.new` |
| `false` | No model created, block return value becomes `@model` |
| Symbol | `classify` the symbol, create class via `Object.const_set` if missing |
| Class | `opts[:class].new` directly |

When `class: false`, block receives `(opts)` instead of `(model, opts)`.

## Instance methods available in define blocks

| Method | Does |
|---|---|
| `trait(name, &block)` | Deletes name from `@traits`, runs block if matched |
| `func(name, &block)` | `@model.define_singleton_method(name, &block)` |
| `sequence(name=nil, start=nil)` | Increments `@@sequence[name]`, returns new value |
| `create(name, field=nil)` | `CleanMock.create(name)`, assigns `.id` to `@model.field` |
| `after_save(&block)` / `after_create` | Stores callback, runs in `create_mock` after save |

## Full example

```ruby
# define - block receives (model_instance, opts_hash)
# self inside the block is CleanMock, NOT the model
mock.define :user do |user, opts|
  user.name     = 'User %s' % sequence(:user)
  user.email    = opts[:email] || 'default@test.com'
  user.is_admin = false

  # singleton method on this instance only
  func :greeting do
    "Hello, #{name}"
  end

  # trait - only runs when activated: mock.build(:user, :admin)
  trait :admin do
    user.is_admin = true
  end

  # trait that creates+links another mock
  trait :with_org do
    create :org                    # -> user.org_id = mock.create(:org).id
    # create :org, 'custom_field'  # -> user.custom_field = mock.create(:org).id
  end

  # only fires on mock.create / mock.fetch, NOT mock.build
  after_create do
    func :after_hook do
      true
    end
  end
end

# class: false - no model, block return value is the mock
mock.define :token, class: false do |opts|
  opts[:value] || SecureRandom.hex
end

# usage
user = mock.build(:user)                         # User.new, no save
user = mock.build(:user, :admin, email: 'x@y')   # with trait + opts
user = mock.create(:user)                         # User.new + save
user = mock.fetch(:user)                          # create once, return cached
token = mock.build(:token, value: 'abc')          # returns 'abc'
```

## Global `mock` helper (global.rb)

Added to `Object` unless already defined:
* `mock(:name, opts) { block }` -> `CleanMock.define`
* `mock { define ... }` -> `CleanMock.instance_exec(&block)`
* `mock` (no args) -> returns `CleanMock` class

## Dependencies

Requires `String#classify`, `String#constantize`, `String#singularize` - from ActiveSupport or dry-inflector.

## File structure

```
lib/clean-mock.rb          # entry point, requires base + global
lib/clean-mock/base.rb     # CleanMock class, all logic
lib/clean-mock/global.rb   # injects mock() onto Object
spec/spec_helper.rb        # loads dry-inflector polyfills, fixtures
spec/fixtures/models.rb    # User, Org test stubs
spec/fixtures/mocks.rb     # mock definitions for tests
spec/tests/clean_spec.rb   # all specs (19 examples)
```

## Testing

```
bundle exec rspec
```

Specs are in `spec/tests/clean_spec.rb`. Fixture models in `spec/fixtures/models.rb` are plain Ruby classes with `attr_accessor` and `save` methods (not ActiveRecord). Mock definitions in `spec/fixtures/mocks.rb`.

## Gotchas

* `attributes_for` requires `#attributes` and `#present?` (ActiveRecord/ActiveSupport) - not usable with plain objects
* `@@sequence` is global and persistent across tests - values keep incrementing, do not assert exact sequence numbers
* `@@fetched` cache is never cleared - `fetch` will return stale objects across test runs unless process restarts
* `after_save` callbacks only fire via `create`/`fetch`, never via `build`
* Unused traits raise `RuntimeError`, not `ArgumentError`
* `@@classes` class variable is declared but never used
