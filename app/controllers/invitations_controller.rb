class InvitationsController < ApplicationController
	before_action :signed_in_user

	def update
		@invitation = Invitation.find_by(id: params["id"])
		if Invitation.find_by(id: params["id"]).status == "NA"
			current_user.join!(params["id"])
			Gather.find_by(id: @invitation.gathering_id).increase_num_joining!(params["id"])
			redirect_to root_url			
		else
			current_user.unjoin!(params["id"])
			Gather.find_by(id: @invitation.gathering_id).decrease_num_joining!(params["id"])
			redirect_to root_url
		end
	end
end