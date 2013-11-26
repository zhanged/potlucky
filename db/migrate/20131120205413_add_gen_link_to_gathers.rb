class AddGenLinkToGathers < ActiveRecord::Migration
  def change
    add_column :gathers, :gen_link, :text, :limit => nil
  end
end
