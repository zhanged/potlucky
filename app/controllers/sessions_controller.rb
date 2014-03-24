class SessionsController < ApplicationController

	def new
	end

	def create
		if params[:provider].present?
		# FB sign in
			user = User.from_omniauth(env["omniauth.auth"])
			the_user = User.find_by(uid: env["omniauth.auth"].uid)
    		sign_in the_user
    		# session[:user_id] = user.id
    		if the_user.phone.present?
				if session[:gatherfrominvite].present?
		            @gather = Gather.find_by(id: session[:gatherfrominvite])
		            feed_item = @gather
		            if Invitation.find_by(gathering_id: @gather.id, invitee_id: the_user.id).present?		            	
		            else
		            	@gather.invite!(the_user)
		            	# @invitation = @gather.invitations.create!(invitee_id: the_user.id)
		            	session[:gatherfrominvite] = nil
		            	# friend everyone else in the gathering
		            	@gather.gather_friends(the_user)
						@gather.update_attributes(invited: @gather.invited + " " + the_user.email)
						@gather.update_attributes(num_invited: @gather.num_invited + 1)
		            end
		            redirect_to(root_url)
		        else
					redirect_to(root_url)
				end
    		else
    			redirect_to edit_user_path(current_user)
    		end
    	else 
    	# Email sign in
    		# params[:session][:email].present?
			inputted_email = params[:session][:email].downcase
			if inputted_email.split('@').last == "gmail.com"
				inputted_email = inputted_email.split('@').first.gsub(".","") + "@" + inputted_email.split('@').last
			end

			user = User.find_by(email: inputted_email)
			if user && user.authenticate(params[:session][:password])
				sign_in user
				if user.phone.present?
					if session[:gatherfrominvite].present?
			            @gather = Gather.find_by(id: session[:gatherfrominvite])
			            feed_item = @gather
			            if Invitation.find_by(gathering_id: @gather.id, invitee_id: user.id).present?		            	
			            else
			            	@gather.invite!(user)
			            	# @invitation = @gather.invitations.create!(invitee_id: user.id)
			            	session[:gatherfrominvite] = nil
			            	# friend everyone else in the gathering
			            	@gather.gather_friends(user)
			            	@gather.update_attributes(invited: @gather.invited + " " + user.email)
							@gather.update_attributes(num_invited: @gather.num_invited + 1)
			            end
			            redirect_to(root_url)
			        else
						redirect_to(root_url)
					end
				else
					redirect_to edit_user_path(current_user)
    			end
				#redirect_to root_url#, notice: "Welcome back! Don't forget to invite friends to an activity"  # redirect_back_or root_path
			else
				flash.now[:error] = 'Invalid email/password combination' 
				render 'new' # redirect_to edit_user_path
			end
    	end
	end

	def destroy
		sign_out
		redirect_to '/signin'
	end
end
