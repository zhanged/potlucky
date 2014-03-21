class List < ActiveRecord::Base
	belongs_to :user
	default_scope -> { order('lists.created_at DESC') }
	validates :item, presence: true, length: { maximum: 70 }
	validates :user_id, presence: true

	def self.list_from_friends(user)
		friend_user_ids = "SELECT friended_id FROM friendships WHERE friender_id = :user_id"
    	where("user_id IN (#{friend_user_ids}) OR user_id = :user_id", user_id: user.id)		
	end
end