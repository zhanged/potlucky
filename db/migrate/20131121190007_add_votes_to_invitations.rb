class AddVotesToInvitations < ActiveRecord::Migration
  def change
    add_column :invitations, :activity_1v, :integer
    add_column :invitations, :activity_2v, :integer
    add_column :invitations, :activity_3v, :integer
    add_column :invitations, :time_1v, :integer
    add_column :invitations, :time_2v, :integer
    add_column :invitations, :time_3v, :integer
    add_column :invitations, :date_1v, :integer
    add_column :invitations, :date_2v, :integer
    add_column :invitations, :date_3v, :integer
    add_column :invitations, :location_1v, :integer
    add_column :invitations, :location_2v, :integer
    add_column :invitations, :location_3v, :integer
  end
end
