class InvitationsController < ApplicationController
	before_action :signed_in_user

	def update
#		@gather = Gather.find_by(params["id"])
		if Invitation.find_by(id: params["id"]).status == "NA"
			current_user.join!(params["id"])
#			@gather.increase_num_joining!(params["id"])
			redirect_to root_url			
		else
			current_user.unjoin!(params["id"])
			redirect_to root_url
		end
	end
end