# Clean mock - ruby testing mock and stub helper

Clen mock replaces fixtures in tests. This way, you won't have to keep the fixtures up-to-date as you change the data model.

Clen mock generates data on the fly and adding and removing fields is much easier. Also, you can use it in setup just how you'd use fixtures.

Mocks you create will use objects that you allready have, as for example ActiveRecord or Sequel models.

Library is similar to factory bot, but creates object in much cleaner - non-magic way.
Pointer to newely created object is passed and you are free to do with it as you please.

### Why?

There is no `method_missing` inside `clean-mock` lib.
Author (@dux) loves metaprograming, but thinks that this is not place to use it, hence this lib and not [factory bot](https://github.com/thoughtbot/factory_bot).

Using `clean-mock` will probably never produce unexpected results and you will not have to work around it in any way.

## Installation and usage

to install

`gem install clean-mock`

or in Gemfile

`gem 'clean-mock'`

and to use

`require 'clean-mock'`

### Dependency

`clean-mock` requires that you have `String#classify` and `String#constantize` defined.

## mock.define

Makes definitinos/descriptions of base mock objects. We start with `new` object and reference is passed.

`mock.define(:user) do |user, opts| ...` - define mock object and use `User` class instance

`mock.define(:user, class: SomeClass) do |user, opts| ...` - use `SomeClass` instead of calculated `User`

`mock.define(:user, class: :some_class) do |some_class, opts|...` - dynamicly create `SomeClass` and use it

`mock.define(:user, class: false) do |opts| ...` - do not create a class on `mock.build`, pass only options

### CleanMock instance methods, available inside define &block

Only the basic helper stuff is available.

`trait(name, &block)`   - Create different versions of a object

`func(name, &blok)` - shortcut for @object.define_method, overload or add class methods

`sequence(name)`  - create a named sequence

`create(name, [field])` - create and link other objects

All features shown as examples in Example 1.

## mock - other public methods

`mock.build(:user)` -> build user object, no save

`mock.create(:user)` -> build user object and save if  `@object.respond_to?(:save) == true`

`mock.fetch(:user)` -> create or fetch allready created object

`mock.attributes_for(:user, :trait1, ...)` -> get attrbibutes for created object

## Example 1 - object with a trait and an option

Fast reference for a start. In this case class name is calculated as `(:user).to_s.classify`

```ruby
# define user mock wich will use existing User model for creation of new objects
mock :user do |user, opts|
  user.name    = 'User %s' % sequence(:foo)
  user.address = 'Somewhere %s' % sequence
  user.email   = opts[:email] || Faker::Internet.email

  trait :admin do
    func :say_ok do
      'ok'
    end

    # or the same thing
    def user.say_ok
      'ok'
    end

    user.is_admin = true
  end

  trait :with_org do
    create :org
  end
end

# this will create User model but will not save
user = mock.build :user
user.class    # User
user.id.class # NilClass
user.name     # 'User 1'
user.email    # 'john.doe@from-faker-gem.net'
user.say_ok   # ArgumentError
user.is_admin # false
user.org      # nil

# this creates and saves new User model
user = mock.create :user, :admin, email: 'foo@bar.baz'
user.name     # 'User 2'
user.email    # 'foo@bar.baz'
user.say_ok   # 'ok'
user.is_admin # true
user.org      # nil

# now we will create another mocked object inside base one
user = mock.create :user, :with_org
user.name     # 'User 3'
user.email    # 'john.doe@from-faker-gem.net'
user.say_ok   # ArgumentError
user.is_admin # false
user.org      # <Org>
```

### Example 2 - custom class as a class

In this case class `User` is given and calculated one `AdminUser` will not be used.

```ruby
mock :admin_user, class: User do |user, opts|
  user.is_admin = true
end

mock.create :admin_user # <User:0x0...>
```

### Example 3 - class: false

With passing `class: false` you can return anything you like and you will not be using base class.

```ruby
mock do
  # return new generic class
  define :foo, class: false do
    Class.new do
      def foo
        :bar
      end
    end.new
  end

  # retrun random string
  define :commmon_name, class: false do
    ['John', 'Josh', 'Mike'].sample
  end
end

obj = mock.build :foo   # <Foo:0x0...>
obj.foo                 # :bar

str = mock.build :commmon_name
str                     # John, Josh or  Mike
```

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rspec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/solnic/clean-mock.
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the
[Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
