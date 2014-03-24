class ListsController < ApplicationController
	before_action :signed_in_user,  only: [:create, :destroy]

	def index
	end

	def create
		@list = current_user.lists.build(list_params)
		if @list.save
			tracker = Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
			tracker.track(current_user.id, 'Added to list', {
			'List ID' => @list.id,
			'List Item' => @list.item
			})
			flash[:success] = "Added to list!"
			redirect_to root_url
		else
			redirect_to (request.env['HTTP_REFERER'])
		end
	end

	def destroy
		@list.destroy
		redirect_to root_url
	end

	private

		def list_params
			params.require(:list).permit(:item)			
		end
end
