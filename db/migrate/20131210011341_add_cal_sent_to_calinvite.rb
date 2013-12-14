class AddCalSentToCalinvite < ActiveRecord::Migration
  def change
    add_column :calinvites, :cal_sent, :text, :limit => nil
  end
end
