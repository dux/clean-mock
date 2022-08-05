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

    trait :with_org do
      create :org
    end

    if opts[:process_after_save]
      after_create do
        func :after_save_test do
          true
        end
      end
    end
  end

  define :admin_user, class: User do |user, opts|
    user.is_admin = true
  end

  define(:org) {}
end

# mock explicit define
mock.define :commmon_name, class: false do
  ['John', 'Josh', 'Mike'].sample
end

# mock implicit define
mock :foo, class: false do
  Class.new do
    def foo
      :bar
    end
  end.new
end


