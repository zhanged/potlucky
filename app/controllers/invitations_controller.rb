class InvitationsController < ApplicationController
	before_action :signed_in_user

	def create
		# @invitation = Invitation.new(invitation_params)
		@invitation = Gather.find_by(id: params["invitation"]["gathering_id"]).invitations.build(gathering_id: params["invitation"]["gathering_id"], invitee_id: current_user.id)
		@invitation.update_attributes(invitation_params)
		if @invitation.save			
			current_user.join!(@invitation.id)
			Gather.find_by(id: @invitation.gathering_id).increase_num_joining!(@invitation.id)
			if Calinvite.find_by(gather_id: @invitation.gathering_id).present?
				calinvite = Calinvite.find_by(gather_id: @invitation.gathering_id)
				if calinvite.cal_sent == "Yes"
					CalMailer.meeting_request_with_calendar(Gather.find_by(id: @invitation.gathering_id), calinvite, current_user).deliver
				else
					calinvite.redo_results!(@invitation.gathering_id)
				end				
			end		
			redirect_to root_url, notice: "You've joined!"
		else
			redirect_to root_url, notice: "Hmm something went wrong and you weren't able to join..."
		end
	end

	def update
		if current_user.phone.present?
			@invitation = Invitation.find_by(id: params["id"])
			@invitation.update_attributes(invitation_params)
			if params[:commit] == "Join"
				current_user.join!(params["id"])
				Gather.find_by(id: @invitation.gathering_id).increase_num_joining!(params["id"])
				if Calinvite.find_by(gather_id: @invitation.gathering_id).present?
					calinvite = Calinvite.find_by(gather_id: @invitation.gathering_id)
					if calinvite.cal_sent == "Yes"
						CalMailer.meeting_request_with_calendar(Gather.find_by(id: @invitation.gathering_id), calinvite, current_user).deliver
					else
						calinvite.redo_results!(@invitation.gathering_id)
					end
					redirect_to root_url
				end			
			else
				current_user.unjoin!(params["id"])
				Gather.find_by(id: @invitation.gathering_id).decrease_num_joining!(params["id"])
				Calinvite.find_by(gather_id: @invitation.gathering_id).redo_results!(@invitation.gathering_id) if Calinvite.find_by(gather_id: @invitation.gathering_id).present?
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
			params.require(:invitation).permit(:gathering_id, :activity_1v, :activity_2v, :activity_3v, :time_1v, :time_2v, :time_3v, :date_1v, :date_2v, :date_3v, :location_1v, :location_2v, :location_3v)
		end


end