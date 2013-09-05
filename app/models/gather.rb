class Gather < ActiveRecord::Base
	belongs_to :user
	has_many :invitations, foreign_key: "gathering_id", dependent: :destroy
	has_many :invitees, through: :invitations
	before_create do
		self.invited = (user.email + " " + invited).downcase.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i).uniq.join(" ")
		self.invited_yes = user.email
		self.invited_no = invited.sub(user.email,'')
		self.num_invited = invitees.count
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
				invite!(User.create!(name: invitee.split('@').first, email: invitee, phone: "0000000000", password: "foobar", password_confirmation: "foobar"))
			end
		end
		invitations.find_by(invitee_id: user.id).update(status: "Yes")
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

	def increase_num_joining!(invitation_id)
		this_invitation = Invitation.find_by(id: invitation_id)
		this_gather_id = Gather.find_by(id: this_invitation.gathering_id).id
		Gather.increment_counter(:num_joining, this_gather_id)
		@gather = Gather.find_by(id: this_invitation.gathering_id)
		@joining_user = User.find_by(id: this_invitation.invitee_id)
		@gather.update_attributes(invited_yes: (@gather.invited_yes + " " + @joining_user.email))
		@gather.update_attributes(invited_no: @gather.invited_no.sub(@joining_user.email,''))
		
		account_sid = "ACbb2447b2100021b9e65920128431f756"
		auth_token = "2ff59ce4c8f6b6b6eb871c61d9f9fc50"
		@client = Twilio::REST::Client.new account_sid, auth_token
			
		if @gather.num_joining == @gather.tilt			 
			message = @client.account.sms.messages.create(
				body: "Yes! Your gathering #{@gather.activity} has tilted with #{@gather.invited_yes}!",
			    to: @gather.user.phone,
			    from: "+14154231000")
			puts message.from
		elsif @gather.num_joining > @gather.tilt
			message = @client.account.sms.messages.create(
				body: "Looks like #{@joining_user.email} is also joining your gathering #{@gather.activity}!",
			    to: @gather.user.phone,
			    from: "+14154231000")
			puts message.from
		end
	end

	def decrease_num_joining!(invitation_id)
		this_invitation = Invitation.find_by(id: invitation_id)
		this_gather_id = Gather.find_by(id: this_invitation.gathering_id).id
		Gather.decrement_counter(:num_joining, this_gather_id)
		@gather = Gather.find_by(id: this_invitation.gathering_id)
		@unjoining_user = User.find_by(id: this_invitation.invitee_id)
		@gather.update_attributes(invited_no: (@gather.invited_no + " " + @unjoining_user.email))
		@gather.update_attributes(invited_yes: @gather.invited_yes.sub(@unjoining_user.email,''))

		account_sid = "ACbb2447b2100021b9e65920128431f756"
		auth_token = "2ff59ce4c8f6b6b6eb871c61d9f9fc50"
		@client = Twilio::REST::Client.new account_sid, auth_token

		if (@gather.num_joining + 1) >= @gather.tilt			 
			message = @client.account.sms.messages.create(
				body: "Bad news bears: looks like #{@unjoining_user.email} won't be joining your gathering #{@gather.activity} anymore :(",
			    to: @gather.user.phone,
			    from: "+14154231000")
			puts message.from
		end
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

