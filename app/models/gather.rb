class Gather < ActiveRecord::Base
	belongs_to :user
	has_many :invitations, foreign_key: "gathering_id", dependent: :destroy
	has_many :invitees, through: :invitations
	before_create do
		self.invited_yes = user.email
		self.invited_no = invited
	end
	default_scope -> { order('gathers.created_at DESC') }
	validates :activity, presence: true, length: { maximum: 80 }
	validates :user_id, presence: true
	validate :tilt_must_fall_in_range_of_invited, unless: "tilt.nil?"
	after_create do
		invitees = invited.downcase.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i)
		invitees.each do |invitee|
			if User.where(email: invitee).present?
				@user = User.find_by(email: invitee)
				invite!@user
				@invitation = Invitation.find_by(invitee_id: @user.id, gathering_id: self.id)
				if @user.phone.present?
					@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
					message = @client.account.sms.messages.create(
					body: "#{user.name} has invited you to #{activity}! #{tilt} friends to tilt - to join, reply YES#{@invitation.id}",
				    to: @user.phone,
				    from: "+14154231000")
					puts message.from
				else
					UserMailer.invitation_email(@user, self, @invitation).deliver
				end
			else
				invite!(User.create!(email: invitee))
				@user = User.find_by(email: invitee)
				@invitation = Invitation.find_by(invitee_id: @user.id, gathering_id: self.id)
				UserMailer.invitation_email(@user, self, @invitation).deliver
			end
		end
		
		self.invited = (user.email + " " + invited).downcase.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i).uniq.join(" ")
		invite!user
		self.num_invited = invitees.count

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
		
		@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
			
		if @gather.num_joining == (@gather.tilt + 1)			 
			message = @client.account.sms.messages.create(
				body: "Yes! Your gathering #{@gather.activity} has tilted with #{@gather.invited_yes}!",
			    to: @gather.user.phone,
			    from: "+14154231000")
			puts message.from
		elsif @gather.num_joining > (@gather.tilt + 1)
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

		@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']

		if @gather.num_joining >= @gather.tilt			 
			message = @client.account.sms.messages.create(
				body: "Bad news bears: looks like #{@unjoining_user.email} won't be joining your gathering #{@gather.activity} anymore :(",
			    to: @gather.user.phone,
			    from: "+14154231000")
			puts message.from
		end
	end

	def tilt_must_fall_in_range_of_invited		
		if tilt < 0 || tilt > (invited.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i).uniq.count)
			errors.add(:tilt, "- Invite #{tilt - invited.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i).uniq.count} more people for tilt to be valid")
			# Need to add error message for negative tilt inputs
		end
	end

	def self.from_gathers_invited_to(user)
		gatherings = user.gatherings
	end
end

