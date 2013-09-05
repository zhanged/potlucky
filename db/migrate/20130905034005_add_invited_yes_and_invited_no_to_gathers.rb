class AddInvitedYesAndInvitedNoToGathers < ActiveRecord::Migration
  def change
    add_column :gathers, :invited_yes, :string
    add_column :gathers, :invited_no, :string
  end
end
