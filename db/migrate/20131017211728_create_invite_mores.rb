class CreateInviteMores < ActiveRecord::Migration
  def change
    create_table :invite_mores do |t|
      t.text :more_invitees
      t.integer :user_id
      t.integer :gather_id

      t.timestamps
    end
    add_index :invite_mores, [:gather_id, :created_at]
  end
end
