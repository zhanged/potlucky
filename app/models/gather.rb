class Gather < ActiveRecord::Base
	belongs_to :user
	has_many :invitations, foreign_key: "gathering_id", dependent: :destroy
	has_many :invitees, through: :invitations
	has_many :updates, dependent: :destroy
	before_create do
		self.invited = invited.downcase.sub(user.email,"").scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i).uniq.join(" ")
		self.invited_yes = user.email
	end
	default_scope -> { order('gathers.updated_at DESC') }
	validates :activity, presence: true, length: { maximum: 72 }
	validates :user_id, presence: true
	validate :tilt_must_fall_in_range_of_invited, unless: "tilt.nil?"
	validate :when_tilt_is_nil
	after_create do
		invitees = invited.downcase.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i)
		self.update_attributes(num_invited: invitees.count)
		invitees.each do |invitee|
			email_name = invitee.split(/[.@]/).first.capitalize
			formatted_email = invitee
			if invitee.split('@').last == "gmail.com"
				formatted_email = invitee.split('@').first.gsub(".","") + "@" + invitee.split('@').last
			end
			
			@to_invitees = ""
			invitees.each do |i|
				if i.split('@').last == "gmail.com"
					i_email = i.split('@').first.gsub(".","") + "@" + i.split('@').last
				else
					i_email = i
				end
				if formatted_email != i_email
					if @to_invitees == ""
						if User.find_by(email: i_email).present?
							@to_invitees = User.find_by(email: i_email).name.split(' ').first
						else
							@to_invitees = i.split(/[.@]/).first.capitalize
						end
					else
						if User.find_by(email: i_email).present?
							@to_invitees = User.find_by(email: i_email).name.split(' ').first + ", " + @to_invitees
						else
							@to_invitees = i.split(/[.@]/).first.capitalize + ", " + @to_invitees
						end
					end
				end
			end
			if @to_invitees == ""
				@to_invitees = "me"
			else
				@to_invitees = @to_invitees + " and me"
			end

			if User.find_by(email: formatted_email).present?
				@user = User.find_by(email: formatted_email)
				invite!@user
				@invitation = Invitation.find_by(invitee_id: @user.id, gathering_id: self.id)
				if @user.phone.present?
					@dtl = ""
					if self.date.present? 
						@dtl = "on " + self.date.strftime("%a, %b %e") 
						if self.time.present? 
							@dtl = @dtl + " " + self.time.strftime("%l:%M%p")
						end
					elsif self.time.present? 
						@dtl = "at " + self.time.strftime("%l:%M%p")
					end 
					if self.location.present?
						@dtl = @dtl + " at " + self.location
					end
					if self.more_details.present?						
						@det = "where " + user.name.split(' ').first + " has provided more details"
					else
						@det = "for details"
					end
					@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
					message = @client.account.messages.create(
						body: "#{activity} #{@dtl}? #{user.name} invited you - #{tilt}/#{invitees.count} invitees must join for activity to take off. REPLY 'Y#{@invitation.id}' to join or go to bloon.us #{@det}",
					    to: @user.phone,
					    from: ENV['TWILIO_MAIN'])
					puts message.from
					puts message.to
					puts message.body
				else
					UserMailer.invitation_email(@user, self, @invitation, user, @to_invitees).deliver
				end
			else
				first_password = SecureRandom.urlsafe_base64(10)
				@user = User.create!(name: email_name, email: formatted_email, password: first_password, password_confirmation: first_password)
				invite!@user
				@invitation = Invitation.find_by(invitee_id: @user.id, gathering_id: self.id)
				UserMailer.invitation_email(@user, self, @invitation, user, @to_invitees).deliver				
			end
		end
		
		formatted_invited = invited
		invitees.each do |invitee|
			if invitee.split('@').last == "gmail.com"
				formatted_invitee = invitee.split('@').first.gsub(".","") + "@" + invitee.split('@').last
				formatted_invited = formatted_invited.gsub(invitee,formatted_invitee)
			end
		end
		self.update_attributes(invited_no: formatted_invited)
		self.update_attributes(invited: (user.email + " " + formatted_invited))
		invitees = invited.downcase.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i)
		invitees.each do |invitee|
			@user = User.find_by(email: invitee)
			invitees.each do |n|
				other_user = User.find_by(email: n)
				if @user != other_user && @user.not_friend?(other_user)
					@user.friend!(other_user)
				end
			end
		end
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
			@joining_user_name_or_email = @joining_user.name.split(' ').first
		else
			@joining_user_name_or_email = @joining_user.email.split(/[.@]/).first.capitalize
		end				

		@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
			
		if @gather.num_joining < (@gather.tilt + 1)
			message = @client.account.messages.create(
				body: "Great, we've marked you down as interested in #{@gather.activity[0,1].downcase + @gather.activity[1..-1]} on bloon.us. You'll get a text if this takes off",
			    to: @joining_user.phone,
			    from: ENV['TWILIO_MAIN'])
			puts message.from

			@gather.update_attributes(details: ("#{@gather.details} <br>To #{@joining_user_name_or_email}: Great, we've marked you down as interested in #{@gather.activity[0,1].downcase + @gather.activity[1..-1]} on bloon.us. You'll get a text if this takes off (#{Time.now.localtime("-07:00").strftime("%m/%d %I:%M%p PT")}) "))

			message = @client.account.messages.create(
				body: "#{@joining_user.name} just joined you for #{@gather.activity[0,1].downcase + @gather.activity[1..-1]} on bloon.us. If #{@gather.tilt + 1 - @gather.num_joining} more join, you will be put in a group chat",
			    to: User.find_by(id: user_id).phone,
			    from: ENV['TWILIO_MAIN'])
			puts message.from

		elsif @gather.num_joining == (@gather.tilt + 1)

			# Expire existing Gather numbers?
			Gather.where("expire IS NOT NULL").pluck(:id).each  do |g|
				expiring_gather = Gather.find_by(id: g)
				if expiring_gather.expire.at(0.1) == "Y" && ( ( Time.now - Time.parse(expiring_gather.expire.gsub("Y","")) ) > 60*60*24 )
					# if it's been > 1 day since receiving warning
					expiring_gather.update_attributes(expire: nil, completed: Time.now)
					Invitation.where(gathering_id: expiring_gather.id, status: "Yes").pluck(:id).each do |i|
						Invitation.find_by(id: i).update_attributes(number_used: nil)
					end
				elsif expiring_gather.expire.at(0.1) != "Y" && ( ( Time.now - Time.parse(expiring_gather.expire) ) > 60*60*24*6 )
					# if it's been > 6 days since tilting
					add_y = "Y" + Time.now.to_s
					expiring_gather.update_attributes(expire: add_y)
					Invitation.where(gathering_id: expiring_gather.id, status: "Yes").pluck(:id).each do |i|
						expiring_invitation = Invitation.find_by(id: i)

						message = @client.account.messages.create(
							body: "Bloon: Group text for #{expiring_gather.activity} expires in 24 hrs. Reply 'E' to extend. Organizer can end group texts anytime by replying 'X'",
						    to: User.find_by(id: expiring_invitation.invitee_id).phone,
						    from: expiring_invitation.number_used)
						puts message.from
					end
					expiring_gather.update_attributes(details: ("#{expiring_gather.details} <br>Bloon: Group text for #{expiring_gather.activity} expires in 24 hrs. Reply 'E' to extend. Organizer can end group texts anytime by replying 'X' (#{Time.now.localtime("-07:00").strftime("%m/%d %I:%M%p PT")}) "))
				end
			end
			@gather.update_attributes(expire: Time.now)

			invited_yes_array.each do |n|
				invited_yes_user = User.find_by(email: n)
				@invited_yes_user_invitation = Invitation.find_by(gathering_id: @gather.id, invitee_id: invited_yes_user.id)
				if @invited_yes_user_invitation.number_used.nil?
					all_numbers_used = invited_yes_user.reverse_invitations.pluck(:number_used)
					@number_used = (Tnumber.pluck(:tphone) - all_numbers_used).sample
					if @number_used.blank?
						@numbers = @client.account.available_phone_numbers.get('US').local.list(:area_code => "415")
						@number_used = @numbers[0].phone_number
						@number = @client.account.incoming_phone_numbers.create(:phone_number => @number_used)	# Purchase the number
						Tnumber.create!(tphone: @number_used)
						@number.update(:sms_method => "GET", :sms_url => "http://bloon.us/twilio/respond")
					end
					@invited_yes_user_invitation.update_attributes!(number_used: @number_used)
				else
					@number_used = @invited_yes_user_invitation.number_used
				end

				@people_joining_less_user = ""
				(invited_yes_array - (invited_yes_user.email.split(" "))).each do |m|
					m = User.find_by(email: m)
					if m.name.present?
						if @people_joining_less_user == ""
							@people_joining_less_user = m.name.split(' ').first
						else
							@people_joining_less_user = @people_joining_less_user + ", " + m.name.split(' ').first
						end
					else
						if @people_joining_less_user == ""
							@people_joining_less_user = m.email.split(/[.@]/).first.capitalize
						else
							@people_joining_less_user = @people_joining_less_user + ", " + m.email.split(/[.@]/).first.capitalize
						end
					end
				end
				
				message = @client.account.messages.create(
					body: "Bloon: #{@gather.activity} has taken off with #{@people_joining_less_user} and you! Reply to this group text to plan the details together",
				    to: invited_yes_user.phone,
				    from: @number_used)
				puts message.from
			end

			@gather.update_attributes(details: ("#{@gather.details} <br>Bloon: #{@gather.activity} has taken off with #{User.find_by(email: invited_yes_array.last).name.split(' ').first}, #{@people_joining_less_user}! Reply to this group text to plan the details together (#{Time.now.localtime("-07:00").strftime("%m/%d %I:%M%p PT")}) "))

		elsif @gather.num_joining > (@gather.tilt + 1)
			if @this_invitation.number_used.nil?
				all_numbers_used = @joining_user.reverse_invitations.pluck(:number_used)
				@number_used = (Tnumber.pluck(:tphone) - all_numbers_used).sample
					if @number_used.blank?
						@numbers = @client.account.available_phone_numbers.get('US').local.list(:area_code => "415")
						@number_used = @numbers[0].phone_number
						@number = @client.account.incoming_phone_numbers.create(:phone_number => @number_used)	# Purchase the number
						Tnumber.create!(tphone: @number_used)
						@number.update(:sms_method => "GET", :sms_url => "http://bloon.us/twilio/respond")
					end
				@this_invitation.update_attributes(number_used: @number_used)
			else
				@number_used = @this_invitation.number_used
			end

			@people_joining_less_user = ""
			(invited_yes_array - @joining_user.email.split(" ")).each do |n|
				invited_yes_user = User.find_by(email: n)
				@invited_yes_user_invitation = Invitation.find_by(gathering_id: @gather.id, invitee_id: invited_yes_user.id)
				
				message = @client.account.messages.create(
					body: "Bloon: #{@joining_user_name_or_email} has joined too and has been added to this group text! Catch #{@joining_user_name_or_email} up on the details",
				    to: invited_yes_user.phone,
				    from: @invited_yes_user_invitation.number_used)
				puts message.from

				if invited_yes_user.name.present?
					if @people_joining_less_user == ""
						@people_joining_less_user = invited_yes_user.name.split(' ').first
					else
						@people_joining_less_user = @people_joining_less_user + ", " + invited_yes_user.name.split(' ').first
					end
				else
					if @people_joining_less_user == ""
						@people_joining_less_user = invited_yes_user.email.split(/[.@]/).first.capitalize
					else
						@people_joining_less_user = @people_joining_less_user + ", " + invited_yes_user.email.split(/[.@]/).first.capitalize
					end
				end
			end

			message = @client.account.messages.create(
				body: "Bloon: #{@gather.activity} is on! You're joining #{@people_joining_less_user} in this group chat (chat history is on bloon.us)",
			    to: @joining_user.phone,
			    from: @number_used)
			puts message.from

			@gather.update_attributes(details: ("#{@gather.details} <br>To #{@joining_user_name_or_email}: Bloon: #{@gather.activity} is on! You're joining #{@people_joining_less_user} in this group chat (chat history is on bloon.us) (#{Time.now.localtime("-07:00").strftime("%m/%d %I:%M%p PT")}) "))
			@gather.update_attributes(details: ("#{@gather.details} <br>Bloon: #{@joining_user_name_or_email} has joined too and has been added to this group text! Catch #{@joining_user_name_or_email} up on the details (#{Time.now.localtime("-07:00").strftime("%m/%d %I:%M%p PT")}) "))

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
			@unjoining_user_name_or_email = @unjoining_user.name.split(' ').first
		else
			@unjoining_user_name_or_email = @unjoining_user.email.split(/[.@]/).first.capitalize
		end

		@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']

		if @gather.num_joining < @gather.tilt
			from_number = ENV['TWILIO_MAIN']
		else
			from_number = @this_invitation.number_used
		end

		message = @client.account.messages.create(
			body: "Sad to see you leave! Reply Y#{@this_invitation.id} to rejoin",
		    to: @unjoining_user.phone,
		    from: from_number)
		puts message.from

		@gather.update_attributes(details: ("#{@gather.details} <br>To #{@unjoining_user_name_or_email}: Sad to see you leave! Reply Y#{@this_invitation.id} to rejoin (#{Time.now.localtime("-07:00").strftime("%m/%d %I:%M%p PT")}) "))

		@this_invitation.update_attributes(number_used: nil)

		if @gather.num_joining >= @gather.tilt			 

			invited_yes_array = @gather.invited_yes.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i)
			invited_yes_array.each do |n|
				invited_yes_user = User.find_by(email: n)
				invited_yes_user_invitation = Invitation.find_by(gathering_id: @gather.id, invitee_id: invited_yes_user.id)				

				message = @client.account.messages.create(
					body: "Bloon: Unfortunately #{@unjoining_user_name_or_email} won't be joining anymore and is now off the group text :(",
				    to: invited_yes_user.phone,
				    from: invited_yes_user_invitation.number_used)
				puts message.from
			end

			@gather.update_attributes(details: ("#{@gather.details} <br>Bloon: Unfortunately #{@unjoining_user_name_or_email} won't be joining anymore and is now off the group texts :( (#{Time.now.localtime("-07:00").strftime("%m/%d %I:%M%p PT")}) "))

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

