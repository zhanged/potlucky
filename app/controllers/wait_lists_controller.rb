class WaitListsController < ApplicationController
  def new
    @waitlistee = WaitList.new
  end


  def create
	inputted_email = params[:wait_list][:email].downcase
	if inputted_email.split('@').last == "gmail.com"
		inputted_email = inputted_email.split('@').first.gsub(".","") + "@" + inputted_email.split('@').last
	end

	  	if User.find_by(email: inputted_email).present?
			@user = User.find_by(email: inputted_email)
			UserMailer.welcome_email(@user).deliver
			redirect_to root_url, :notice => "Nice, looks like you've been invited already - check your email now to complete your registration"
		else
			@waitlistee = WaitList.new(email: inputted_email) 
			if @waitlistee.save
				UserMailer.wait_list(inputted_email).deliver			
				redirect_to root_url, :notice => "Thanks for your interest, we've added you to the waitlist!"
			else
				redirect_to root_url, :notice => "That doesn't looks like an email address to us, try again?"
			end
		end
	end
end
