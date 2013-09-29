class AddCompletedToGathers < ActiveRecord::Migration
  def change
    add_column :gathers, :completed, :datetime
  end
end
