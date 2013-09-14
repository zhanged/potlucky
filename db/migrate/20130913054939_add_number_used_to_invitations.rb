class AddNumberUsedToInvitations < ActiveRecord::Migration
  def change
  	    add_column :invitations, :number_used, :string
  end
end
