class LinksController < ApplicationController

	def go
	  @link = Link.find_by_in_url!(params[:in_url])
	  @gather = Gather.find_by(gen_link: params[:in_url])
	  if @link.invitation_id.present?
	  	@user = User.find_by(id: Invitation.find_by(id: @link.invitation_id).invitee_id)
      	sign_in @user
      	redirect_to @link.out_url, :status => @link.http_status
      else
      	redirect_to @link.out_url, :status => @link.http_status
      end
	end

	def show
		@gather = Gather.find_by(gen_link: params[:in_url])
	end

end