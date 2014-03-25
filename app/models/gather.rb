class Gather < ActiveRecord::Base
	belongs_to :user
	has_many :invitations, foreign_key: "gathering_id", dependent: :destroy
	has_many :invitees, through: :invitations
	has_many :updates, dependent: :destroy
	has_many :invite_mores, dependent: :destroy
	has_many :links, foreign_key: "gathering_id", dependent: :destroy
	has_one :calinvite, dependent: :destroy
	before_create do
		self.gen_link = gen_link.gsub("bloon.us/","")
		self.invited = invited.downcase.sub(user.email,"").scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i).uniq.join(" ")
		self.invited_yes = user.email
		self.num_passing = 0
#		if self.tilt == nil || self.tilt == 0
#			self.tilt = 1
#		end
		# if self.activity.blank? && (self.activity_2.present? || self.activity_3.present?)
		# 	if self.activity_2.present?
		# 		self.activity = activity_2
		# 		self.activity_2 = nil
		# 	else
		# 		self.activity = activity_3
		# 		self.activity_3 = nil
		# 	end
		# end
		# if self.date.blank? && self.time.blank? && (self.date_2.present? || self.date_3.present? || self.time_2.present? || self.time_3.present?)
		# 	if self.date_2.present? || self.time_2.present? 
		# 		self.date = date_2
		# 		self.time = time_2
		# 		self.date_2 = nil
		# 		self.time_2 = nil
		# 	else
		# 		self.date = date_3
		# 		self.time = time_3
		# 		self.date_3 = nil
		# 		self.date_3 = nil
		# 	end
		# end
		# if self.location.blank? && (self.location_2.present? || self.location_3.present?)
		# 	if self.location_2.present?
		# 		self.location = location_2
		# 		self.location_2 = nil
		# 	else
		# 		self.location = location_3
		# 		self.location_3 = nil
		# 	end
		# end
	end
	default_scope -> { order('gathers.created_at DESC') }
	validates :activity, presence: true, length: { maximum: 70 }
	# validates :activity_2, length: { maximum: 70 }
	# validates :activity_3, length: { maximum: 70 }
	# validates :location, length: { maximum: 100 }
	# validates :location_2, length: { maximum: 100 }
	# validates :location_3, length: { maximum: 100 }
	validates :user_id, presence: true
