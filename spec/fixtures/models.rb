class User
  attr_accessor :name, :email, :is_admin, :org_id, :custom_org_id, :is_saved

  def org
    Org.new.tap do |o|
      o.save
    end
  end

  def save
    @is_saved = true
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