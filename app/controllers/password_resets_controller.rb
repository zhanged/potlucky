class PasswordResetsController < ApplicationController

	def create
		inputted_email = params[:password_reset][:email].downcase
		if inputted_email.split('@').last == "gmail.com"
			inputted_email = inputted_email.split('@').first.gsub(".","") + "@" + inputted_email.split('@').last
		end
	  	if User.find_by(email: inputted_email).present?
			user = User.find_by(email: inputted_email)
			user.send_password_reset
			redirect_to root_url, :notice => "We've sent you an email with a link to reset your password"
		else
			redirect_to root_url, :notice => "Doesn't look like you've signed up yet, please request an invite"
		end
	end

end
