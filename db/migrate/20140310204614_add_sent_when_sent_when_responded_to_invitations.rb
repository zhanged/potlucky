class AddSentWhenSentWhenRespondedToInvitations < ActiveRecord::Migration
  def change
    add_column :invitations, :sent, :string
    add_column :invitations, :when_sent, :datetime
    add_column :invitations, :when_responded, :datetime
  end
end
