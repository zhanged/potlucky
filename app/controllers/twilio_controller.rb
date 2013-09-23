class TwilioController < ApplicationController
	BASE_URL = "http://bloon.us/twilio/respond"
  
    def respond
    	@from = params[:From]
    	@to = params[:To]
    	@formatted_phone = @from.gsub("+1","")
    	@body = params[:Body]
    	@invitation_id = @body.split(' ').first.gsub("Y","")

    	# Y# Responses:
    	if @body.at(0.1) == "Y" && Invitation.find_by(id: @invitation_id).present?
    		# Matches an invitation
   	    	@invitation = Invitation.find_by(id: @invitation_id)
   	    	@user = User.find_by(id: @invitation.invitee_id)    		

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
					if @invitation.status == "NA"
						@user.join!(@invitation_id)
						Gather.find_by(id: @invitation.gathering_id).increase_num_joining!(@invitation_id)
					else
						@user.unjoin!(@invitation_id)
						Gather.find_by(id: @invitation.gathering_id).decrease_num_joining!(@invitation_id)
					end
		    	end
			end

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

			@gather.update_attributes(details: ("#{@gather.details} <br>#{@user_name_or_email}: #{@body} (#{Time.now.localtime("-07:00").strftime("%m/%d %I:%M%p PT")}) "))

		elsif (( @body.at(0.1) != "Y" && Invitation.find_by(number_used: @to, invitee_id: User.find_by(phone: @formatted_phone).id).blank? ) || 
    		( @body.at(0.1) == "Y" && Invitation.find_by(id: @invitation_id).blank? ))
    		# To and From don't match a conversation: Error
    		# Y# doesn't match an invitation: Error
			@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
			message = @client.account.messages.create(
				body: "Sorry, please enter the right code. For more help, email hello@bloon.us",
			    to: @from,
			    from: @to)
			puts message.from
    	end
    	render 'prevent_error.xml.erb', :content_type => 'text/xml'
	end
end
