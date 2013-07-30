class TwilioController < ApplicationController
  def firstsms
  end

  def respond
  	get '/sms-quickstart' do
  twiml = Twilio::TwiML::Response.new do |r|
    r.Sms "Hey Monkey. Thanks for the message!"
  end
  twiml.text
end
  end
end
