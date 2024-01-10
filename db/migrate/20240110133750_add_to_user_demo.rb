class AddToUserDemo < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :demo, :boolean, default: false
    # migrate actual user to demo= false
    users = User.all
    users.each do |user|
      user.update(demo: false)
    end
  end
end
