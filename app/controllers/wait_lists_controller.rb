class WaitListsController < ApplicationController
  def new
    @waitlistee = WaitList.new
  end


  def create
	  	if User.find_by(email: params[:wait_list][:email]).present?
			@user = User.find_by(email: params[:wait_list][:email])
			UserMailer.welcome_email(@user).deliver
			redirect_to root_url, :notice => "Nice, looks like you've been invited already - check your email now to complete your registration"
		else
			@waitlistee = WaitList.new(email: params[:wait_list][:email]) 
			if @waitlistee.save
				UserMailer.wait_list(params[:wait_list][:email]).deliver			
				redirect_to root_url, :notice => "Thanks for your interest, we've added you to the waitlist!"
			else
				redirect_to root_url, :notice => "That doesn't looks like an email address to us, try again?"
			end
		end
	end
end
