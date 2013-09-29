class AddExpireToGathers < ActiveRecord::Migration
  def change
    add_column :gathers, :expire, :string
  end
end
