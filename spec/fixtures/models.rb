class User
  attr_accessor :name, :email, :is_admin, :org_id

  def org
    Org.new.tap do |o|
      o.save
    end
  end
end

class Org
  attr_accessor :is_saved

  def id
    11
  end

  def save
    @is_saved = true
  end
end