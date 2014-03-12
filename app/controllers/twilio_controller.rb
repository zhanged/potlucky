class TwilioController < ApplicationController
	BASE_URL = "http://bloon.us/twilio/respond"
  
    def respond
    	@from = params[:From]
    	@to = params[:To]
    	@formatted_phone = @from.gsub("+1","")
    	@body = params[:Body]
    	@invitation_id = @body.split(' ').first.gsub("Y","")

    	

    	# Y# Responses:
    	if @body.downcase == "y" && @to == ENV['TWILIO_MAIN']
    	# if "Y" and to the Main #, find invitation through From # and join, then check backlog
    		if User.find_by(phone: @formatted_phone).present?
    			@user = User.find_by(phone: @formatted_phone)
    			if Invitation.where(invitee_id: @user.id, sent: "Yes", when_responded: nil).where("when_sent IS NOT NULL").present?
    				@invitation = Invitation.where(invitee_id: @user.id, sent: "Yes", when_responded: nil).where("when_sent IS NOT NULL").first
					@user.join!(@invitation.id)
					Gather.find_by(id: @invitation.gathering_id).increase_num_joining!(@invitation.id)
				else
					@invitation = Invitation.where(invitee_id: @user.id, sent: "Yes").where("when_responded IS NOT NULL").order(:when_responded).last
					if @invitation.status == "Yes"
				    	@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
						message = @client.account.messages.create(
							body: "Great, we've already marked you down as joining: #{@invitation.gathering.activity}",
						    to: @user.phone,
						    from: ENV['TWILIO_MAIN'])
						puts message.from	
					else 						
						@user.join!(@invitation.id)
						Gather.find_by(id: @invitation.gathering_id).increase_num_joining!(@invitation.id)
						"Switched from no to yes via text"
					end
				end
			end

    	elsif @body.downcase == "n" && @to == ENV['TWILIO_MAIN']
    	# if "N" and to the Main #, find invitation through From # and join, then check backlog
    		if User.find_by(phone: @formatted_phone).present?
    			@user = User.find_by(phone: @formatted_phone)
    			if Invitation.where(invitee_id: @user.id, sent: "Yes", when_responded: nil).where("when_sent IS NOT NULL").present?
    				@invitation = Invitation.where(invitee_id: @user.id, sent: "Yes", when_responded: nil).where("when_sent IS NOT NULL").first
					@user.unjoin!(@invitation.id)
					Gather.find_by(id: @invitation.gathering_id).decrease_num_joining!(@invitation.id)
				else
					@invitation = Invitation.where(invitee_id: @user.id, sent: "Yes").where("when_responded IS NOT NULL").order(:when_responded).last
					if @invitation.status == "No"
				    	@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
						message = @client.account.messages.create(
							body: "Aw, we've already marked you down as passing: #{@invitation.gathering.activity}",
						    to: @user.phone,
						    from: ENV['TWILIO_MAIN'])
						puts message.from	
					else 						
						@user.unjoin!(@invitation.id)
						Gather.find_by(id: @invitation.gathering_id).decrease_num_joining!(@invitation.id)
						"Switched from yes to no via text"
					end
				end
			end

    	elsif @body.at(0.1) == "Y" && Invitation.find_by(id: @invitation_id).present?
    		# Matches an invitation
   	    	@invitation = Invitation.find_by(id: @invitation_id)
   	    	@user = User.find_by(id: @invitation.invitee_id)    		

   	    	if Gather.find_by(id: @invitation.gathering_id).completed.present?
				# Y# response when the gathering has already been completed
		    	@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
				message = @client.account.messages.create(
					body: "Oops, this activity has already ended",
				    to: @from,
				    from: @to)
				puts message.from				
   	    	else
	   	    	if @user.phone.blank?
	   	    		# Invitee doesn't have a phone number: record it and join/unjoin. Will be error if wrong new user texts this
		   	    	@user.phone = @formatted_phone
		    		@user.save(validate: false)
					if @invitation.status == "NA"
						@user.join!(@invitation_id)
						Gather.find_by(id: @invitation.gathering_id).increase_num_joining!(@invitation_id)
					else
						@user.unjoin!(@invitation_id)
						Gather.find_by(id: @invitation.gathering_id).decrease_num_joining!(@invitation_id)
					end
				else	
		   	    	# Invitee does have a phone already recorded
		   	    	if (User.find_by(phone: @formatted_phone) != User.find_by(id: Invitation.find_by(id: @invitation_id).invitee_id))
				    	# Phone doesn't match up with invitation's user: Error
				    	@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
						message = @client.account.messages.create(
							body: "Oops, please enter the correct code. For more help, email hello@bloon.us",
						    to: @from,
						    from: @to)
						puts message.from
		   	    	else
		   	    		# Phone does match user's invitation: join / unjoin	
						if @invitation.status != "Yes"
							@user.join!(@invitation_id)
							Gather.find_by(id: @invitation.gathering_id).increase_num_joining!(@invitation_id)
						else
							@user.unjoin!(@invitation_id)
							Gather.find_by(id: @invitation.gathering_id).decrease_num_joining!(@invitation_id)
						end
			    	end
				end
			end			

		# Incorrect phone number
		elsif @body.downcase == "pop22" && @to == ENV['TWILIO_MAIN']
			@user = User.find_by(phone: @formatted_phone)
			Invitation.where(invitee_id: @user.id, status: "Yes").pluck(:id).each do |i|
				@user.unjoin!(i) # Wrong phone number still gets the leaving gather text
				Gather.find_by(id: Invitation.find_by(id: i).gathering_id).decrease_num_joining!(i)
			end
   	    	@user.phone = nil
    		@user.save(validate: false)

		# Extending the group chat
		elsif @body.downcase == "e" && Invitation.find_by(number_used: @to, invitee_id: User.find_by(phone: @formatted_phone).id).present?
    		@invitation = Invitation.find_by(number_used: @to, invitee_id: User.find_by(phone: @formatted_phone).id)
    		@gather = Gather.find_by(id: @invitation.gathering_id)
			@gather.update_attributes(expire: Time.now)
			Invitation.where(gathering_id: @gather.id, status: "Yes").pluck(:id).each do |i|
				expiring_invitation = Invitation.find_by(id: i)

		    	@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
				message = @client.account.messages.create(
					body: "Bloon: This group chat has been extended by 7 days",
				    to: User.find_by(id: expiring_invitation.invitee_id).phone,
				    from: expiring_invitation.number_used)
				puts message.from
			end
			@gather.update_attributes(details: ("#{@gather.details} <br>Bloon: This group chat has been extended by 7 days "))

		# Killing the group chat
		elsif @body.downcase == "x" && Invitation.find_by(number_used: @to, invitee_id: User.find_by(phone: @formatted_phone).id).present?
    		@invitation = Invitation.find_by(number_used: @to, invitee_id: User.find_by(phone: @formatted_phone).id)
    		expiring_gather = Gather.find_by(id: @invitation.gathering_id)
    		if expiring_gather.user.id == @invitation.invitee_id
				Invitation.where(gathering_id: expiring_gather.id, status: "Yes").pluck(:id).each do |i|
					expiring_invitation = Invitation.find_by(id: i)

			    	@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
					message = @client.account.messages.create(
						body: "Bloon: The group chat for #{expiring_gather.activity} has been closed. Visit bloon.us to create another activity!",
					    to: User.find_by(id: expiring_invitation.invitee_id).phone,
					    from: expiring_invitation.number_used)
					puts message.from
				end
				expiring_gather.update_attributes(details: ("#{expiring_gather.details} <br>Bloon: This group chat for #{expiring_gather.activity} has been closed. Visit bloon.us to create another activity! "))

				expiring_gather.update_attributes(expire: nil, completed: Time.now)
				Invitation.where(gathering_id: expiring_gather.id, status: "Yes").pluck(:id).each do |i|
					Invitation.find_by(id: i).update_attributes(number_used: nil)
				end
			end

		# Group chat
		elsif Invitation.find_by(number_used: @to, invitee_id: User.find_by(phone: @formatted_phone).id).present?
    		# To and From match a conversation: add text to convo and text back out to everyone
    		@invitation = Invitation.find_by(number_used: @to, invitee_id: User.find_by(phone: @formatted_phone).id)
    		@gather = Gather.find_by(id: @invitation.gathering_id)
    		@user = User.find_by(phone: @formatted_phone)
    		invited_yes_array = @gather.invited_yes.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i)

    		if @user.name.present?
    			@user_name_or_email = @user.name.split(' ').first
    		else
    			@user_name_or_email = @user.email.split(/[.@]/).first.capitalize
    		end
			
			(invited_yes_array - @user.email.split(" ")).each do |invited_yes_array|
				@invited_yes_user = User.find_by(email: invited_yes_array)
				@invited_yes_user_invitation = Invitation.find_by(gathering_id: @gather.id, invitee_id: @invited_yes_user.id)
				
				@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
				message = @client.account.messages.create(
					body: "#{@user_name_or_email}: #{@body}",
				    to: @invited_yes_user.phone,
				    from: @invited_yes_user_invitation.number_used)
				puts message.from
			end

			@gather.update_attributes(details: ("#{@gather.details} <br>#{@user_name_or_email}: #{@body} "))

		elsif (( @body.at(0.1) != "Y" && Invitation.find_by(number_used: @to, invitee_id: User.find_by(phone: @formatted_phone).id).blank? ) || 
    		( @body.at(0.1) == "Y" && Invitation.find_by(id: @invitation_id).blank? ))
    		# To and From don't match a conversation: Error
    		# Y# doesn't match an invitation: Error
			@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
			message = @client.account.messages.create(
				body: "Oops, looks like this activity has ended. For more help, email hello@bloon.us",
			    to: @from,
			    from: @to)
			puts message.from
    	end
    	render 'prevent_error.xml.erb', :content_type => 'text/xml'
	end
end
