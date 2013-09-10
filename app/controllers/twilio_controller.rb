class TwilioController < ApplicationController
	BASE_URL = "http://serene-journey-3919.herokuapp.com/twilio/respond"
  
    def respond
    	@from = params[:From]
    	@body = params[:Body]
    	@invitation_id = @body.gsub("YES","")
    	if @body.at(0..2) == "YES"
    		@user = User.find_by(phone: @from)
    		Invitation.find_by(id: @invitation_id).update
    		if Invitation.find_by(id: @invitation_id) == "Yes"
				render 'joined.xml.erb', :content_type => 'text/xml'
				puts "Just joined!"
			elsif Invitation.find_by(id: @invitation_id) == "NA"
				render 'unjoined.xml.erb', :content_type => 'text/xml'
				puts "Just unjoined!"
			end
    	else
    		@invitee_id = Invitation.find_by(id: @invitation_id).invitee_id
    		@formatted_phone = @from.gsub("+1","")
    		User.find_by(@invitee_id).update_attribute(phone: @formatted_phone)
    		Invitation.find_by(id: @invitation_id).update
    		if Invitation.find_by(id: @invitation_id) == "Yes"
				render 'joined.xml.erb', :content_type => 'text/xml'
				puts "Just joined!"
			elsif Invitation.find_by(id: @invitation_id) == "NA"
				render 'unjoined.xml.erb', :content_type => 'text/xml'
				puts "Just unjoined!"
			end
    	end
#    	render 'twilio_test.xml.erb', :content_type => 'text/xml'
	end
end
