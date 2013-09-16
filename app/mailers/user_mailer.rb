class UserMailer < ActionMailer::Base
  default from: "from@example.com"

  def welcome_email(user)
  	@user = user
  	@url = "http://localhost:3000/email_redirect?auth_token=#{@user.auth_token}"
  	mail(to: @user.email, subject: 'Welcome to Potlucky!')
  end

  def password_reset(user)
  	@user = user
  	@url = "http://localhost:3000/email_redirect?auth_token=#{@user.auth_token}"
  	mail(to: @user.email, subject: 'Potlucky Password Reset')
  end

  def wait_list(email)
  	mail(to: email, subject: "You've been added to the Potlucky waitlist!")
  end

  def invitation_email(user, gather, invitation, invitor, email_url) 
  	@user = user
  	@gather = gather
  	@invitation = invitation
  	@invitor = invitor
  	@url = email_url
  	mail(to: @user.email, subject: "You've been invited by #{@invitor.name}!")  	
  end
end
