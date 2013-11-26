class InvitationsController < ApplicationController
	before_action :signed_in_user

	def update
		if current_user.phone.present?
			@invitation = Invitation.find_by(id: params["id"])
			@invitation.update_attributes(invitation_params)
			if Invitation.find_by(id: params["id"]).status == "NA"
				current_user.join!(params["id"])
				Gather.find_by(id: @invitation.gathering_id).increase_num_joining!(params["id"])
				redirect_to root_url			
			else
				current_user.unjoin!(params["id"])
				Gather.find_by(id: @invitation.gathering_id).decrease_num_joining!(params["id"])
				redirect_to root_url
			end
		else
			@user = current_user
			flash.now[:error] = "Please complete your profile to join your friends"
			render 'users/edit'
		end

	end

	private
		def invitation_params
			params.require(:invitation).permit(:activity_1v, :activity_2v, :activity_3v, :time_1v, :time_2v, :time_3v, :date_1v, :date_2v, :date_3v, :location_1v, :location_2v, :location_3v)
		end


end