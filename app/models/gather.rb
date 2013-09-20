class Gather < ActiveRecord::Base
	belongs_to :user
	has_many :invitations, foreign_key: "gathering_id", dependent: :destroy
	has_many :invitees, through: :invitations
	before_create do
		self.invited = invited.downcase.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i).uniq.join(" ")
		self.invited_yes = user.email
		self.invited_no = invited
	end
	default_scope -> { order('gathers.created_at DESC') }
	validates :activity, presence: true, length: { maximum: 80 }
	validates :user_id, presence: true
	validate :tilt_must_fall_in_range_of_invited, unless: "tilt.nil?"
	validate :when_tilt_is_nil
	after_create do
		invitees = invited.downcase.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i)
		invitees.each do |invitee|
			if User.find_by(email: invitee).present?
				@user = User.find_by(email: invitee)
				invite!@user
				@invitation = Invitation.find_by(invitee_id: @user.id, gathering_id: self.id)
				if @user.phone.present?
					@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
					message = @client.account.sms.messages.create(
						body: "#{user.name} has invited you to #{activity}! #{tilt} friends for critical mass - to join, reply Y#{@invitation.id}",
					    to: @user.phone,
					    from: "+14154231000")
					puts message.from
				else
					UserMailer.invitation_email(@user, self, @invitation, user).deliver
				end
			else
				first_password = SecureRandom.urlsafe_base64(10)
				@user = User.create!(email: invitee, password: first_password, password_confirmation: first_password)
				invite!@user
				@invitation = Invitation.find_by(invitee_id: @user.id, gathering_id: self.id)
				UserMailer.invitation_email(@user, self, @invitation, user).deliver				
			end
		end
		
		self.update_attributes(invited: (user.email + " " + invited))
		self.update_attributes(num_invited: invitees.count + 1)
		invite!user
		invitations.find_by(invitee_id: user.id).update(status: "Yes")
		self.update_attributes(num_joining: 1)

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
		@this_invitation = Invitation.find_by(id: invitation_id)
		Gather.increment_counter(:num_joining, @this_invitation.gathering_id)
		@gather = Gather.find_by(id: @this_invitation.gathering_id)
		@joining_user = User.find_by(id: @this_invitation.invitee_id)
		@gather.update_attributes(invited_yes: (@gather.invited_yes + " " + @joining_user.email))
		@gather.update_attributes(invited_no: @gather.invited_no.sub(@joining_user.email,''))
		invited_yes_array = @gather.invited_yes.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i)
		@people_joining_less_user = ""
		if @joining_user.name.present?
			@joining_user_name_or_email = @joining_user.name
		else
			@joining_user_name_or_email = @joining_user.email
		end				

		@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
			
		if @gather.num_joining < (@gather.tilt + 1)
			message = @client.account.sms.messages.create(
				body: "Great! We've marked you down as joining #{@gather.activity}. Stay tuned - you'll get a text if this takes off...",
			    to: @joining_user.phone,
			    from: ENV['TWILIO_MAIN'])
			puts message.from

			@gather.update_attributes(details: ("#{@gather.details} <br>#{Time.now.to_formatted_s(:db)} To #{@joining_user_name_or_email}: Great! We've marked you down as joining #{@gather.activity}. Stay tuned - you'll get a text if this takes off... "))

		elsif @gather.num_joining == (@gather.tilt + 1)
			invited_yes_array.each do |n|
				invited_yes_user = User.find_by(email: n)
				@invited_yes_user_invitation = Invitation.find_by(gathering_id: @gather.id, invitee_id: invited_yes_user.id)
				if @invited_yes_user_invitation.number_used.nil?
					all_numbers_used = invited_yes_user.reverse_invitations.pluck(:number_used)
					@number_used = (ENV['TWILIO_NUMBERS'].split(" ") - all_numbers_used).sample
					@invited_yes_user_invitation.update_attributes!(number_used: @number_used)
				else
					@number_used = @invited_yes_user_invitation.number_used
				end

				(invited_yes_array - (invited_yes_user.email.split(" "))).each do |n|
					if invited_yes_user.name.present?
						if @people_joining_less_user == ""
							@people_joining_less_user = invited_yes_user.name
						else
							@people_joining_less_user = @people_joining_less_user + ", " + invited_yes_user.name
						end
					else
						if @people_joining_less_user == ""
							@people_joining_less_user = invited_yes_user.email
						else
							@people_joining_less_user = @people_joining_less_user + ", " + invited_yes_user.email
						end
					end
				end
				
				message = @client.account.sms.messages.create(
					body: "Yes! Your Bloon #{@gather.activity} has taken off with #{@people_joining_less_user}! Just reply to this text to figure out the details with them",
				    to: invited_yes_user.phone,
				    from: @number_used)
				puts message.from
			end

			@gather.update_attributes(details: ("#{@gather.details} <br>#{Time.now.to_formatted_s(:db)} Yes! Your Bloon #{@gather.activity} has tilted with #{invited_yes_array.join(", ")}! Just reply to this text to figure out the details with them "))

		elsif @gather.num_joining > (@gather.tilt + 1)
			if @this_invitation.number_used.nil?
				all_numbers_used = @joining_user.reverse_invitations.pluck(:number_used)
				@number_used = (ENV['TWILIO_NUMBERS'].split(" ") - all_numbers_used).sample
				@this_invitation.update_attributes(number_used: @number_used)
			else
				@number_used = @this_invitation.number_used
			end

			(invited_yes_array - @joining_user.email.split(" ")).each do |n|
				invited_yes_user = User.find_by(email: n)
				@invited_yes_user_invitation = Invitation.find_by(gathering_id: @gather.id, invitee_id: invited_yes_user.id)
				
				message = @client.account.sms.messages.create(
					body: "Sweet, #{@joining_user_name_or_email} is joining as well! Catch #{@joining_user_name_or_email} up on the details",
				    to: invited_yes_user.phone,
				    from: @invited_yes_user_invitation.number_used)
				puts message.from

				if invited_yes_user.name.present?
					if @people_joining_less_user == ""
						@people_joining_less_user = invited_yes_user.name
					else
						@people_joining_less_user = @people_joining_less_user + ", " + invited_yes_user.name
					end
				else
					if @people_joining_less_user == ""
						@people_joining_less_user = invited_yes_user.email
					else
						@people_joining_less_user = @people_joining_less_user + ", " + invited_yes_user.email
					end
				end
			end

			message = @client.account.sms.messages.create(
				body: "Yay, the Bloon #{@gather.activity} has already taken off with #{@people_joining_less_user}! Just reply to this text to get the details from them",
			    to: @joining_user.phone,
			    from: @number_used)
			puts message.from

			@gather.update_attributes(details: ("#{@gather.details} <br>#{Time.now.to_formatted_s(:db)} Yay, the Bloon #{@gather.activity} has already taken off with #{@people_joining_less_user}! Just reply to this text to get the details from them "))
			@gather.update_attributes(details: ("#{@gather.details} <br>#{Time.now.to_formatted_s(:db)} To #{@joining_user_name_or_email}: Yay, the Bloon #{@gather.activity} has already taken off with #{@people_joining_less_user}! Just reply to this text to get the details from them "))

		end
	end

	def decrease_num_joining!(invitation_id)
		@this_invitation = Invitation.find_by!(id: invitation_id)
		Gather.decrement_counter(:num_joining, @this_invitation.gathering_id)
		@gather = Gather.find_by(id: @this_invitation.gathering_id)
		@unjoining_user = User.find_by(id: @this_invitation.invitee_id)
		@gather.update_attributes(invited_no: (@gather.invited_no + " " + @unjoining_user.email))
		@gather.update_attributes(invited_yes: @gather.invited_yes.sub(@unjoining_user.email,''))

		if @unjoining_user.name.present?
			@unjoining_user_name_or_email = @unjoining_user.name
		else
			@unjoining_user_name_or_email = @unjoining_user.email
		end

		@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']

		if @gather.num_joining < @gather.tilt
			from_number = ENV['TWILIO_MAIN']
		else
			from_number = @this_invitation.number_used
		end

		message = @client.account.sms.messages.create(
			body: "Sad to see you leave! Reply Y#{@this_invitation.id} to rejoin",
		    to: @unjoining_user.phone,
		    from: from_number)
		puts message.from

		@gather.update_attributes(details: ("#{@gather.details} <br>#{Time.now.to_formatted_s(:db)} To #{@unjoining_user_name_or_email}: Sad to see you leave! Reply Y#{@this_invitation.id} to rejoin "))

		if @gather.num_joining >= @gather.tilt			 

			invited_yes_array = @gather.invited_yes.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i)
			invited_yes_array.each do |n|
				invited_yes_user = User.find_by(email: n)
				invited_yes_user_invitation = Invitation.find_by(gathering_id: @gather.id, invitee_id: invited_yes_user.id)				

				message = @client.account.sms.messages.create(
					body: "Bad news bears: looks like #{@unjoining_user_name_or_email} won't be joining anymore :(",
				    to: invited_yes_user.phone,
				    from: invited_yes_user_invitation.number_used)
				puts message.from
			end

			@gather.update_attributes(details: ("#{@gather.details} <br>#{Time.now.to_formatted_s(:db)} Bad news bears: looks like #{@unjoining_user_name_or_email} won't be joining anymore :( "))

		end
	end

	def tilt_must_fall_in_range_of_invited		
		if tilt > (invited.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i).uniq.count)
			errors.add(:tilt, "- Invite #{tilt - invited.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i).uniq.count} more people for lift off number to be valid")
		elsif tilt < 0
			errors.add(:tilt, "- Can't lift off with negative people...")
		end
	end

	def when_tilt_is_nil
		if tilt == nil && invited.present?
				errors.add(:tilt, "- Can't invite anyone if you don't enter a lift off number")
		end
	end

	def self.from_gathers_invited_to(user)
		gatherings = user.gatherings
	end
end

