class AddPollingToGathers < ActiveRecord::Migration
  def change
  	add_column :gathers, :activity_2, :string
  	add_column :gathers, :activity_3, :string
  	add_column :gathers, :location_2, :text, :limit => nil
  	add_column :gathers, :location_3, :text, :limit => nil
  	add_column :gathers, :date_2, :date
  	add_column :gathers, :date_3, :date
  	add_column :gathers, :time_2, :time
  	add_column :gathers, :time_3, :time
  	add_column :gathers, :wait_hours, :integer
  	add_column :gathers, :wait_time, :time
  end
end
