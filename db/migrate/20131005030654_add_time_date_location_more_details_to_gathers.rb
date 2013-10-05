class AddTimeDateLocationMoreDetailsToGathers < ActiveRecord::Migration
  def change
		add_column :gathers, :time, :time
		add_column :gathers, :date, :date
		add_column :gathers, :location, :text, :limit => nil
		add_column :gathers, :more_details, :text, :limit => nil
  end
end
