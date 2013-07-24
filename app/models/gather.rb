class Gather < ActiveRecord::Base
	belongs_to :user
	has_many :invitations, foreign_key: "gathering_id", dependent: :destroy
	has_many :invitees, through: :invitations
	before_save do
		self.invited = (user.email + ", " + invited).downcase.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i).uniq.join(", ")
	end
	default_scope -> { order('gathers.created_at DESC') }
	validates :activity, presence: true, length: { maximum: 40 }
	validates :user_id, presence: true
	validate :tilt_must_fall_in_range_of_invited, unless: "tilt.nil?"
	after_create do
		invitees = invited.downcase.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i)
		invitees.each do |invitee|
			if User.where(email: invitee).present?
				invite!(User.find_by(email: invitee))
			else
				invite!(User.create!(name: invitee.split('@').first, email: invitee, password: "foobar", password_confirmation: "foobar"))
			end
		end
	end

	def invited_already?(other_user)
		invitations.find_by(invitee_id: other_user.id)
	end

	def invite!(other_user)
		invitations.create!(invitee_id: other_user.id)
	end

	def uninvite!(other_user)
		invitations.find_by(invitee_id: other_user.id).destroy
	end

	def tilt_must_fall_in_range_of_invited		
		if tilt < 0 || tilt > (invited.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i).uniq.count + 1)
			errors.add(:tilt, "- Invite #{tilt - invited.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i).uniq.count - 1} more people for tilt to be valid")
			# Need to add error message for negative tilt inputs
		end
	end

	def self.from_gathers_invited_to(user)
		gatherings = user.gatherings
	end
end

