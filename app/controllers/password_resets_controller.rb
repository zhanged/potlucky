class PasswordResetsController < ApplicationController

  def create
	  	if User.find_by(email: params[:password_reset][:email]).present?
			user = User.find_by(email: params[:password_reset][:email])
			user.send_password_reset
			redirect_to root_url, :notice => "We've sent you an email with a link to reset your password"
		else
			redirect_to root_url, :notice => "Doesn't look like you've signed up yet, please request an invite"
		end
	end

end
