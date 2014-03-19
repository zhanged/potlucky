class AddProviderUidImageTokenExpiresAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    add_column :users, :image, :text, :limit => nil
    add_column :users, :token, :text, :limit => nil
    add_column :users, :expires_at, :datetime
  end
end
