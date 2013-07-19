class Gather < ActiveRecord::Base
	belongs_to :user
	before_save do
		self.invited = invited.downcase.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i).uniq.join(", ")
	end
	default_scope -> { order('created_at DESC') }
	validates :activity, presence: true, length: { maximum: 40 }
	validates :user_id, presence: true
	validate :tilt_must_fall_in_range_of_invited, unless: "tilt.nil?"

	def tilt_must_fall_in_range_of_invited		
		if tilt < 0 || tilt > (invited.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i).uniq.count + 1)
			errors.add(:tilt, "- Invite #{tilt - invited.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i).uniq.count - 1} more people for tilt to be valid")
			# Need to add error message for negative tilt inputs
		end
	end
end

