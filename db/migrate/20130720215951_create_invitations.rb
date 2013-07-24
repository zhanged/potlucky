class CreateInvitations < ActiveRecord::Migration
  def change
    create_table :invitations do |t|
      t.integer :gathering_id
      t.integer :invitee_id
      t.string :status, default: "NA"

      t.timestamps
    end
    add_index :invitations, :gathering_id
    add_index :invitations, :invitee_id
    add_index :invitations, [:gathering_id, :invitee_id], unique: true
  end
end
