class GathersController < ApplicationController
	before_action :signed_in_user,  only: [:create, :destroy]
	before_action :correct_user, 	only: :destroy

	def create
		@gather = current_user.gathers.build(gather_params)
		if @gather.save
			flash[:success] = "Gathering created!"
			redirect_to root_url
		else
			@feed_items = []		
			render 'static_pages/home'
		end
	end

	def destroy
		@gather.destroy
		redirect_to root_url
	end

	private

		def gather_params
			params.require(:gather).permit(:activity, :invited, :location, :date, :time, :details, :tilt)
		end

		def correct_user
			@gather = current_user.gathers.find_by(id: params[:id])
			redirect_to root_url if @gather.nil?
		end
end