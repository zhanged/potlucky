class AddDetailsTiltToGather < ActiveRecord::Migration
  def change
    add_column :gathers, :details, :string
    add_column :gathers, :tilt, :integer
  end
end
