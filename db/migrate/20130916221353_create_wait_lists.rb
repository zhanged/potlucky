class CreateWaitLists < ActiveRecord::Migration
  def change
    create_table :wait_lists do |t|
      t.string :email

      t.timestamps
    end
  end
end
