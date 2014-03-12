class GathersController < ApplicationController
	before_action :signed_in_user,  only: [:new, :create, :update, :destroy]
	before_action :correct_user, 	only: :destroy
	before_action :admin_user,     only: [:index]

	def index
		@gathers = Gather.paginate(page: params[:page])
	end

	def new
    	@gather = Gather.new
	end

	def create
		if current_user.phone.present?
			@gather = current_user.gathers.build(gather_params)
			if @gather.save
				flash[:success] = "Activity created! Share this link with friends not yet invited: bloon.us/#{@gather.gen_link}"
				redirect_to root_url
			else				
				flash[:error] = "Please include an activity"
				redirect_to (request.env['HTTP_REFERER'])
				# @feed_items = current_user.feed.paginate(page: params[:page], per_page: 10) #Also in static_pages_controller, needed here so show feed during error
				# render 'static_pages/home'
			end
		else
			@user = current_user
			flash[:error] = "Please complete your profile before creating activities"
			render 'users/edit'
		end
	end

	def destroy
		@gather.destroy
		redirect_to root_url
	end

	def show
		@invitation = Invitation.new
		link = Link.find_by(in_url: params[:id])
		@gather = Gather.find_by(id: link.gathering_id)
		@updates = @gather.updates
		# if @gather.activity.present? && @gather.activity_2.blank? && @gather.activity_3.blank?
		# 	@activity_set = "yes"
		# end
		# if @gather.date.present? && @gather.date_2.blank? && @gather.date_3.blank? 
		# 	@date_set = "yes" 
		# end
		# if @gather.time.present? && @gather.time_2.blank? && @gather.time_3.blank?
		# 	@time_set = "yes" 
		# end
		# if @gather.location.present? && @gather.location_2.blank? && @gather.location_3.blank?
		# 	@location_set = "yes" 
		# end
		if !signed_in?
			if link.seen == nil
				link.update_attributes(seen: "1")
			else
				link.update_attributes(seen: 1+link.seen)
			end
		elsif link.invitation_id.present?
			if signed_in? && (Invitation.find_by(id: link.invitation_id).invitee_id == current_user.id)
				link.update_attributes(seen: "1")
			end
		else
			if link.seen == nil
				link.update_attributes(seen: "1")
			else
				link.update_attributes(seen: 1+link.seen)
			end
		end
	end

	private

		def gather_params
			params.require(:gather).permit(:activity, :activity_2, :activity_3, :invited, :location, :location_2, :location_3, :date, :time, :date_2, :time_2, :date_3, :time_3, :details, :tilt, :more_details, :wait_hours, :wait_time, :gen_link)
		end

		def correct_user
			@gather = current_user.gathers.find_by(id: params[:id])
			redirect_to root_url if @gather.nil?
		end

	    def admin_user
	    	redirect_to(root_url) unless current_user.admin?
    	end

end