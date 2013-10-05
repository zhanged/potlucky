class ChangeDateTimeFieldTypesInGathers < ActiveRecord::Migration
  def change
	reversible do |dir|
	    change_table :gathers do |t|
	      dir.up 	{ t.change :date, :date }
	      dir.up	{ t.change :time, :time }
	      dir.up 	{ t.change :location, :text, :limit => nil }
	      dir.down 	{ t.change :date, :string }
	      dir.down 	{ t.change :time, :string }
	      dir.down 	{ t.change :location, :string }
	  end
    end

  	add_column :gathers, :more_details, :text, :limit => nil
  end
end
