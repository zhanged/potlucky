class RemoveCharLimitForInvitesInGather < ActiveRecord::Migration
  def change
	reversible do |dir|
	    change_table :gathers do |t|
	      dir.up 	{ t.change :invited, :text, :limit => nil }
	      dir.up	{ t.change :invited_yes, :text, :limit => nil }
	      dir.up 	{ t.change :invited_no, :text, :limit => nil }
	      dir.down 	{ t.change :invited, :string }
	      dir.down 	{ t.change :invited_yes, :string }
	      dir.down 	{ t.change :invited_no, :string }
	  end
    end
  end
end
