require 'spec_helper'

describe CleanMock do
  context 'is faling when' do
    it 'creates a bad object' do
      expect { mock.build(:foo_bar) }.to raise_error(ArgumentError)
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
end