class SessionsController < ApplicationController

	def new
	end

	def create
		inputted_email = params[:session][:email].downcase
		if inputted_email.split('@').last == "gmail.com"
			inputted_email = inputted_email.split('@').first.gsub(".","") + "@" + inputted_email.split('@').last
		end

		user = User.find_by(email: inputted_email)
		if user && user.authenticate(params[:session][:password])
			sign_in user
			redirect_to root_url#, notice: "Welcome back! Don't forget to invite friends to an activity"  # redirect_back_or root_path
		else
			flash.now[:error] = 'Invalid email/password combination' 
			render 'new' # redirect_to edit_user_path
		end
	end

	def destroy
		sign_out
		redirect_to '/signin'
	end
end
