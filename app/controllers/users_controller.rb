class UsersController < ApplicationController
  before_action :signed_in_user, only: [:show, :edit, :update, :destroy]
  before_action :correct_user,   only: [:edit, :update]
  before_action :admin_user,     only: [:destroy, :index]

  def index
    @users = User.paginate(page: params[:page])
  end

  def show
    @user = User.find(params[:id])
    # @gathers = @user.gathers.paginate(page: params[:page])
    @lists = @user.lists.paginate(page: params[:page])
  end

  def new
    @user = User.new
  end

  def lets_go
    if signed_in?
      sign_out
    end
    if :link_email.present? && User.find_by(email: params[:link_email]).present?
      @user = User.find_by(email: params[:link_email])
      UserMailer.welcome_email(@user).deliver
      flash[:notice] = "Check your email now to complete your registration"
      redirect_to(root_url)
    else
      redirect_to(root_url)
    end
  end

  def email_redirect
    if User.find_by(auth_token: params[:auth_token]).present?
      @user = User.find_by(auth_token: params[:auth_token])
      sign_in @user
      if @user.phone.present?
        render 'edit'            
      else
        redirect_to(root_url) #redirect_to welcome_path
      end
    else
      redirect_to signin_url
    end
  end

  def edit
  end

  def update
    if params[:commit] == "Save"
    # Settings
      previous_phone = @user.phone
      if previous_phone != user_params[:phone].gsub(/\D/,'')
        begin
          @client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
          message = @client.account.messages.create(
            body: "Welcome to Bloon! If you didn't sign up for Bloon, reply 'Pop22'",
              to: user_params[:phone],
              from: ENV['TWILIO_MAIN'])
          puts message.to, message.body               
        rescue 
          flash[:error] = "Oops this cell number doesn't seem to be correct, please re-enter your cell number"
          render 'edit'
        else
          if @user.update_attributes(user_params)
            @user.update_attributes(auth_token: SecureRandom.urlsafe_base64)
            flash[:success] = "Profile updated!"
            sign_in @user
            redirect_to(root_url)
          else
            render 'edit'
          end        
        end
      else 
        if @user.update_attributes(user_params)
          @user.update_attributes(auth_token: SecureRandom.urlsafe_base64)
          flash[:success] = "Profile updated!"
          sign_in @user
          redirect_to(root_url)
        else
          render 'edit'
        end
      end
    else
    # New user
      # Check if someone with this # exists
      if User.where(phone: user_params[:phone].gsub(/\D/,'')).present? && User.where(phone: user_params[:phone].gsub(/\D/,'')).last.email.nil?
        # Merge accounts
        @user = User.where(phone: user_params[:phone].gsub(/\D/,'')).last
        @user.name = current_user.name
        @user.email = current_user.email
        @user.password_digest = current_user.password_digest
        @user.remember_token = current_user.remember_token
        @user.admin = current_user.admin
        @user.auth_token = current_user.auth_token
        @user.provider = current_user.provider
        @user.uid = current_user.uid
        @user.image = current_user.image
        @user.token = current_user.token
        @user.expires_at = current_user.expires_at
        @user.first_name = current_user.first_name
        @user.last_name = current_user.last_name
        @user.location_id = current_user.location_id
        @user.location_name = current_user.location_name
        @user.gender = current_user.gender
        @user.timezone = current_user.timezone
        @user.locale = current_user.locale
        current_user.email = nil
        current_user.save!(:validate => false)
        @user.save!(:validate => false)
        tracker = Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
          tracker.track(@user.id, 'Converted from phone-only to user', {
        })
        sign_in @user
        if session[:gatherfrominvite].present? # params["invitation"].present?
          @gather = Gather.find_by(id: session[:gatherfrominvite]) # Gather.find_by(id: params["invitation"]["gathering_id"])
          feed_item = @gather
          if Invitation.find_by(gathering_id: @gather.id, invitee_id: @user.id).present?
          else              
            @gather.invite!@user
            # @invitation = @gather.invitations.create!(invitee_id: @user.id)
            session[:gatherfrominvite] = nil
            # friend everyone else in the gathering
            @gather.gather_friends(@user)
            # @gather.update_attributes(invited: @gather.invited + " " + @user.email)
            @gather.update_attributes(num_invited: @gather.num_invited + 1)
          end
          tracker = Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
          tracker.track(@user.id, 'Signed Up from link', {
          })
          flash[:success] = "Welcome to Bloon, #{@user.name.split(' ').first}!"
          redirect_to(root_url)
        else
          flash[:success] = "Welcome to Bloon, #{@user.name.split(' ').first}!"
          redirect_to(root_url)
        end
      elsif User.where(phone: user_params[:phone].gsub(/\D/,'')).present?
        flash[:error] = "This phone number has already been taken"
        render 'edit'
      else
        begin
          @client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
          message = @client.account.messages.create(
            body: "Welcome to Bloon! If you didn't sign up for Bloon, reply 'Pop22'",
              to: user_params[:phone],
              from: ENV['TWILIO_MAIN'])
          puts message.to, message.body               
        rescue 
          flash[:error] = "Oops this cell number doesn't seem to be correct, please re-enter your cell number"
          render 'edit'
        else
          @user.phone = user_params[:phone].gsub(/\D/,'')
          if @user.save!(:validate => false)
            # @user.update_attributes(auth_token: SecureRandom.urlsafe_base64)
            sign_in @user
            if session[:gatherfrominvite].present? # params["invitation"].present?
              @gather = Gather.find_by(id: session[:gatherfrominvite]) # Gather.find_by(id: params["invitation"]["gathering_id"])
              feed_item = @gather
              if Invitation.find_by(gathering_id: @gather.id, invitee_id: @user.id).present?
              else              
                @gather.invite!@user
                # @invitation = @gather.invitations.create!(invitee_id: @user.id)
                session[:gatherfrominvite] = nil
                # friend everyone else in the gathering
                @gather.gather_friends(@user)
                # @gather.update_attributes(invited: @gather.invited + " " + @user.email)
                @gather.update_attributes(num_invited: @gather.num_invited + 1)
              end
              tracker = Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
              tracker.track(@user.id, 'Signed Up from link', {
              })
              flash[:success] = "Welcome to Bloon, #{@user.name.split(' ').first}!"
              redirect_to(root_url)
            else
              flash[:success] = "Welcome to Bloon, #{@user.name.split(' ').first}!"
              redirect_to(root_url)
            end
          else
            render 'edit'
          end        
        end
      end
    end
  end

  def create    
    if params[:commit] == "Add"
      flash.keep
      # Added by phone number
      gather = Gather.find_by(id: user_params[:gathering_id])
      if User.find_by(phone: user_params[:phone].gsub(/\D/,'')).present?
        # User already exists
        @user = User.find_by(phone: user_params[:phone].gsub(/\D/,''))
        if Invitation.find_by(gathering_id: gather.id, invitee_id: User.find_by(phone: @user.phone)).present?
          if gather.id == current_user.gathers.first.id
            flash[:error] = "#{User.find_by(phone: @user.phone).name} has already been invited"
            redirect_to root_url, flash: { new_gather_modal: true }
          else
            flash[:error] = "#{User.find_by(phone: @user.phone).name} has already been invited"
            redirect_to root_url
          end
        else
          gather.invite!(@user)
          gather.gather_friends(@user)
          gather.update_attributes(num_invited: gather.num_joining + 1)
          @client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
          message = @client.account.messages.create(
            body: "#{gather.activity}? #{current_user.name} invited you - #{gather.tilt} must join for this to take off. REPLY 'Y' to join or 'N' to pass",
            to: user_params[:phone],
            from: Invitation.find_by(gathering_id: gather.id, invitee_id: @user.id).number_used)
          puts message.to, message.body
          # NEED TO UPDATE GATHER ON INVITATION 
          if gather.id == current_user.gathers.first.id
            flash[:success] = "#{@user.name} has been invited!"
            redirect_to root_url, flash: { new_gather_modal: true }
          else
            flash[:success] = "#{@user.name} has been invited!"
            redirect_to root_url
          end
        end
      else
        # Create new user
        # Check phone number first
        begin
          number_used = (Tnumber.pluck(:tphone) - ENV['TWILIO_MAIN'].split('xxx')).sample
          @client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
          message = @client.account.messages.create(
            body: "#{gather.activity}? #{current_user.name} invited you - #{gather.tilt} must join for this to take off. REPLY 'Y' to join or 'N' to pass",
            to: user_params[:phone],
            from: number_used)
          puts message.to, message.body               
        rescue 
          if gather.id == current_user.gathers.first.id
            flash[:error] = "Oops this cell number doesn't seem to be correct, please re-enter your friend's mobile number"
            redirect_to (request.env['HTTP_REFERER']), flash: { new_gather_modal: true }
          else
            flash[:error] = "Oops this cell number doesn't seem to be correct, please re-enter your friend's mobile number"
            redirect_to (request.env['HTTP_REFERER'])
          end
        else
          @user = User.new
          @user.phone = user_params[:phone].gsub(/\D/,'')          
          @user.name = user_params[:phone].gsub(/\D/,'')          
          @user.save!(:validate => false)
          gather.invite!(@user)
          Invitation.find_by(gathering_id: gather.id, invitee_id: @user.id).update_attributes(number_used: number_used)
          # gather.gather_friends(@user)
          gather.update_attributes(num_invited: gather.num_invited + 1)
          tracker = Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
          tracker.track(@user.id, 'New User, Invited via Phone', {
          })
          if gather.id == current_user.gathers.first.id
            flash[:success] = "Your friend has been invited!"
            redirect_to root_url, flash: { new_gather_modal: true }
          else
            flash[:success] = "Your friend has been invited!"
            redirect_to root_url
          end
        end
      end
    else
      @user = User.new(user_params)
      if params[:gatherfrominvite].present?
        remember_gather(params[:gatherfrominvite])
      end
        # begin
        #   @client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
        #   message = @client.account.messages.create(
        #     body: "Welcome to Bloon! You'll receive new invitations from this phone number. If you didn't sign up for Bloon, reply 'Pop22'",
        #       to: user_params[:phone],
        #       from: ENV['TWILIO_MAIN'])
        #   puts message.to, message.body               
        # rescue 
        #   flash[:error] = "Oops this cell number doesn't seem to be correct, please re-enter your cell number"
        #   redirect_to(request.env['HTTP_REFERER'])
        # else
          puts "step 1"
          Rails.logger.info(@user.errors.inspect)
          if @user.save
            tracker = Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
            tracker.people.set(@user.id, {
              '$name'       => @user.name,
              '$email'      => @user.email,
              '$phone'      => @user.phone,
              '$created_at' => @user.created_at
              });
            tracker.track(@user.id, 'New User Signed Up (email)', {
            })            
            sign_in @user
            puts "step 2"
            # if params["invitation"].present?
            #   puts "step 3"
            #   @gather = Gather.find_by(id: params["invitation"]["gathering_id"])
            #   feed_item = @gather
            #   @invitation = @gather.invitations.create!(invitee_id: @user.id, 
            #     # activity_1v: params["invitation"]["activity_1v"],
            #     # activity_2v: params["invitation"]["activity_2v"],
            #     # activity_3v: params["invitation"]["activity_3v"],
            #     # date_1v: params["invitation"]["date_1v"],
            #     # date_2v: params["invitation"]["date_2v"],
            #     # date_3v: params["invitation"]["date_3v"],
            #     # time_1v: params["invitation"]["time_1v"],
            #     # time_2v: params["invitation"]["time_2v"],
            #     # time_3v: params["invitation"]["time_3v"],
            #     # location_1v: params["invitation"]["location_1v"],
            #     # location_2v: params["invitation"]["location_2v"],
            #     # location_3v: params["invitation"]["location_3v"],
            #     )
            #   @user.join!(@invitation.id)
            #   @gather.increase_num_joining!(@invitation.id)
            #   flash[:success] = "Welcome to Bloon!"
            #   redirect_to(root_url)
            # else
            # UserMailer.welcome_email(@user).deliver
              # flash[:success] = "Welcome to Bloon!"
              render 'edit' # redirect_to(root_url) #redirect_to :controller => 'gathers', :action => 'new'
            # end
          else
            if params["invitation"].present?
              error_msgs = ""
              @user.errors.full_messages.each do |msg|
                if msg == @user.errors.full_messages.first
                  error_msgs = msg
                else
                  error_msgs = error_msgs +", "+ msg
                end
              end
              flash[:error] = error_msgs
              redirect_to (request.env['HTTP_REFERER'])
            else
              error_msgs = ""
              @user.errors.full_messages.each do |msg|
                if msg == @user.errors.full_messages.first
                  error_msgs = msg
                else
                  error_msgs = error_msgs +", "+ msg
                end
              end
              flash[:error] = error_msgs
              redirect_to(:back) # redirect_to(session[:return_to]) # render 'new'
            end
          end
    end   
  end

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "User destroyed"
    redirect_to users_url
  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :phone, :password,
                                   :password_confirmation, :gathering_id, :code, invitation: [:gathering_id, :activity_1v, :activity_2v, :activity_3v, :time_1v, :time_2v, :time_3v, :date_1v, :date_2v, :date_3v, :location_1v, :location_2v, :location_3v])
    end

    # Before filters

    def signed_in_user
      unless signed_in?
        store_location
        redirect_to signin_url, notice: "Please sign in."
      end
    end

    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_url) unless current_user?(@user)
    end

    def admin_user
      redirect_to(root_url) unless current_user.admin?
    end
end