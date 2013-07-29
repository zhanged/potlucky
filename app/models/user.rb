class User < ActiveRecord::Base
	has_many :gathers, dependent: :destroy
	belongs_to :invitation, foreign_key: "invitee_id"
	has_many :reverse_invitations, foreign_key: "invitee_id", class_name: "Invitation"
	has_many :gatherings, through: :reverse_invitations
	before_save { self.email = email.downcase }
	before_create :create_remember_token
	validates :name, 	presence: true, length: { maximum: 50 }
	VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
	validates :email, 	presence: true, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }
	has_secure_password
	validates :password, length: { minimum: 6 }

	def User.new_remember_token
		SecureRandom.urlsafe_base64
	end

	def User.encrypt(token)
		Digest::SHA1.hexdigest(token.to_s)
	end

	def feed
		Gather.from_gathers_invited_to(self)
	end

	def join?(invitation_id)
		Invitation.find_by(id: invitation_id).status.include?("Yes")
	end

	def join!(invitation_id)
		this_invitation = Invitation.find_by(id: invitation_id)
		this_invitation.update(status: "Yes")
		this_gather_id = Gather.find_by(id: this_invitation.gathering_id).id
		Gather.increment_counter(:num_joining, this_gather_id)
	end

	def unjoin!(invitation_id)
		this_invitation = Invitation.find_by(id: invitation_id)
		this_invitation.update(status: "NA")
		this_gather_id = Gather.find_by(id: this_invitation.gathering_id).id
		Gather.decrement_counter(:num_joining, this_gather_id)
	end

	private

		def create_remember_token
			self.remember_token = User.encrypt(User.new_remember_token)
		end
end