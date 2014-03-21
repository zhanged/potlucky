class CreateLists < ActiveRecord::Migration
  def change
    create_table :lists do |t|
      t.text :item, :limit => nil
      t.integer :user_id
      t.string :source
      t.string :status
      t.integer :virality

      t.timestamps
    end
    add_index :lists, [:user_id, :created_at]
  end
end
