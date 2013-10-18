class InviteMoresController < ApplicationController
  before_action :signed_in_user

  	def new
  		@invite_more = InviteMore.new
  	end

	def create
		@invite_more = InviteMore.new(invite_more_params) 
		if current_user.phone.present?
			@invite_more = Gather.find_by(id: invite_more_params[:gather_id]).invite_mores.build(invite_more_params)
			if @invite_more.save
				flash[:success] = "New invitations sent!"
				redirect_to root_url
			else				
				flash[:error] = "Oops, invitation was not sent"
				redirect_to root_url
			end
		else
			@user = current_user
			flash[:error] = "You must complete your profile before adding friends to this activity"
			render 'users/edit'
		end
	end

	def destroy
	end

	private

		def invite_more_params
			params.require(:invite_more).permit(:more_invitees, :user_id, :gather_id)
		end
end