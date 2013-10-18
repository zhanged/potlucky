class InviteMore < ActiveRecord::Base
	belongs_to :gather
	validates :gather_id, presence: true
	validates :user_id, presence: true
	validates :more_invitees, presence: true
	after_create do
		@gather = Gather.find_by(id: gather_id)
		if @gather.tilt == nil
			@gather.update_attributes(tilt: 1)
			@gather.update_attributes(invited: @gather.user.email)
		end
		# cleaning up emails, gmails
		invitees = more_invitees.downcase.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i).uniq
		formatted_invited = invitees.join(" ")
		invitees.each do |invitee|
			if invitee.split('@').last == "gmail.com"
				formatted_invitee = invitee.split('@').first.gsub(".","") + "@" + invitee.split('@').last
				formatted_invited = formatted_invited.gsub(invitee,formatted_invitee)
			end
		end
		invitees = formatted_invited.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i) - @gather.invited.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i)
		formatted_invited = invitees.join(" ")

		# udpate Gather
		@gather.update_attributes(invited: @gather.invited + " " + formatted_invited)
		@gather.update_attributes(invited_no: @gather.invited_no + " " + formatted_invited)
		@gather.update_attributes(num_invited: @gather.num_invited + invitees.count)
		
		# Creating invitations
		invitees.each do |invitee|
			email_name = invitee.split(/[.@]/).first.capitalize
			formatted_email = invitee
			
			@to_invitees = ""
			@gather.invited.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i).each do |i|
				i_email = i
				if formatted_email != i_email && User.find_by(id: self.user_id).email != i_email
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
				@gather.invite!@user
				@invitation = Invitation.find_by(invitee_id: @user.id, gathering_id: @gather.id)
				if @user.phone.present?
					@dtl = ""
					if @gather.date.present? 
						@dtl = "on " + @gather.date.strftime("%a, %b %e") 
						if @gather.time.present? 
							@dtl = @dtl + " " + @gather.time.strftime("%l:%M%p")
						end
					elsif @gather.time.present? 
						@dtl = "at " + @gather.time.strftime("%l:%M%p")
					end 
					if @gather.location.present?
						if @gather.time.present? || @gather.date.present?
							@dtl = @dtl + " at " + @gather.location
						else
							@dtl = "at " + @gather.location
						end
					end
					if @dtl != ""
						@dtl = " " + @dtl
					end
					if @gather.more_details.present?						
						@det = "where " + User.find_by(id: self.user_id).name.split(' ').first + " has provided more details"
					else
						@det = "for details"
					end
					@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
					message = @client.account.messages.create(
						body: "#{@gather.activity}#{@dtl}? #{User.find_by(id: self.user_id).name} invited you - #{@gather.tilt}/#{@gather.num_invited} invitees must join for activity to take off. REPLY 'Y#{@invitation.id}' to join or go to bloon.us #{@det}",
					    to: @user.phone,
					    from: ENV['TWILIO_MAIN'])
					puts message.from
					puts message.to
					puts message.body
				else
					UserMailer.invitation_email(@user, @gather, @invitation, User.find_by(id: self.user_id), @to_invitees).deliver
				end
			else
				first_password = SecureRandom.urlsafe_base64(10)
				@user = User.create!(name: email_name, email: formatted_email, password: first_password, password_confirmation: first_password)
				@gather.invite!@user
				@invitation = Invitation.find_by(invitee_id: @user.id, gathering_id: @gather.id)
				UserMailer.invitation_email(@user, @gather, @invitation, User.find_by(id: self.user_id), @to_invitees).deliver				
			end
		end

		# Create Update
		new_names = ""
		invitees.each do |n|
			if new_names == ""
				new_names = User.find_by(email: n).name
			else
				new_names = User.find_by(email: n).name + ", " + new_names
			end
		end
		content = "I've invited " + new_names
		Update.create!(gather_id: self.gather_id, user_id: self.user_id, content: content)

		# Creating Friendships
		invitees = @gather.invited.downcase.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i)
		invitees.each do |invitee|
			@user = User.find_by(email: invitee)
			invitees.each do |n|
				other_user = User.find_by(email: n)
				if @user != other_user && @user.not_friend?(other_user)
					@user.friend!(other_user)
				end
			end
		end
	end
end