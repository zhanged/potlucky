class CalinvitesController < ApplicationController

  def edit
  	@calinvite = Calinvite.find(params[:id])
  end

  def update
  	if params[:calinvite][:cal_date] == "" || params[:calinvite][:cal_time] == "" || params[:calinvite][:cal_activity] == ""
		redirect_to root_url, notice: "Please include an activity, date and time"
	else
	  	@calinvite = Calinvite.find(params[:id])
	  	@calinvite.update_attributes(calinvite_params)
	  	gather = Gather.find_by(id: @calinvite.gather_id)
	  	gather.invited_yes.split(" ").each do |recipient|
	  		CalMailer.meeting_request_with_calendar(gather, @calinvite, recipient).deliver
	  	end
	  	gather.update_attributes(activity: @calinvite.cal_activity, activity_2: nil, activity_3: nil,
	  		date: @calinvite.cal_date, date_2: nil, date_3: nil,
	  		time: @calinvite.cal_time, time_2: nil, time_3: nil,
	  		location: @calinvite.cal_location, location_2: nil, location_3: nil
	  		)
	  	@calinvite.update_attributes(cal_sent: "Yes")
		
	  	gather_blurb = @calinvite.cal_activity + " on " + @calinvite.cal_date.strftime("%a, %b %-e") + ", " + @calinvite.cal_time.strftime("%-l:%M%p")
	  	if @calinvite.cal_location.present?
	  		gather_blurb = gather_blurb + " at " + @calinvite.cal_location
	  	end

		gather.invited_yes.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i).each do |invited_yes_array|
			@invited_yes_user = User.find_by(email: invited_yes_array)
			@invited_yes_user_invitation = Invitation.find_by(gathering_id: gather.id, invitee_id: @invited_yes_user.id)
			
			@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
			message = @client.account.messages.create(
				body: "Bloon: #{gather.user.name.split(' ').first} has sent out a calendar invitation for #{gather_blurb}",
			    to: @invited_yes_user.phone,
			    from: @invited_yes_user_invitation.number_used)
			puts message.from
		end

		gather.update_attributes(details: ("#{gather.details} <br>Bloon: #{gather.user.name.split(' ')} has sent out a calendar invitation for #{gather_blurb} "))

		redirect_to root_url, notice: "Calendar invitations sent!"
	end					
  end

  	private
		def calinvite_params
			params.require(:calinvite).permit(:cal_activity, :cal_date, :cal_time, :cal_location, :cal_details)
		end

end