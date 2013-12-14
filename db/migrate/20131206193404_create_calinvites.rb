class CreateCalinvites < ActiveRecord::Migration
  def change
    create_table :calinvites do |t|
    	t.integer :gather_id
    	t.text :cal_activity, :limit => nil
    	t.date :cal_date
    	t.time :cal_time
    	t.text :cal_location, :limit => nil
    	t.text :cal_details, :limit => nil
      
     	t.timestamps
    end
    add_index :calinvites, [:gather_id, :created_at]
  end
end
