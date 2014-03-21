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
            body: "Welcome to Bloon! You'll receive new invitations from this phone number. If you didn't sign up for Bloon, reply 'Pop22'",
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
      begin
        @client = Twilio::REST::Client.new ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN']
        message = @client.account.messages.create(
          body: "Welcome to Bloon! You'll receive invitations from your friends through this phone number. If you didn't sign up for Bloon, reply 'Pop22'",
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
              @invitation = @gather.invitations.create!(invitee_id: @user.id)
              session[:gatherfrominvite] = nil
              # friend everyone else in the gathering
              @gather.gather_friends(@user)
            end
            flash[:success] = "Welcome to Bloon!"
            redirect_to(root_url)
          else
            flash[:success] = "Welcome to Bloon!"
            redirect_to '/new'
          end
        else
          render 'edit'
        end        
      end
    end
  end

  def create
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
      # end   
  end

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "User destroyed"
    redirect_to users_url
  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :phone, :password,
                                   :password_confirmation, invitation: [:gathering_id, :activity_1v, :activity_2v, :activity_3v, :time_1v, :time_2v, :time_3v, :date_1v, :date_2v, :date_3v, :location_1v, :location_2v, :location_3v])
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