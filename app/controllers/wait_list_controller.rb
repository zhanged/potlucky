class WaitListController < ApplicationController

  def create
	  	if User.find_by_email(params[:email]).present?
			@user = User.find_by_email(params[:email])
			UserMailer.welcome_email(@user).deliver
			redirect_to root_url, :notice => "Check your email now to complete your registration"
		else
			waitlistee = WaitList.new(email: params[:email])
			waitlistee.save
			UserMailer.wait_list(params[:email]).deliver			
			redirect_to root_url, :notice => "Thanks for your interest, we've added you to the waitlist!"
		end
	end
end
