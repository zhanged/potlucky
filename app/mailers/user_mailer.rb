class UserMailer < ActionMailer::Base
  BASE_URL = "http://serene-journey-3919.herokuapp.com/"
#  BASE_URL = "http://localhost:3000/"

  def welcome_email(user)
  	@user = user
  	@url = BASE_URL + "email_redirect?auth_token=#{@user.auth_token}"
  	mail(to: @user.email, subject: 'Welcome to Potlucky!')
  end

  def password_reset(user)
  	@user = user
  	@url = BASE_URL + "email_redirect?auth_token=#{@user.auth_token}"
  	mail(to: @user.email, subject: 'Potlucky Password Reset')
  end

  def wait_list(email)
  	mail(to: email, subject: "You've been added to the Potlucky waitlist!")
  end

  def invitation_email(user, gather, invitation, invitor) 
  	@user = user
  	@gather = gather
  	@invitation = invitation
  	@invitor = invitor
  	@url = BASE_URL + "lets_go?link_email=#{@user.email}"
  	mail(to: @user.email, subject: "You've been invited by #{@invitor.name}!")  	
  end
end
