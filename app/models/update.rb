class Update < ActiveRecord::Base
	belongs_to :gather
	default_scope -> { order('created_at DESC') }
	validates :gather_id, presence: true
	validates :user_id, presence: true
	validates :content, presence: true #, length: { maximum: 140 }
	after_create do
		gather = Gather.find_by(id: self.gather_id)
		responder = User.find_by(id: self.user_id)
		@client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
		if responder.id == gather.user_id
			# Update from organizer
			invites = Invitation.where(gathering_id: gather.id).pluck(:id) - Invitation.where(gathering_id: gather.id, invitee_id: responder.id).pluck(:id)
			invites.each do |i|
				invite = Invitation.find_by(id: i)
				user = User.find_by(id: invite.invitee_id)
				if invite.number_used.present?
				# Joining, so text				
					message = @client.account.messages.create(
						body: "Update from #{responder.name}: #{self.content}",
					    to: user.phone,
					    from: invite.number_used)
					puts message.from
				elsif user.phone.blank?
					# Send email bc no phone
					already_joinings = Invitation.where(gathering_id: gather.id, status: "Yes").pluck(:invitee_id)
					if gather.num_joining == 1
						already_joining = User.find_by(id: already_joinings).name.split(' ').first + " has"
					elsif gather.num_joining == 2
						already_joining = "" 
						already_joinings.each do |j|
							if already_joining == ""
								already_joining = User.find_by(id: j).name.split(' ').first
							else
								already_joining = User.find_by(id: j).name.split(' ').first + " and " + already_joining + " have"
							end
						end						
					else
						already_joining = "" 
						already_joinings.each do |j|
							if already_joining == ""
								already_joining = "and " + User.find_by(id: j).name.split(' ').first + " have"
							else
								already_joining = User.find_by(id: j).name.split(' ').first + ", " + already_joining
							end
						end
					end
					UserMailer.update_email(user, self, gather, already_joining, responder, invite).deliver
				else
					# Not joining but has phone, send text through main
					message = @client.account.messages.create(
						body: "#{responder.name} has an update for #{gather.activity}: #{self.content}",
					    to: user.phone,
					    from: ENV['TWILIO_MAIN'])
					puts message.from
				end
			end
		else
			# From invitee, texts the organizer
			organizer = User.find_by(id: gather.user_id)
			if Invitation.find_by(gathering_id: gather.id, invitee_id: gather.user_id).number_used.present?
			# If tilted
				message = @client.account.messages.create(
					body: "Msg from #{responder.name} to only you re: #{gather.activity} - #{self.content}",
				    to: organizer.phone,
				    from: Invitation.find_by(gathering_id: gather.id, invitee_id: gather.user_id).number_used)
				puts message.from
			else
			# If not tilted
				message = @client.account.messages.create(
					body: "Msg from #{responder.name} re: #{gather.activity} - #{self.content}",
				    to: organizer.phone,
				    from: ENV['TWILIO_MAIN'])
				puts message.from	
			end
		end
	end
end
