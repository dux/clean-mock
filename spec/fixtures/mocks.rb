# mock block define
mock do
  define :user do |user, opts|
    user.name     = 'User %s' % sequence(:foo)
    user.email    = opts[:email] || Faker::Internet.email
    user.is_admin = false

    func :say_ok do
      'ok'
    end

    def user.say_not_ok
      'not ok'
    end

    trait :admin do
      user.is_admin = true
    end
  end

  define :admin_user, class: User do |user, opts|
    user.is_admin = true
  end
end

# mock explicit define
mock.define :commmon_name, class: false do
  ['John', 'Josh', 'Mike'].sample
end

# mock implicit define
mock :foo, class: false do
  FooBar ||= Class.new do
    def foo
      :bar
    end
  end

  FooBar.new
end
