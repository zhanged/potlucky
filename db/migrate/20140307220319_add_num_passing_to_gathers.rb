class AddNumPassingToGathers < ActiveRecord::Migration
  def change
    add_column :gathers, :num_passing, :integer, default: 0
  end
end
