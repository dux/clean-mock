require 'spec_helper'

describe CleanMock do
  it 'creates bad object and it fails' do
    expect { mock.build(:foo_bar) }.to raise_error(ArgumentError)
  end

  it 'creates user object with default name' do
    expect(mock.build(:user).name).to include 'User '
  end

  it 'reads options and adds custom email' do
    email = 'foo@bar'
    expect(mock.build(:user, email: email).email).to eq email
  end

  it 'creates user object with custom methods' do
    user = mock.build(:user)
    expect(user.class).to      eq User
    expect(user.say_ok).to     eq 'ok'
    expect(user.say_not_ok).to eq 'not ok'
  end

  it 'creates user with admin trait' do
    user = mock.build(:user)
    expect(user.class).to    eq User
    expect(user.is_admin).to eq false

    user = mock.build(:user, :admin)
    expect(user.class).to    eq User
    expect(user.is_admin).to eq true
  end

  it 'creates admin_user with admin trait' do
    user = mock.build(:admin_user)
    expect(user.class).to eq User
    expect(user.is_admin).to eq true
  end

  it 'creates object without default class' do
    foo_bar = mock.build(:foo)
    expect(foo_bar.class).to eq FooBar
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