#	validate :tilt_must_fall_in_range_of_invited, unless: "tilt.nil?"
	after_create do
		# self.gen_link = String.random_alphanumeric
		links.create!(in_url: self.gen_link, out_url: "/gathers/"+gen_link)
		invitees = invited.downcase.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i)
		self.update_attributes(num_invited: invitees.count)
		self.update_attributes(num_invited: num_invited + 1)
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
					# if Invitation.where(invitee_id: @user.id, sent: "Yes", when_responded: nil).where("when_sent IS NOT NULL").blank?
					# if user hasn't responded to an invite, send reminder, else go ahead and send invitation

						@dtl = self.activity
						if self.date.present? 
							@dtl = @dtl + " on " + self.date.strftime("%a, %b %-e") 
						end

						# if self.activity.present? && self.activity_2.blank? && self.activity_3.blank? 
						# 	@dtl = self.activity
						# else
						# 	@dtl = "Hang out"
						# end
						# if self.date.present? && self.date_2.blank? && self.date_3.blank? 
						# 	@dtl = @dtl + " on " + self.date.strftime("%a, %b %-e") 
						# 	if self.time.present? && self.time_2.blank? && self.time_3.blank? 
						# 		@dtl = @dtl + " @" + self.time.strftime("%-l:%M%p")
						# 	end
						# elsif self.time.present? && self.time_2.blank? && self.time_3.blank? 
						# 	@dtl = @dtl + " at " + self.time.strftime("%-l:%M%p")
						# end 
						# if self.location.present? && self.location_2.blank? && self.location_3.blank? 
						# 	if (self.activity.present? && self.activity_2.blank? && self.activity_3.blank?) || (self.time.present? && self.time_2.blank? && self.time_3.blank?) || (self.date.present? && self.date_2.blank? && self.date_3.blank?)
						# 		@dtl = @dtl + " at " + self.location
						# 	else
						# 		@dtl = @dtl + " at " + self.location
						# 	end
						# end
						# if self.more_details.present?						
						# 	@det = "where " + user.name.split(' ').first + " has provided more details"
						# else
						# 	@det = "for details"
						# end
						# if wait_hours == 0
						# 	@wait = ""
						# else
						# 	@wait = " within #{wait_hours} hours"
						# end
						@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
						message = @client.account.messages.create(
							body: "#{@dtl}? #{user.name} invited you - #{tilt} must join for this to take off. REPLY 'Y' to join or 'N' to pass",
						    to: @user.phone,
						    from: @invitation.number_used)
						puts message.from
						puts message.to
						puts message.body

						# @invitation.update_attributes(sent: "Yes", when_sent: Time.now)
					# else
					# 	# send reminder text to respond to the previous invitation 
					# 	@invitation.update_attributes(sent: "No")
					# 	old_invitation = Invitation.where(invitee_id: @user.id, sent: "Yes", when_responded: nil).where("when_sent IS NOT NULL").last
					# 	@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
					# 		message = @client.account.messages.create(
					# 			body: "You've been invited to another activity via Bloon! To receive it, first respond Y/N to your last invitation (#{old_invitation.gathering.activity} from #{old_invitation.gathering.user.name})",
					# 		    to: @user.phone,
					# 		    from: ENV['TWILIO_MAIN'])
					# 	puts message.from
					# 	puts message.to
					# 	puts message.body
					# 	puts "reminder text"
					# end
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
		self.update_attributes(invited_no: "")
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
		@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
		message = @client.account.messages.create(
			body: "#{self.activity} invitations have been sent! Reply with any updates and we'll let everyone know",
		    to: user.phone,
		    from: Invitation.find_by(gathering_id: self.id, invitee_id: user.id).number_used)
		puts message.from
		puts message.to
		puts message.body
		# activity_1v = "1" if self.activity.present?
		# activity_2v = "1" if self.activity_2.present?
		# activity_3v = "1" if self.activity_3.present?
		# date_1v = "1" if self.date.present? || self.time.present?
		# date_2v = "1" if self.date_2.present? || self.time_2.present?
		# date_3v = "1" if self.date_3.present? || self.time_3.present?
		# location_1v = "1" if self.location.present?
		# location_2v = "1" if self.location_2.present?
		# location_3v = "1" if self.location_3.present?
		
		invitations.find_by(invitee_id: user.id).update(status: "Yes", 
			# activity_1v: activity_1v, 
			# activity_2v: activity_2v, 
			# activity_3v: activity_3v, 
			# date_1v: date_1v, 
			# date_2v: date_2v, 
			# date_3v: date_3v, 
			# location_1v: location_1v, 
			# location_2v: location_2v, 
			# location_3v: location_3v, 
			)
		self.update_attributes(num_joining: 1)
		@calinvite = Calinvite.create!(gather_id: self.id, cal_activity: self.activity, cal_date: self.date, cal_time: self.time, cal_location: self.location)

		tracker = Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
		tracker.track(user.id, 'Created Activity', {
			'Activity ID' => self.id,
			'Activity' => self.activity,
			'Tilt' => self.tilt
			})
	end

	def invited_already?(other_user)
		invitations.find_by(invitee_id: other_user.id)
	end

	def invite!(other_user)
		invited_user_invitation = invitations.create!(invitee_id: other_user.id)
		short_link = String.random_alphanumeric
		links.create!(in_url: short_link, out_url: "/gathers/"+short_link, invitation_id: invited_user_invitation.id)

		if invited_user_invitation.number_used.nil?
			all_numbers_used = other_user.reverse_invitations.pluck(:number_used)
			@number_used = (Tnumber.pluck(:tphone) - all_numbers_used  - ENV['TWILIO_MAIN'].split('xxx')).sample
			if @number_used.blank?
				@numbers = @client.account.available_phone_numbers.get('US').local.list(:area_code => "415")
				@number_used = @numbers[0].phone_number
				@number = @client.account.incoming_phone_numbers.create(:phone_number => @number_used)	# Purchase the number
				Tnumber.create!(tphone: @number_used)
				@number.update(:sms_method => "GET", :sms_url => "http://bloon.us/twilio/respond")
			end
			invited_user_invitation.update_attributes!(number_used: @number_used)
		end

		tracker = Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
		tracker.track(other_user.id, 'Invited', {
			'Activity ID' => self.id,
			'Activity' => self.activity,
			'Invitation ID' => Invitation.find_by(gathering_id: self.id, invitee_id: other_user.id).id
			})
	end

	def uninvite!(other_user)
		invitations.find_by(invitee_id: other_user.id).destroy
	end

	def increase_num_joining!(invitation_id)
		@this_invitation = Invitation.find_by(id: invitation_id)
		# Gather.increment_counter(:num_joining, @this_invitation.gathering_id)
		@gather = Gather.find_by(id: @this_invitation.gathering_id)
		@joining_user = User.find_by(id: @this_invitation.invitee_id)
		@gather.update_attributes(num_joining: @gather.num_joining + 1)
		@gather.update_attributes(invited_yes: (@gather.invited_yes + " " + @joining_user.email))
		# was previously not joining
		if @gather.invited_no.include?(@joining_user.email)
			@gather.update_attributes(invited_no: @gather.invited_no.sub(@joining_user.email,''))
			@gather.update_attributes(num_passing: @gather.num_passing - 1)
		end
		invited_yes_array = @gather.invited_yes.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i).uniq
		@people_joining_less_user = ""
		if @joining_user.name.present?
			@joining_user_name_or_email = @joining_user.name.split(' ').first
		else
			@joining_user_name_or_email = @joining_user.email.split(/[.@]/).first.capitalize
		end

		if not @gather.invited.include?(@joining_user.email)
			@gather.invited.downcase.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i).each do |invitee|
				other_user = User.find_by(email: invitee)
				if @joining_user.not_friend?(other_user)
					@joining_user.friend!(other_user)
					other_user.friend!(@joining_user)
				end
			end
			new_invited = [@gather.invited, @joining_user.email].join(" ")
			@gather.update_attributes(invited: new_invited)
		end

		# if @gather.activity.present? && ( @gather.activity_2 == "" || @gather.activity_2.nil? ) && ( @gather.activity_3 == "" || @gather.activity_3.nil? )
		# 	gather_name = @gather.activity
		# else
		# 	if @gather.location.present? && ( @gather.location_2 == "" || @gather.location_2.nil? ) && ( @gather.location_3 == "" || @gather.location_3.nil? )
		# 		gather_name = "Hang out at " + @gather.location
		# 	else
		# 		if @gather.date.present? && @gather.date_2.nil? && @gather.date_3.nil?
		# 			gather_name = "Hang out on " + @gather.date.strftime("%a, %b %-e")
		# 		else
		# 			if @gather.time.present? && @gather.time_2.nil? && @gather.time_3.nil?
		# 				gather_name = "Hang out at " + @gather.time.strftime("%-l:%M%p")
		# 			else
		# 				gather_name = "Hang out with " + @gather.user.name.split(' ').first
		# 			end
		# 		end
		# 	end
		# end
		if @gather.date.present?
			gather_name = @gather.activity + " on " + @gather.date.strftime("%a, %b %-e")
		else
			gather_name = @gather.activity
		end


		@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
			
		if @gather.num_joining < (@gather.tilt)
			message = @client.account.messages.create(
				body: "Bloon: Great, we've marked you down as interested in: #{@gather.activity}! We'll send you a group text if this takes off",
			    to: @joining_user.phone,
			    from: @this_invitation.number_used)
			puts message.from

			# @gather.update_attributes(details: ("#{@gather.details} <br>To #{@joining_user_name_or_email}: Great, we've marked you down as interested in #{@gather.activity[0,1].downcase + @gather.activity[1..-1]} on bloon.us. You'll get a text if this takes off "))

			message = @client.account.messages.create(
				body: "#{@joining_user.name} just joined you for #{gather_name} on bloon.us. If #{@gather.tilt - @gather.num_joining} more join, you will be put in a group chat",
			    to: User.find_by(id: user_id).phone,
			    from: Invitation.find_by(gathering_id: @gather.id, invitee_id: user_id).number_used)
			puts message.from

		elsif @gather.num_joining == (@gather.tilt)

			# Expire existing Gather numbers that have tilted
			Gather.where("expire IS NOT NULL").pluck(:id).each  do |g|
				expiring_gather = Gather.find_by(id: g)
				if expiring_gather.expire.at(0.1) == "Y" && ( ( Time.now - Time.parse(expiring_gather.expire.gsub("Y","")) ) > 60*60*24 )
					# if it's been > 1 day since receiving warning
					expiring_gather.update_attributes(expire: nil, completed: Time.now)
					Invitation.where(gathering_id: expiring_gather.id).pluck(:id).each do |i|
						Invitation.find_by(id: i).update_attributes(number_used: nil)
					end
					# update invitations that haven't been answered
					# Invitation.where(gathering_id: expiring_gather.id, status: "NA").pluck(:id).each do |i|
					# 	Invitation.find_by(id: i).update_attributes(sent: "Never")
					# end
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
					expiring_gather.update_attributes(details: ("#{expiring_gather.details} <br>Bloon: Group text for #{expiring_gather.activity} expires in 24 hrs. Reply 'E' to extend. Organizer can end group texts anytime by replying 'X' "))
				end
			end

			# Expire for Gathers that haven't tilted
			Gather.where(completed: nil).where(expire: nil).pluck(:id).each  do |g|
				expiring_gather = Gather.find_by(id: g)
				if Time.now - expiring_gather.created_at > 60*60*24*7
					# Complete the gather
					expiring_gather.update_attributes(expire: nil, completed: Time.now)
					# Erase phone #s
					Invitation.where(gathering_id: expiring_gather.id).pluck(:id).each do |i|
						Invitation.find_by(id: i).update_attributes(number_used: nil)
					end
				end
			end

			@gather.update_attributes(expire: Time.now)

			invited_yes_array.each do |n|
				invited_yes_user = User.find_by(email: n)
				@invited_yes_user_invitation = Invitation.find_by(gathering_id: @gather.id, invitee_id: invited_yes_user.id)
				# if @invited_yes_user_invitation.number_used.nil?
				# 	all_numbers_used = invited_yes_user.reverse_invitations.pluck(:number_used)
				# 	@number_used = (Tnumber.pluck(:tphone) - all_numbers_used).sample
				# 	if @number_used.blank?
				# 		@numbers = @client.account.available_phone_numbers.get('US').local.list(:area_code => "415")
				# 		@number_used = @numbers[0].phone_number
				# 		@number = @client.account.incoming_phone_numbers.create(:phone_number => @number_used)	# Purchase the number
				# 		Tnumber.create!(tphone: @number_used)
				# 		@number.update(:sms_method => "GET", :sms_url => "http://bloon.us/twilio/respond")
				# 	end
				# 	@invited_yes_user_invitation.update_attributes!(number_used: @number_used)
				# else
				# 	@number_used = @invited_yes_user_invitation.number_used
				# end
				@number_used = @invited_yes_user_invitation.number_used

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
					body: "Bloon: #{gather_name} has taken off with #{@people_joining_less_user} and you! Reply to this group text to plan the details together",
				    to: invited_yes_user.phone,
				    from: @number_used)
				puts message.from
			end

			# if Invitation.find_by(invitee_id: @gather.user_id, gathering_id: @gather.id).number_used.present?
			# 	message = @client.account.messages.create(
			# 			body: "As the organizer, you can send a calendar invite to current & future participants when you finalize the details - just follow this link bloon.us/#{Invitation.find_by(invitee_id: @gather.user_id, gathering_id: @gather.id).link.in_url}",
			# 		    to: @gather.user.phone,
			# 		    from: Invitation.find_by(invitee_id: @gather.user_id, gathering_id: @gather.id).number_used)
			# 		puts message.from
			# end

			@gather.update_attributes(details: ("#{@gather.details} <br>Bloon: #{gather_name} has taken off with #{User.find_by(email: invited_yes_array.last).name.split(' ').first}, #{@people_joining_less_user}! Reply to this group text to plan the details together "))

		elsif @gather.num_joining > (@gather.tilt)
			# if @this_invitation.number_used.nil?
			# 	all_numbers_used = @joining_user.reverse_invitations.pluck(:number_used)
			# 	@number_used = (Tnumber.pluck(:tphone) - all_numbers_used).sample
			# 		if @number_used.blank?
			# 			@numbers = @client.account.available_phone_numbers.get('US').local.list(:area_code => "415")
			# 			@number_used = @numbers[0].phone_number
			# 			@number = @client.account.incoming_phone_numbers.create(:phone_number => @number_used)	# Purchase the number
			# 			Tnumber.create!(tphone: @number_used)
			# 			@number.update(:sms_method => "GET", :sms_url => "http://bloon.us/twilio/respond")
			# 		end
			# 	@this_invitation.update_attributes(number_used: @number_used)
			# else
			# 	@number_used = @this_invitation.number_used
			# end
			@number_used = @this_invitation.number_used

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
				body: "Bloon: #{gather_name} is on! You're joining #{@people_joining_less_user} in this group chat (chat history is on bloon.us)",
			    to: @joining_user.phone,
			    from: @number_used)
			puts message.from

			@gather.update_attributes(details: ("#{@gather.details} <br>To #{@joining_user_name_or_email}: Bloon: #{gather_name} is on! You're joining #{@people_joining_less_user} in this group chat (chat history is on bloon.us) "))
			@gather.update_attributes(details: ("#{@gather.details} <br>Bloon: #{@joining_user_name_or_email} has joined too and has been added to this group text! Catch #{@joining_user_name_or_email} up on the details "))

		end

		# # check to see if joining_user has a backlog of invites
		# if Invitation.where(invitee_id: @joining_user.id, sent: "No").any?
		# 	old_invitation = Invitation.where(invitee_id: @joining_user.id, sent: "No").first
		# 	@dtl = old_invitation.gathering.activity
		# 	if old_invitation.gathering.date.present? 
		# 		@dtl = @dtl + " on " + old_invitation.gathering.date.strftime("%a, %b %-e") 
		# 	end

		# 	@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
		# 	message = @client.account.messages.create(
		# 		body: "#{@dtl}? #{old_invitation.gathering.user.name} invited you - #{old_invitation.gathering.tilt} must join for this to take off. REPLY 'Y' to join or 'N' to pass",
		# 	    to: @joining_user.phone,
		# 	    from: ENV['TWILIO_MAIN'])
		# 	puts message.from
		# 	puts message.to
		# 	puts message.body
		# 	puts "late invitation"

		# 	old_invitation.update_attributes(sent: "Yes", when_sent: Time.now)
		# end

		tracker = Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
		tracker.track(@joining_user.id, 'Joined Activity', {
			'Activity ID' => @gather.id,
			'Activity' => @gather.activity,
			'Invitation ID' => @this_invitation.id
			})

	end

	def decrease_num_joining!(invitation_id)
		@this_invitation = Invitation.find_by!(id: invitation_id)
		@gather = Gather.find_by(id: @this_invitation.gathering_id)
		@unjoining_user = User.find_by(id: @this_invitation.invitee_id)
		@gather.update_attributes(num_passing: @gather.num_passing + 1)
		if @gather.date.present? 
			@dtl = @gather.activity + " on " + @gather.date.strftime("%a, %b %-e") 
		else
			@dtl = @gather.activity
		end

		if @gather.invited_yes.include?(@unjoining_user.email)
			# Was previously joining
			@gather.update_attributes(num_joining: @gather.num_joining - 1)
			# Gather.decrement_counter(:num_joining, @this_invitation.gathering_id)
			@gather.update_attributes(invited_yes: @gather.invited_yes.sub(@unjoining_user.email,''))
			@gather.update_attributes(invited_no: (@gather.invited_no + " " + @unjoining_user.email))

			if @unjoining_user.name.present?
				@unjoining_user_name_or_email = @unjoining_user.name.split(' ').first
			else
				@unjoining_user_name_or_email = @unjoining_user.email.split(/[.@]/).first.capitalize
			end

			@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']

			# if @gather.num_joining + 1 < @gather.tilt
			# 	from_number = ENV['TWILIO_MAIN']
			# else
			# 	from_number = @this_invitation.number_used
			# end

			message = @client.account.messages.create(
				body: "Sad to see you leave #{@gather.activity}! Reply 'Y' to join or reply with a msg for #{@gather.user.name.split(' ').first}",
			    to: @unjoining_user.phone,
			    from: @this_invitation.number_used)
			puts message.from
			puts "pass1"

			@gather.update_attributes(details: ("#{@gather.details} <br>To #{@unjoining_user_name_or_email}: Sad to see you leave #{@gather.activity}! Reply 'Y' to join or reply with a msg for #{@gather.user.name.split(' ').first}"))

			# @this_invitation.update_attributes(number_used: nil)

			if @gather.num_joining + 1 >= @gather.tilt			 
			# Tilted already, including untilted now; let already joining group know
				invited_yes_array = @gather.invited_yes.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i).uniq
				invited_yes_array.each do |n|
					invited_yes_user = User.find_by(email: n)
					invited_yes_user_invitation = Invitation.find_by(gathering_id: @gather.id, invitee_id: invited_yes_user.id)				

					message = @client.account.messages.create(
						body: "Bloon: Unfortunately #{@unjoining_user_name_or_email} won't be joining anymore and is now off the group text :(",
					    to: invited_yes_user.phone,
					    from: invited_yes_user_invitation.number_used)
					puts message.from
					puts "pass2"
				end

				@gather.update_attributes(details: ("#{@gather.details} <br>Bloon: Unfortunately #{@unjoining_user_name_or_email} won't be joining anymore and is now off the group texts :( "))
			else
			# Hasn't tilted yet 
				if ( @gather.tilt > ( @gather.num_invited - @gather.num_passing ) ) && @gather.num_invited >= @gather.tilt
				# Can't tilt (too many friends have passed); tell everyone to invite more friends
					Invitation.where(gathering_id: @gather.id, status: "Yes").pluck(:id).each do |i|
						@user = User.find_by(id: Invitation.find_by(id: i).invitee_id)
						if @user.id == @gather.user.id
						# for the organizer
							@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
							message = @client.account.messages.create(
								body: "Unfortunately #{@unjoining_user.name} is passing on #{@dtl}. Not enough friends are left for this to tilt - try inviting a few more friends",
							    to: @user.phone,
							    from: Invitation.find_by(gathering_id: @gather.id, invitee_id: @user.id).number_used)
							puts message.from
							puts message.to
							puts message.body
							puts "pass23"
						elsif @user.phone.present?
						# for non-organizers
							@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
							message = @client.account.messages.create(
								body: "Looks like not enough friends can join #{@dtl} for it to tilt - try inviting a few more friends",
							    to: @user.phone,
							    from: Invitation.find_by(gathering_id: @gather.id, invitee_id: @user.id).number_used)
							puts message.from
							puts message.to
							puts message.body
							puts "pass3"
						end
					end
					Invitation.where(gathering_id: @gather.id, status: "NA").pluck(:id).each do |i|
						@user = User.find_by(id: Invitation.find_by(id: i).invitee_id)
						if @user.phone.present?
							@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
							message = @client.account.messages.create(
								body: "Looks like not enough friends can join #{@dtl} for it to tilt - try inviting a few more friends",
							    to: @user.phone,
							    from: Invitation.find_by(gathering_id: @gather.id, invitee_id: @user.id).number_used)
							puts message.from
							puts message.to
							puts message.body
							puts "pass4"
						end
					end
					@gather.update_attributes(details: ("#{@gather.details} <br>Bloon: Looks like not enough friends can join #{@dtl} for it to tilt - try inviting a few more friends"))
				else
				# Can still tilt; just let organizer know
					@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
					message = @client.account.messages.create(
						body: "Unfortunately #{@unjoining_user.name} is passing on #{@dtl} :(",
					    to: @gather.user.phone,
					    from: Invitation.find_by(gathering_id: @gather.id, invitee_id: @gather.user.id).number_used)
					puts message.from
					puts message.to
					puts message.body
					puts "pass5"
				end
			end
		else
			# Passing as the first action
			@gather.update_attributes(invited_no: (@gather.invited_no + " " + @unjoining_user.email))

			if @unjoining_user.name.present?
				@unjoining_user_name_or_email = @unjoining_user.name.split(' ').first
			else
				@unjoining_user_name_or_email = @unjoining_user.email.split(/[.@]/).first.capitalize
			end

			@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']

			message = @client.account.messages.create(
				body: "Thanks for letting #{@gather.user.name.split(' ').first} know that you're passing on: #{@gather.activity}! Reply 'Y' to join or reply with a msg for #{@gather.user.name.split(' ').first}",
			    to: @unjoining_user.phone,
			    from: @this_invitation.number_used)
			puts message.from
			puts "pass6"

			@gather.update_attributes(details: ("#{@gather.details} <br>To #{@unjoining_user_name_or_email}: Thanks for letting #{@gather.user.name.split(' ').first} know that you're passing! Reply 'Y' to join or reply with a msg for #{@gather.user.name.split(' ').first}"))

			if ( @gather.tilt > ( @gather.num_invited - @gather.num_passing ) ) && @gather.num_invited >= @gather.tilt
			# Can't tilt (too many friends have passed); tell everyone to invite more friends
				puts "pass67"
				Invitation.where(gathering_id: @gather.id, status: "Yes").pluck(:id).each do |i|
					@user = User.find_by(id: Invitation.find_by(id: i).invitee_id)
					if @user.id == @gather.user.id
					# for the organizer
						@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
						message = @client.account.messages.create(
							body: "Unfortunately #{@unjoining_user.name} is passing on #{@dtl}. Not enough friends are left for this to tilt - try inviting a few more friends",
						    to: @user.phone,
						    from: Invitation.find_by(gathering_id: @gather.id, invitee_id: @user.id).number_used)
						puts message.from
						puts message.to
						puts message.body
						puts "pass677"
					elsif @user.phone.present?
						@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
						message = @client.account.messages.create(
							body: "Looks like not enough friends can join #{@dtl} for it to tilt - try inviting a few more friends",
						    to: @user.phone,
						    from: Invitation.find_by(gathering_id: @gather.id, invitee_id: @user.id).number_used)
						puts message.from
						puts message.to
						puts message.body
						puts "pass7"
					end
				end
				Invitation.where(gathering_id: @gather.id, status: "NA").pluck(:id).each do |i|
					@user = User.find_by(id: Invitation.find_by(id: i).invitee_id)
					if @user.phone.present?
						@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
						message = @client.account.messages.create(
							body: "Looks like not enough friends can join #{@dtl} for it to tilt - try inviting a few more friends",
						    to: @user.phone,
						    from: Invitation.find_by(gathering_id: @gather.id, invitee_id: @user.id).number_used)
						puts message.from
						puts message.to
						puts message.body
						puts "pass8"
					end
				end
				@gather.update_attributes(details: ("#{@gather.details} <br>Bloon: Looks like not enough friends can join #{@dtl} for it to tilt - try inviting a few more friends"))
			else
			# Can still tilt; just let organizer know
				@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
				message = @client.account.messages.create(
					body: "Unfortunately #{@unjoining_user.name} is passing on #{@dtl} :(",
				    to: @gather.user.phone,
				    from: Invitation.find_by(gathering_id: @gather.id, invitee_id: @gather.user.id).number_used)
				puts message.from
				puts message.to
				puts message.body
				puts "pass9"
			end
		end

		# # check to see if joining_user has a backlog of invites
		# if Invitation.where(invitee_id: @unjoining_user.id, sent: "No").any?
		# 	old_invitation = Invitation.where(invitee_id: @unjoining_user.id, sent: "No").first
		# 	@dtl = old_invitation.gathering.activity
		# 	if old_invitation.gathering.date.present? 
		# 		@dtl = @dtl + " on " + old_invitation.gathering.date.strftime("%a, %b %-e") 
		# 	end

		# 	@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
		# 	message = @client.account.messages.create(
		# 		body: "#{@dtl}? #{old_invitation.gathering.user.name} invited you - #{old_invitation.gathering.tilt} must join for this to take off. REPLY 'Y' to join or 'N' to pass",
		# 	    to: @unjoining_user.phone,
		# 	    from: ENV['TWILIO_MAIN'])
		# 	puts message.from
		# 	puts message.to
		# 	puts message.body
		# 	puts "late invitation"

		# 	old_invitation.update_attributes(sent: "Yes", when_sent: Time.now)
		# end

		tracker = Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
		tracker.track(@unjoining_user.id, 'Passed Activity', {
			'Activity ID' => @gather.id,
			'Activity' => @gather.activity,
			'Invitation ID' => @this_invitation.id
			})

	end

	def gather_friends(current_user)
		self.invitations.pluck(:invitee_id).each do |invitee|
			a_user = User.find_by(id: invitee)
			if a_user != current_user && a_user.not_friend?(current_user)
				a_user.friend!(current_user)
				current_user.friend!(a_user)
			end
		end
	end

	def tilt_must_fall_in_range_of_invited		
		if tilt > (invited.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i).uniq.count)
			# errors.add(:tilt, "- Invite #{tilt - invited.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i).uniq.count} more people for lift off number to be valid")
		elsif tilt < 0
			errors.add(:tilt, "- Can't lift off with negative people...")
		end
	end

	def self.from_gathers_invited_to(user)
		gatherings = user.gatherings
	end

	def to_param
		gen_link
	end

	def String.random_alphanumeric(size=5)
  		s = ""
		size.times { s << (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }
  		s
	end
end