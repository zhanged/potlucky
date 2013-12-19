class CalMailer < ActionMailer::Base
  default from: "Bloon <hello@bloon.us>"

	def meeting_request_with_calendar(gather, calinvite, recipient)
		@calinvite = calinvite
		@gather = gather
		if recipient.name.split(' ').second.present?
			@recipient_initials = recipient.name.at(0.1).upcase + recipient.name.split(' ').last.at(0.1).upcase
		else
			@recipient_initials = recipient.name.at(0.1).upcase
		end
    	invitations_all = "" 
    	gather.invitations.where(status: "Yes").pluck(:invitee_id).each do |f|
			if invitations_all == "" 
				invitations_all = "ATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION;RSVP=TRUE;CN="+User.find_by(id: f).name+";X-NUM-GUESTS=0:mailto:"+User.find_by(id: f).email
			else
				invitations_all = invitations_all +
				"\nATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION;RSVP=TRUE;CN="+User.find_by(id: f).name+";X-NUM-GUESTS=0:mailto:"+User.find_by(id: f).email
			end
		end

		if calinvite.cal_time == nil
			gather_start = nil
			gather_end = nil
		else
			gather_start = calinvite.cal_date.strftime("%Y%m%dT")+calinvite.cal_time.strftime("%H%M%S")
			if calinvite.cal_time.strftime("%H") == "23"
				gather_end = ((calinvite.cal_date)+1.day).strftime("%Y%m%dT")+((calinvite.cal_time)+1.hour).strftime("%H%M%S")
			else
				gather_end = calinvite.cal_date.strftime("%Y%m%dT")+((calinvite.cal_time)+1.hour).strftime("%H%M%S")
			end
		end
		
    	content = 
"BEGIN:VCALENDAR
VERSION:2.0
CALSCALE:GREGORIAN
PRODID:-//Bloon Inc//EN
METHOD:REQUEST
BEGIN:VEVENT
DTSTART:"+gather_start.to_s+"
DTEND:"+gather_end.to_s+"
DTSTAMP:"+DateTime.now.strftime("%Y%m%dT%H%M%S")+"Z"+"
ORGANIZER;CN="+gather.user.name+":mailto:"+gather.user.email+"
UID:"+gather.created_at.strftime("%Y%m%dT%H%M%S")+gather.id.to_s+"@bloon.us
"+invitations_all+"
CREATED:"+DateTime.now.strftime("%Y%m%dT%H%M%S")+"Z"+"
DESCRIPTION:"+calinvite.cal_details.to_s+"
LAST-MODIFIED:"+DateTime.now.strftime("%Y%m%dT%H%M%S")+"Z"+"
LOCATION:"+calinvite.cal_location.to_s+"
SEQUENCE:0
STATUS:CONFIRMED
SUMMARY:"+calinvite.cal_activity.to_s+"
TRANSP:OPAQUE
END:VEVENT
END:VCALENDAR"

		file = File.new("tmp/invite.ics", "w+")
		file.write(content)
		file.close

		
		mail(to: recipient.email, from: "Bloon <hello@bloon.us>", subject: "Invitation: #{calinvite.cal_activity}") do |format|
			format.ics { render 'tmp/invite' }
			format.html { render 'meeting_request_with_calendar' }
		end
  	end

# FIX DETAILS PART: http://stackoverflow.com/questions/20253715/how-to-set-content-type-in-action-mailer-rails-4-0-1

	def make_ical
		@calendar = Icalendar::Calendar.new
		event = Icalendar::Event.new
		event.start = DateTime.now.strftime("%Y%m%dT%H%M%S%Z")
		event.end = (DateTime.now + 1.hour).strftime("%Y%m%dT%H%M%S%Z")
		event.summary = "This is the summary"
		event.description = "This is the description"
		event.location = "This is the location"
		@calendar.add event
		@calendar.publish
		file = File.new("tmp/ics_files/sample.ics", "w+")
		file.write(@calendar.to_ical)
		file.close
		
		recipients "edisonmzhang@gmail.com"
		from "Bloon <hello@bloon.us>"
		subject "Sending the event details with an iCal"
		# body :user => user

		attachment :content_type => "text/calendar",
		:body => File.read("tmp/ics_files/sample.ics"),
		:filename => "sample.ics"
		
		# mail(:to => "edisonmzhang@gmail.com", :subject => "iCalendar test",
  #                 :from => "Bloon <hello@bloon.us>", 
		# attachment :content_type => "text/calendar",
		# :body => File.read("tmp/ics_files/sample.ics"),
		# :filename => "sample.ics"
	end
end
