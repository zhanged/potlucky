class InvitationsController < ApplicationController
	before_action :signed_in_user

	def update
		if Invitation.find_by(id: params["id"]).status == "NA"
			current_user.join!(params["id"])
			Gather.find_by(params["id"]).increase_num_joining!(params["id"])
			redirect_to root_url			
		else
			current_user.unjoin!(params["id"])
			Gather.find_by(params["id"]).decrease_num_joining!(params["id"])
			redirect_to root_url
		end
	end
end