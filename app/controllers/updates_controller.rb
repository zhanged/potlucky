class UpdatesController < ApplicationController
  before_action :signed_in_user

  	def new
  		@update = Update.new
  	end

	def create
		@update = Update.new(update_params) 
		if current_user.phone.present?
			@update = Gather.find_by(id: update_params[:gather_id]).updates.build(update_params)
			if @update.save
				flash[:success] = "Update sent!"
				redirect_to root_url
			else				
				flash[:error] = "Oops, update was not sent"
				redirect_to root_url
			end
		else
			@user = current_user
			flash[:error] = "You must complete your profile before commenting"
			render 'users/edit'
		end
	end

	def destroy
	end

	private

		def update_params
			params.require(:update).permit(:content, :user_id, :gather_id)
		end

end