module TwilioHelper

	def textupdate(invitation_id, texter)
		@invitation = Invitation.find_by(id: invitation_id)
		if @invitation.status == "NA"
			texter.join!(params["id"])
			Gather.find_by(id: @invitation.gathering_id).increase_num_joining!(params["id"])
			redirect_to root_url			
		else
			texter.unjoin!(params["id"])
			Gather.find_by(id: @invitation.gathering_id).decrease_num_joining!(params["id"])
			redirect_to root_url
		end
	end

end
