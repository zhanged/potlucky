class User < ActiveRecord::Base
	has_many :gathers, dependent: :destroy
	belongs_to :invitation, foreign_key: "invitee_id"
	has_many :reverse_invitations, foreign_key: "invitee_id", class_name: "Invitation"
	has_many :gatherings, through: :reverse_invitations
	has_many :friendships, foreign_key: "friender_id"
	has_many :friended_users, through: :friendships, source: :friended
	before_save { self.email = email.downcase }
	before_validation do 
		if self.phone != nil
		self.phone = phone.gsub(/\D/,'')
		end
	end
	before_create :create_remember_token
	before_create :create_auth_token
	validates :name, 	presence: true, :on => :update, length: { maximum: 50 }
	VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
	validates :email, presence: true, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }
	validates :phone, presence: true, :on => :update, length: { is: 10 }
	has_secure_password :validations => false # users can be created without passwords
	validates :password, :on => :update, length: { minimum: 6 }

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
	end

	def unjoin!(invitation_id)
		this_invitation = Invitation.find_by(id: invitation_id)
		this_invitation.update(status: "NA")
	end

	def send_password_reset
		UserMailer.password_reset(self).deliver
	end

	def not_friend?(other_user)
		friendships.find_by(friender_id: self.id, friended_id: other_user.id).blank?
	end

	def friend!(other_user)
		friendships.create!(friender_id: self.id, friended_id: other_user.id)
	end

	def friends
		current_user.friended_users.pluck(:email)
	end

	private

		def create_remember_token
			self.remember_token = User.encrypt(User.new_remember_token)
		end

		def create_auth_token
			self.auth_token = User.new_remember_token
		end
end