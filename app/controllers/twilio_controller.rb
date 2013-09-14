class TwilioController < ApplicationController
	BASE_URL = "http://serene-journey-3919.herokuapp.com/twilio/respond"
  
    def respond
    	@from = params[:From]
    	@to = params[:To]
    	@formatted_phone = @from.gsub("+1","")
    	@body = params[:Body]
    	@invitation_id = @body.split(' ').first.gsub("Y","")

    	if @body.at(0.1) == "Y" && Invitation.find_by(id: @invitation_id).present?
   	    	@invitation = Invitation.find_by(id: @invitation_id)
   	    	@user = User.find_by(id: @invitation.invitee_id)    		

   	    	if @user.phone.blank?
	   	    	@user.phone = @formatted_phone
	    		@user.save(validate: false)
	    	elsif (User.find_by(phone: @formatted_phone) != User.find_by(id: Invitation.find_by(id: @invitation_id).invitee_id))
		    	@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
				message = @client.account.sms.messages.create(
					body: "Sorry, there has been an error",
				    to: @from,
				    from: @to)
				puts message.from
   	    	end
			
			if @invitation.status == "NA"
				@user.join!(@invitation_id)
				Gather.find_by(id: @invitation.gathering_id).increase_num_joining!(@invitation_id)
			else
				@user.unjoin!(@invitation_id)
				Gather.find_by(id: @invitation.gathering_id).decrease_num_joining!(@invitation_id)
			end

		elsif Invitation.find_by(number_used: @to, invitee_id: User.find_by(phone: @formatted_phone).id).present?
    		@invitation = Invitation.find_by(number_used: @to, invitee_id: User.find_by(phone: @formatted_phone).id)
    		@gather = Gather.find_by(id: @invitation.gathering_id)
    		@user = User.find_by(phone: @formatted_phone)
    		invited_yes_array = @gather.invited_yes.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i)

    		if @user.name.present?
    			@user_name_or_email = @user.name
    		else
    			@user_name_or_email = @user.email
    		end
			
			(invited_yes_array - @user.email.split(" ")).each do |invited_yes_array|
				@invited_yes_user = User.find_by(email: invited_yes_array)
				@invited_yes_user_invitation = Invitation.find_by(gathering_id: @gather.id, invitee_id: @invited_yes_user.id)
				
				@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
				message = @client.account.sms.messages.create(
					body: "#{@user_name_or_email}: #{@body}",
				    to: @invited_yes_user.phone,
				    from: @invited_yes_user_invitation.number_used)
				puts message.from
			end

			@gather.update_attributes(details: ("#{@gather.details} #{Time.now.to_formatted_s(:db)} #{@user_name_or_email}: #{@body} "))

		elsif (( @body.at(0.1) != "Y" && Invitation.find_by(number_used: @to, invitee_id: User.find_by(phone: @formatted_phone).id).blank? ) || 
    		( @body.at(0.1) == "Y" && Invitation.find_by(id: @invitation_id).blank? ))
    		
			@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
			message = @client.account.sms.messages.create(
				body: "Sorry, there has been an error",
			    to: @from,
			    from: @to)
			puts message.from
    	end
    	render 'prevent_error.xml.erb', :content_type => 'text/xml'
	end
end
