class CreateFriendships < ActiveRecord::Migration
  def change
    create_table :friendships do |t|
      t.integer :friender_id
      t.integer :friended_id

      t.timestamps
    end

    add_index :friendships, :friender_id
    add_index :friendships, :friended_id
    add_index :friendships, [:friender_id, :friended_id], unique: true
  end
end
