class Invitation < ActiveRecord::Base
	belongs_to :gathering, class_name: "Gather"
	belongs_to :invitee, class_name: "User"
	validates :gathering_id, presence: true
	validates :invitee_id, presence: true

		def join!(invitation_id)
		Invitation.find_by(id: invitation_id).update(status: "Yes")
	end

end
