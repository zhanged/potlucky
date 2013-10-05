class RemoveTimeDateFromGathers < ActiveRecord::Migration
    def up
	    remove_column :gathers, :time
	    remove_column :gathers, :date
	    remove_column :gathers, :location
  	end

	def down
		add_column :gathers, :time, :string
		add_column :gathers, :date, :string
		add_column :gathers, :location, :string
	end

end