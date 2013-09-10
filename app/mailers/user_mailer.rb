class UserMailer < ActionMailer::Base
  default from: "from@example.com"

  def welcome_email(user)
  	@user = user
  	@url = 'http://example.com/login'
  	mail(to: @user.email, subject: 'Welcome to Potlucky!')
  end

  def invitation_email(user, gather, invitation, invitor) 
  	@user = user
  	@gather = gather
  	@invitation = invitation
  	@invitor = invitor
  	@url = 'http://example.com/login'
  	mail(to: @user.email, subject: "You've been invited by #{@invitor.name}!")  	
  end
end
