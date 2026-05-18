require 'spec_helper'

describe CleanMock do
  context 'is faling when' do
    it 'creates a bad object' do
      expect { mock.build(:foo_bar) }.to raise_error(ArgumentError)
    end

    it 'lists known mocks in the not-defined error' do
      expect { mock.build(:totally_unknown_mock) }.to raise_error(ArgumentError, /Known:.*user/)
    end
  end

  context 'VERSION' do
    it 'matches the .version file' do
      expect(CleanMock::VERSION).to eq File.read('.version').strip
    end
  end

  context 'auto creates class' do
    it 'with default name' do
      expect(mock.build(:user).name).to include 'User '
    end

    it 'and reads options and adds custom email' do
      email = 'foo@bar'
      expect(mock.build(:user, email: email).email).to eq email
    end

    it 'and creates user object with custom methods' do
      user = mock.build(:user)
      expect(user).to            be_a User
      expect(user.say_ok).to     eq 'ok'
      expect(user.say_not_ok).to eq 'not ok'
    end

    it 'and creates user object with admin trait' do
      user = mock.build(:user)
      expect(user).to        be_a User
      expect(user.is_admin).to eq false

      user = mock.build(:user, :admin)
      expect(user).to        be_a User
      expect(user.is_admin).to eq true
    end

    it 'and links mocked object to org' do
      user = mock.build(:user)
      expect(user.org_id).to be_nil

      user = mock.build(:user, :with_org)
      expect(user.org.is_saved).to be true
      expect(user.org_id.class).to be Integer
    end
  end

  context 'manualy defined class (class: User)' do
    it 'and creates admin_user with admin trait' do
      user = mock.build(:admin_user)
      expect(user).to        be_a User
      expect(user.is_admin).to eq true
    end
  end

  context 'using no class creation (class: false)' do
    it 'creates object' do
      foo_bar = mock.build(:foo)
      expect(foo_bar.foo).to eq :bar
    end

    it 'creates random string' do
      list = ['John', 'Josh', 'Mike']

      mock.define :string, class: false do
        list.sample
      end

      name = mock.build(:string)

      expect(list.include?(name)).to be true
    end
  end

  context 'CleanMock.create' do
    it 'saves the model' do
      org = mock.create(:org)
      expect(org).to be_a Org
      expect(org.is_saved).to be true
    end

    it 'saves user model' do
      user = mock.create(:user)
      expect(user).to be_a User
      expect(user.is_saved).to be true
    end
  end

  context 'CleanMock.fetch' do
    it 'returns same object for same args' do
      a = mock.fetch(:org)
      b = mock.fetch(:org)
      expect(a).to equal(b)
    end

    it 'returns different objects for different args' do
      a = mock.fetch(:user, email: 'a@a.com')
      b = mock.fetch(:user, email: 'b@b.com')
      expect(a).not_to equal(b)
    end
  end

  context 'with after_save hook' do
    it 'does not trigger on build' do
      user = mock.build(:user, process_after_save: true)
      expect(user.respond_to?(:after_save_test)).to eq(false)
    end

    it 'triggers on create' do
      user = mock.create(:user, process_after_save: true)
      expect(user.respond_to?(:after_save_test)).to eq(true)
    end
  end

  context 'sequence' do
    it 'uses custom start value' do
      mock.define :seq_start_test, class: false do
        sequence(:custom_seq, 100)
      end
      val = mock.build(:seq_start_test)
      expect(val).to eq(101)
    end
  end

  context 'class: :symbol dynamic creation' do
    it 'creates class dynamically from symbol' do
      mock.define :dynamic_test_klass, class: :dynamic_test_klass do |model, opts|
      end
      obj = mock.build(:dynamic_test_klass)
      expect(obj.class.name).to eq('DynamicTestKlass')
    end
  end

  context 'create with explicit field' do
    it 'sets custom field name' do
      mock.define :user_custom_org, class: User do |user, opts|
        user.name = 'Test'
        user.email = 'test@test.com'
        user.is_admin = false
        create :org, 'custom_org_id'
      end
      user = mock.build(:user_custom_org)
      expect(user.custom_org_id).to eq(11)
      expect(user.org_id).to be_nil
    end
  end

  context 'trait errors' do
    it 'raises on unused trait' do
      expect { mock.build(:user, :nonexistent) }.to raise_error(RuntimeError, /not found/)
    end
  end

  context 'mock global helper' do
    it 'returns CleanMock class when called with no args and no block' do
      expect(mock).to be CleanMock
    end

    it 'evaluates the block in CleanMock context when called with only a block' do
      mock do
        define :mock_block_define, class: false do
          :from_block
        end
      end
      expect(mock.build(:mock_block_define)).to eq :from_block
    end

    it 'defines a mock when called with a name and block' do
      mock :mock_inline_define, class: false do
        :inline_value
      end
      expect(mock.build(:mock_inline_define)).to eq :inline_value
    end
  end

  context 'sequence' do
    it 'defaults to :seq when called with no name' do
      mock.define :seq_default_test, class: false do
        sequence
      end
      a = mock.build(:seq_default_test)
      b = mock.build(:seq_default_test)
      expect(b).to eq(a + 1)
    end
  end

  context 'func' do
    it 'overloads a previously defined singleton method on the same instance' do
      mock.define :func_overload, class: User do |user, opts|
        func(:tag) { 'first' }
        func(:tag) { 'second' }
      end
      expect(mock.build(:func_overload).tag).to eq 'second'
    end
  end
end