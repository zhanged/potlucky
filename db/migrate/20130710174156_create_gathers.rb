class CreateGathers < ActiveRecord::Migration
  def change
    create_table :gathers do |t|
      t.string :activity
      t.string :invited
      t.string :location
      t.string :date
      t.string :time
      t.integer :user_id

      t.timestamps
    end
    add_index :gathers, [:user_id, :created_at]
  end
end
