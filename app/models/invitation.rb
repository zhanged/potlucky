class Invitation < ActiveRecord::Base
	belongs_to :gathering, class_name: "Gather"
	belongs_to :invitee, class_name: "User"
	has_one :link, dependent: :destroy
	validates :gathering_id, presence: true
	validates :invitee_id, presence: true
end
