class Calinvite < ActiveRecord::Base
	belongs_to :gather
	validates :gather_id, presence: true

	def redo_results!(gather_id)
		puts "kookie #{gather_id}"
		@gather = Gather.find_by(id: gather_id)
		@calinvite = Calinvite.find_by(gather_id: gather_id)

		if @gather.activity.present? && (@gather.activity_2.present? || @gather.activity_3.present?)						
			activity_1_votes = Invitation.where(gathering_id: gather_id, status: "Yes").pluck(:activity_1v).compact.sum
			if @gather.activity_2.present?
				activity_2_votes = Invitation.where(gathering_id: gather_id, status: "Yes").pluck(:activity_2v).compact.sum
			else
				activity_2_votes = 0
			end
			if @gather.activity_3.present?
				activity_3_votes = Invitation.where(gathering_id: gather_id, status: "Yes").pluck(:activity_3v).compact.sum
			else
				activity_3_votes = 0
			end
			activity_votes = [ activity_1_votes, activity_2_votes, activity_3_votes ]
			puts "activity_votes:"
			puts activity_votes
			activity_votes.delete(0)
			if activity_votes.min == activity_1_votes
				@calinvite.update_attributes(cal_activity: @gather.activity)
			else
				if activity_votes.min == activity_2_votes
					@calinvite.update_attributes(cal_activity: @gather.activity_2)
				else
					@calinvite.update_attributes(cal_activity: @gather.activity_3)
				end
			end
		else
			@calinvite.update_attributes(cal_activity: @gather.activity)
		end

		if (@gather.date.present? || @gather.time.present?) && (@gather.date_2.present? || @gather.date_3.present? || @gather.time_2.present? || @gather.time_3.present?)						
			date_1_votes = Invitation.where(gathering_id: gather_id, status: "Yes").pluck(:date_1v).compact.sum
			if @gather.date_2.present? || @gather.time_2.present?
				date_2_votes = Invitation.where(gathering_id: gather_id, status: "Yes").pluck(:date_2v).compact.sum
			else
				date_2_votes = 0
			end
			if @gather.date_3.present? || @gather.time_3.present?
				date_3_votes = Invitation.where(gathering_id: gather_id, status: "Yes").pluck(:date_3v).compact.sum
			else
				date_3_votes = 0
			end
			date_votes = [ date_1_votes, date_2_votes, date_3_votes ]
			puts "date_votes:"
			puts date_votes
			date_votes.delete(0)
			if date_votes.min == date_1_votes
				@calinvite.update_attributes(cal_date: @gather.date)
				@calinvite.update_attributes(cal_time: @gather.time)
			else
				if date_votes.min == date_2_votes
					@calinvite.update_attributes(cal_date: @gather.date_2)
					@calinvite.update_attributes(cal_time: @gather.time_2)
				else
					@calinvite.update_attributes(cal_date: @gather.date_3)
					@calinvite.update_attributes(cal_time: @gather.time_3)
				end
			end
		else
			@calinvite.update_attributes(cal_date: @gather.date)
			@calinvite.update_attributes(cal_time: @gather.time)
		end

		if @gather.location.present? && (@gather.location_2.present? || @gather.location_3.present?)						
			location_1_votes = Invitation.where(gathering_id: gather_id, status: "Yes").pluck(:location_1v).compact.sum
			if @gather.location_2.present?
				location_2_votes = Invitation.where(gathering_id: gather_id, status: "Yes").pluck(:location_2v).compact.sum
			else
				location_2_votes = 0
			end
			if @gather.location_3.present?
				location_3_votes = Invitation.where(gathering_id: gather_id, status: "Yes").pluck(:location_3v).compact.sum
			else
				location_3_votes = 0
			end
			location_votes = [ location_1_votes, location_2_votes, location_3_votes ]
			puts "location_votes:"
			puts location_votes
			location_votes.delete(0)
			if location_votes.min == location_1_votes
				@calinvite.update_attributes(cal_location: @gather.location)
			else
				if location_votes.min == location_2_votes
					@calinvite.update_attributes(cal_location: @gather.location_2)
				else
					@calinvite.update_attributes(cal_location: @gather.location_3)
				end
			end
		else
			@calinvite.update_attributes(cal_location: @gather.location)
		end
	end
end
