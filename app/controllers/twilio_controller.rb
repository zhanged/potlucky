class TwilioController < ApplicationController
	BASE_URL = "http://serene-journey-3919.herokuapp.com/twilio/respond"
  
    def respond
    	render 'twilio_test.xml.erb', :content_type => 'text/xml'
	end
end
