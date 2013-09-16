class GathersController < ApplicationController
	before_action :signed_in_user,  only: [:create, :update, :destroy]
	before_action :correct_user, 	only: :destroy

	def create
		if current_user.phone.present?
			@gather = current_user.gathers.build(gather_params)
			if @gather.save
				flash[:success] = "Gathering created!"
				redirect_to root_url
			else
				
				@feed_items = current_user.feed.paginate(page: params[:page]) #Also in static_pages_controller, needed here so show feed during error
				render 'static_pages/home'
			end
		else
			@user = current_user
			flash[:error] = "You must complete your profile before joining gatherings"
			render 'users/edit'
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