class AddDetailsTiltToGather < ActiveRecord::Migration
  def change
    add_column :gathers, :details, :string
    add_column :gathers, :tilt, :integer
    add_column :gathers, :num_invited, :integer
    add_column :gathers, :num_joining, :integer, default: 1
  end
end
