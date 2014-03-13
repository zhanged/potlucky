class User < ActiveRecord::Base
	has_many :gathers, dependent: :destroy
	belongs_to :invitation, foreign_key: "invitee_id"
	has_many :reverse_invitations, foreign_key: "invitee_id", class_name: "Invitation"
	accepts_nested_attributes_for :invitation, :allow_destroy => true
	has_many :gatherings, through: :reverse_invitations
	has_many :friendships, foreign_key: "friender_id"
	has_many :friended_users, through: :friendships, source: :friended
	before_save { self.email = email.downcase }
	before_validation do 
		if self.phone != nil
		self.phone = phone.gsub(/\D/,'')
		end
	end
	before_validation do
		inputted_email = self.email.downcase
		if inputted_email.split('@').last == "gmail.com"
			inputted_email = inputted_email.split('@').first.gsub(".","") + "@" + inputted_email.split('@').last
			self.email = inputted_email
		end
	end
	before_create :create_remember_token
	before_create :create_auth_token
	validates :name, 	presence: true, length: { maximum: 22 }
	VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
	validates :email, presence: true, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }
	validates :phone, presence: true, :on => :update, length: { is: 10 }
	has_secure_password :validations => false # users canNOT be created without passwords
	validates :password, length: { minimum: 6 }
	validate :phone_is_real
	after_create do
		tracker = Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
		tracker.people.set(self.id, {
	    '$name'       => self.name,
	    '$email'      => self.email,
	    '$phone'      => self.phone,
	    '$created_at' => self.created_at
	    });
	    tracker.track(self.id, 'New User Signed Up', {
			})
	end

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
		this_invitation.update_attributes(status: "Yes", when_responded: Time.now)
	end

	def unjoin!(invitation_id)
		this_invitation = Invitation.find_by(id: invitation_id)
		this_invitation.update_attributes(status: "No", when_responded: Time.now)
	end

	def send_password_reset
		UserMailer.password_reset(self).deliver
	end

	def not_friend?(other_user)
		friendships.find_by(friender_id: self.id, friended_id: other_user.id).blank?
	end

	def friend!(other_user)
		friendships.create!(friender_id: self.id, friended_id: other_user.id)
		tracker = Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
		tracker.people.set(self.id, {
	    '$friends'       => self.friended_users.pluck(:email).count
	    });
	end

	def friends
		current_user.friended_users.pluck(:email)
	end

	def phone_is_real
		# begin
		# 	#text phone
		# rescue
		# 	#if error, redirect to edit profile and put error notice Twilio::REST::RequestError (The 'To' number 1513267216 is not a valid phone number.)
		# end
		begin
        @client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
	        message = @client.account.messages.create(
	          body: "Welcome to Bloon! You'll receive new invitations from this phone number. If you didn't sign up for Bloon, reply 'Pop22'",
	          to: self.phone,
	          from: ENV['TWILIO_MAIN'])
	        puts message.to, message.body               
	    rescue 
	        errors.add(:phone, "number doesn't seem to be correct, please re-enter your phone number")
		end
	end

	private

		def create_remember_token
			self.remember_token = User.encrypt(User.new_remember_token)
		end

		def create_auth_token
			self.auth_token = User.new_remember_token
		end
end