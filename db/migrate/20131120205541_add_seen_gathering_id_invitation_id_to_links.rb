class AddSeenGatheringIdInvitationIdToLinks < ActiveRecord::Migration
  def change
    add_column :links, :seen, :integer
    add_column :links, :gathering_id, :integer
    add_column :links, :invitation_id, :integer

    add_index :links, [:gathering_id, :invitation_id]
  end
end
