# Simple mock - ruby testing mock and stub helper

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

`mock.define(:user) do |user, opts| ...` - define mock object and use `User` class instance

`mock.define(:user, class: SomeClass) do |user, opts| ...` - use `SomeClass` instead of calculated `User`

`mock.define(:user, class: :some_class) do |some_class, opts|...` - dynamicly create `SomeClass` and use it

`mock.define(:user, class: false) do |opts| ...` - do not create a class on `mock.build`, pass only options

## mock - other public methods

`mock.build(:user)` -> build user object, no save

`mock.create(:user)`  -> build user object and save if  `@object.respond_to?(:save) == true`

`mock.fetch(:user)`   -> create or fetch allready created object

## Example 1 - object with a trait and an option

Fast reference for a start. In this case class name is calculated as (:user).to_s.classify

```ruby
mock :user do |user, opts|
  user.name  = 'User %s' % sequence(:foo)
  user.email = opts[:email] || Faker::Internet.email

  trait :admin do
    func :say_ok do
      'ok'
    end
    # or same thing
    def user.say_ok
      'ok'
    end

    user.is_admin = true
  end
end

user = mock.create :user
user.class    # User
user.name     # 'User 1'
user.email    # 'john.doe@from-faker-gem.net'
user.say_ok   # ArgumentError
user.is_admin # false

user = mock.create :user, :admin, email: 'foo@bar.baz'
user.name     # 'User 1'
user.email    # 'foo@bar.baz'
user.say_ok   # 'ok'
user.is_admin # true
```

### Example 2 - custom class as a class

In this case class is given and not calculated

```ruby
mock :admin_user, class: User do |user, opts|
  user.is_admin = true
end

mock.create :admin_user # <User:0x0...>
```

### Example 3 - class: false

```ruby
mock do
  define :foo, class: false do
    FooBar ||= Class.new do
      def foo
        :bar
      end
    end

    FooBar.new
  end

  define :commmon_name, class: false do
    ['John', 'Josh', 'Mike'].sample
  end
end

obj = mock.build :foo   # <Foo:0x0...>
obj.foo                 # :bar

str = mock.build :commmon_name
str                     # John, Josh or  Mike
```
