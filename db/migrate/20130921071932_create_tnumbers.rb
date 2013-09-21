class CreateTnumbers < ActiveRecord::Migration
  def change
    create_table :tnumbers do |t|
      t.string :tphone

      t.timestamps
    end
  end
end
