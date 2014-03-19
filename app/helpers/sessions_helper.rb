module SessionsHelper

	def sign_in(user)
		remember_token = User.new_remember_token
		cookies.permanent[:remember_token] = remember_token
		user.update_attribute(:remember_token, User.encrypt(remember_token))
		self.current_user = user
		tracker = Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
		tracker.track(user.id, 'Signed In', {
			})
	end

	def signed_in?
		!current_user.nil?
	end

	# def current_user
	#     @current_user ||= User.find_by(remember_token: cookies[:remember_token])
	# end

	def current_user?(user)
	    user == current_user
	end

	def signed_in_user
		unless signed_in?
			store_location
			redirect_to signin_url, notice: "Please sign in."
		end
	end

	def current_user=(user)
		@current_user = user
	end

	def current_user
		remember_token = cookies[:remember_token]
		@current_user ||= User.find_by(remember_token: User.encrypt(remember_token))
	end

	def sign_out
		self.current_user = nil
		cookies.delete(:remember_token)
	end

	def redirect_back_or(default)
		redirect_to(session[:return_to] || default)
		session.delete(:return_to)
	end

	def store_location
		if request.post? || request.put?
    		session[:return_to] = request.env['HTTP_REFERER'] unless request.env['HTTP_REFERER'] == root_url
    	else
			session[:return_to] = request.url
		end
	end

	def remember_gather(gather_id)
		#get gathering_id from session if it is blank
		gather_id ||= session[:gatherfrominvite]
		#save gathering_id to session for future requests
		session[:gatherfrominvite] = gather_id
		
	end
end