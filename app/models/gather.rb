class Gather < ActiveRecord::Base
	belongs_to :user
	has_many :invitations, foreign_key: "gathering_id", dependent: :destroy
	has_many :invitees, through: :invitations
	before_save do
		self.invited = (user.email + ", " + invited).downcase.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i).uniq.join(", ")
	end
	default_scope -> { order('gathers.created_at DESC') }
	validates :activity, presence: true, length: { maximum: 80 }
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
		self.num_invited = invitees.count
		invitations.find_by(invitee_id: user.id).update(status: "Yes")
	end
	after_save :text_upon_tilt

	def text_upon_tilt
		if num_joining == tilt
			account_sid = "ACbb2447b2100021b9e65920128431f756"
			auth_token = "2ff59ce4c8f6b6b6eb871c61d9f9fc50"
			@client = Twilio::REST::Client.new account_sid, auth_token
			 
			message = @client.account.sms.messages.create(:body => "Your gathering has tilted!",
			    :to => "+13476032899",
			    :from => "+14154231000")
			puts message.from
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

