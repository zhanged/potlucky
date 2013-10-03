class CreateUpdates < ActiveRecord::Migration
  def change
    create_table :updates do |t|
      t.text :content
      t.integer :user_id
      t.integer :gather_id

      t.timestamps
    end
    add_index :updates, [:gather_id, :created_at]
  end
end
