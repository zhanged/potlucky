class UserMailer < ActionMailer::Base
  default from: "Bloon <hello@bloon.us>"
  BASE_URL = "http://bloon.us/"
#  BASE_URL = "http://localhost:3000/"

  def welcome_email(user)
  	@user = user
  	@url = BASE_URL + "email_redirect?auth_token=#{@user.auth_token}"
  	mail(to: @user.email, subject: 'Welcome to Bloon!')
  end

  def password_reset(user)
  	@user = user
  	@url = BASE_URL + "email_redirect?auth_token=#{@user.auth_token}"
  	mail(to: @user.email, subject: 'Bloon Password Reset')
  end

  def wait_list(email)
  	mail(to: email, bcc: 'hello+waitlist@bloon.us', subject: "You've been added to the Bloon waitlist!")
  end

  def invitation_email(user, gather, invitation, invitor, to_invitees) 
  	@user = user
  	@gather = gather
  	@invitation = invitation
  	@invitor = invitor
    @to_invitees = to_invitees
    @from = "#{@invitor.name} via Bloon <hello@bloon.us>"
    @reply_to = @invitor.email
  	@url = BASE_URL + "email_redirect?auth_token=#{@user.auth_token}" # "lets_go?link_email=#{@user.email}"
#    attachments.inline['organized_by_bloon.png'] = File.read('public/organized_by_bloon.png')
    attachments.inline['bloon-logo.png'] = File.read('public/bloon-logo.png')
  	mail(to: @user.email, from: @from, reply_to: @reply_to, subject: "#{@gather.activity}?")  	
  end

  def update_email(user, update, gather, already_joining, responder, invite)
    @user = user
    @update = update
    @gather = gather
    @already_joining = already_joining
    @organizer = responder
    @invitation = invite
    @from = "#{@organizer.name} via Bloon <hello@bloon.us>"
    @reply_to = @organizer.email
    @url = BASE_URL + "email_redirect?auth_token=#{@user.auth_token}"
    mail(to: @user.email, from: @from, reply_to: @reply_to, subject: "Update: #{@gather.activity}?")   
  end
end
