class Gather < ActiveRecord::Base
	belongs_to :user
	default_scope -> { order('created_at DESC') }
	validates :activity, presence: true, length: { maximum: 40 }
	validates :user_id, presence: true
end