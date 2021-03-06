class TwilioController < ApplicationController
	BASE_URL = "http://bloon.us/twilio/respond"
  
    def respond
    	@from = params[:From] # user's number
    	@to = params[:To]  # twilio number
    	@formatted_phone = @from.gsub("+1","")
    	@body = params[:Body]
    	@invitation_id = @body.split(' ').first.gsub("Y","")

    	

    	# Y# Responses:
    	if @body.downcase == "y"
    	# if "Y", find invitation through To # and join
    		if User.find_by(phone: @formatted_phone).present?
    			@user = User.find_by(phone: @formatted_phone)
    			if Invitation.where(invitee_id: @user.id, number_used: @to, status: "NA").present?
    				# If hasn't repsonded yet
    				@invitation = Invitation.find_by(invitee_id: @user.id, number_used: @to)
					@user.join!(@invitation.id)
					Gather.find_by(id: @invitation.gathering_id).increase_num_joining!(@invitation.id)
					puts "Joining as first response"
					# If person doesn't have a name
					if @user.phone == @user.name
						@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
						message = @client.account.messages.create(
							body: "Thanks for joining #{Gather.find_by(id: @invitation.gathering_id).activity}! Please reply to this text with your name so your friends know who you are in the group text",
						    to: @user.phone,
						    from: ENV['TWILIO_MAIN'])
						puts message.from
						puts "Get name from new user"
						Gather.find_by(id: @invitation.gathering_id).gather_friends(@user)	
					end	
				elsif Invitation.where(invitee_id: @user.id, number_used: @to, status: "No").present?
					# If passed and now wants to join
    				@invitation = Invitation.find_by(invitee_id: @user.id, number_used: @to)
					@user.join!(@invitation.id)
					Gather.find_by(id: @invitation.gathering_id).increase_num_joining!(@invitation.id)
					puts "Joining, was passing before"	
					# If person doesn't have a name
					if @user.phone == @user.name
						@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
						message = @client.account.messages.create(
							body: "Thanks for joining #{Gather.find_by(id: @invitation.gathering_id).activity}! Please reply to this text with your name so your friends know who you are in the group text",
						    to: @user.phone,
						    from: ENV['TWILIO_MAIN'])
						puts message.from
						puts "Get name from new user"
						Gather.find_by(id: @invitation.gathering_id).gather_friends(@user)		
					end	
				elsif Invitation.where(invitee_id: @user.id, number_used: @to, status: "Yes").present?
					# If already joining
    				@invitation = Invitation.find_by(invitee_id: @user.id, number_used: @to)
			    	@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
					message = @client.account.messages.create(
						body: "Great, we've already marked you down as joining: #{@invitation.gathering.activity}",
					    to: @user.phone,
					    from: @invitation.number_used)
					puts message.from
					puts "Trying to join again"	
				else
					# Else joining too late
			    	@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
					message = @client.account.messages.create(
						body: "Sorry, this activity has already been completed",
					    to: @user.phone,
					    from: @to)
					puts message.from
					puts "Joining too late"		
				end
			end

    	elsif @body.downcase == "n"
    	# if "N", find invitation through To # and unjoin
    		if User.find_by(phone: @formatted_phone).present?
    			@user = User.find_by(phone: @formatted_phone)
    			if Invitation.where(invitee_id: @user.id, number_used: @to, status: "NA").present?
    				# Hasn't responded yet
    				@invitation = Invitation.find_by(invitee_id: @user.id, number_used: @to)
					@user.unjoin!(@invitation.id)
					Gather.find_by(id: @invitation.gathering_id).decrease_num_joining!(@invitation.id)
					puts "Passing as first response"	
				elsif Invitation.where(invitee_id: @user.id, number_used: @to, status: "Yes").present?
					# Was joining
    				@invitation = Invitation.find_by(invitee_id: @user.id, number_used: @to)
					@user.unjoin!(@invitation.id)
					Gather.find_by(id: @invitation.gathering_id).decrease_num_joining!(@invitation.id)
					puts "Passing, was joining before"	
				elsif Invitation.where(invitee_id: @user.id, number_used: @to, status: "No").present?
					# Is already passing
    				@invitation = Invitation.find_by(invitee_id: @user.id, number_used: @to)
					@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
					message = @client.account.messages.create(
						body: "Aw, we've already marked you down as passing: #{@invitation.gathering.activity}",
					    to: @user.phone,
					    from: @invitation.number_used)
					puts message.from
					puts "Trying to pass again"
				else
					# Else passing too late
			    	@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
					message = @client.account.messages.create(
						body: "Sorry, this activity has already been completed",
					    to: @user.phone,
					    from: @to)
					puts message.from
					puts "Passing too late"	
				end
			end

   #  	elsif @body.at(0.1) == "Y" && Invitation.find_by(id: @invitation_id).present?
   #  		# Matches an invitation
   # 	    	@invitation = Invitation.find_by(id: @invitation_id)
   # 	    	@user = User.find_by(id: @invitation.invitee_id)    		

   # 	    	if Gather.find_by(id: @invitation.gathering_id).completed.present?
			# 	# Y# response when the gathering has already been completed
		 #    	@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
			# 	message = @client.account.messages.create(
			# 		body: "Oops, this activity has already ended",
			# 	    to: @from,
			# 	    from: @to)
			# 	puts message.from				
   # 	    	else
	  #  	    	if @user.phone.blank?
	  #  	    		# Invitee doesn't have a phone number: record it and join/unjoin. Will be error if wrong new user texts this
		 #   	    	@user.phone = @formatted_phone
		 #    		@user.save(validate: false)
			# 		if @invitation.status == "NA"
			# 			@user.join!(@invitation_id)
			# 			Gather.find_by(id: @invitation.gathering_id).increase_num_joining!(@invitation_id)
			# 		else
			# 			@user.unjoin!(@invitation_id)
			# 			Gather.find_by(id: @invitation.gathering_id).decrease_num_joining!(@invitation_id)
			# 		end
			# 	else	
		 #   	    	# Invitee does have a phone already recorded
		 #   	    	if (User.find_by(phone: @formatted_phone) != User.find_by(id: Invitation.find_by(id: @invitation_id).invitee_id))
			# 	    	# Phone doesn't match up with invitation's user: Error
			# 	    	@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
			# 			message = @client.account.messages.create(
			# 				body: "Oops, please enter the correct code. For more help, email hello@bloon.us",
			# 			    to: @from,
			# 			    from: @to)
			# 			puts message.from
		 #   	    	else
		 #   	    		# Phone does match user's invitation: join / unjoin	
			# 			if @invitation.status != "Yes"
			# 				@user.join!(@invitation_id)
			# 				Gather.find_by(id: @invitation.gathering_id).increase_num_joining!(@invitation_id)
			# 			else
			# 				@user.unjoin!(@invitation_id)
			# 				Gather.find_by(id: @invitation.gathering_id).decrease_num_joining!(@invitation_id)
			# 			end
			#     	end
			# 	end
			# end			

		# Name response from person who doesn't have a name
		elsif @to == ENV['TWILIO_MAIN'] && User.find_by(phone: @formatted_phone).name == @formatted_phone
			@user = User.find_by(phone: @formatted_phone)
			@user.name = @body
			@user.save!(:validate => false)
			@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
			message = @client.account.messages.create(
				body: "Great, thanks #{@user.name}!",
			    to: @user.phone,
			    from: ENV['TWILIO_MAIN'])
			puts message.from
			puts "Got the new user's name"
			gather = Gather.find_by(id: Invitation.where(invitee_id: @user.id, status: "Yes").last.gathering_id)
			gather.gather_friends(@user)

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
				Invitation.where(gathering_id: expiring_gather.id).pluck(:id).each do |i|
					Invitation.find_by(id: i).update_attributes(number_used: nil)
				end
			end

		# Update / Respond when activity hasn't tilted yet

		# Group chat
		elsif Invitation.find_by(number_used: @to, invitee_id: User.find_by(phone: @formatted_phone).id).present?
    		# To and From match a conversation: add text to convo and text back out to everyone
    		@invitation = Invitation.find_by(number_used: @to, invitee_id: User.find_by(phone: @formatted_phone).id)
    		@gather = Gather.find_by(id: @invitation.gathering_id)
    		@user = User.find_by(phone: @formatted_phone)

    		if @user.name.present?
    			@user_name_or_email = @user.name.split(' ').first
    		else
    			@user_name_or_email = @user.email.split(/[.@]/).first.capitalize
    		end

			if @gather.num_joining < @gather.tilt				
			# Hasn't tilted yet
				if @user.id == @gather.user.id
				# Update from organizer
					joining_invites = Invitation.where(gathering_id: @gather.id, status: "Yes").pluck(:id)
					na_invites = Invitation.where(gathering_id: @gather.id, status: "NA").pluck(:id)
					(joining_invites + na_invites - [@invitation.id.to_i]).each do |invite_id|
						invited_user = User.find_by(id: Invitation.find_by(id: invite_id).invitee_id)
						invited_user_invitation = Invitation.find_by(gathering_id: @gather.id, invitee_id: invited_user.id)
						
						@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
						message = @client.account.messages.create(
							body: "Update from #{@user_name_or_email}: #{@body}",
						    to: invited_user.phone,
						    from: invited_user_invitation.number_used)
						puts message.from
					end	
					@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
					message = @client.account.messages.create(
						body: "Update sent!",
					    to: @user.phone,
					    from: @invitation.number_used)
					puts message.from
					
					@gather.update_attributes(details: ("#{@gather.details} <br>Update from #{@user_name_or_email}: #{@body} "))								
				else
				# Response from invitee to organizer
					@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
					message = @client.account.messages.create(
						body: "Msg from #{@user_name_or_email} to only you: #{@body}",
					    to: @gather.user.phone,
					    from: Invitation.find_by(gathering_id: @gather.id, invitee_id: @gather.user.id).number_used)
					puts message.from
					@gather.update_attributes(details: ("#{@gather.details} <br>Msg from #{@user_name_or_email}: #{@body} "))								
				end			
			else		
			# Tilted already - Group chat	
				invited_yes_array = @gather.invitations.where(status: "Yes").pluck(:invitee_id)
				(invited_yes_array - [@user.id]).each do |invited_yes_array|
					@invited_yes_user = User.find_by(id: invited_yes_array)
					@invited_yes_user_invitation = Invitation.find_by(gathering_id: @gather.id, invitee_id: @invited_yes_user.id)
					
					@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
					message = @client.account.messages.create(
						body: "#{@user_name_or_email}: #{@body}",
					    to: @invited_yes_user.phone,
					    from: @invited_yes_user_invitation.number_used)
					puts message.from
				end
				@gather.update_attributes(details: ("#{@gather.details} <br>#{@user_name_or_email}: #{@body} "))
			end


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
