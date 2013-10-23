class UsersController < ApplicationController
  before_action :signed_in_user, only: [:edit, :update, :destroy]
  before_action :correct_user,   only: [:edit, :update]
  before_action :admin_user,     only: [:destroy, :index]

  def index
    @users = User.paginate(page: params[:page])
  end

  def show
    @user = User.find(params[:id])
    @gathers = @user.gathers.paginate(page: params[:page])
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
    previous_phone = @user.phone
    if previous_phone != user_params[:phone]
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
          flash[:success] = "Profile updated"
          sign_in @user
          redirect_to(root_url)
        else
          render 'edit'
        end        
      end
    else 
      if @user.update_attributes(user_params)
        @user.update_attributes(auth_token: SecureRandom.urlsafe_base64)
        flash[:success] = "Profile updated"
        sign_in @user
        redirect_to(root_url)
      else
        render 'edit'
      end
    end
  end

  def create
    @user = User.new(user_params) 
    if @user.save
      sign_in @user
      UserMailer.welcome_email(@user).deliver
      flash[:success] = "Welcome to Bloon!"
      redirect_to(root_url)
    else
      render 'new'
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
                                   :password_confirmation)
    end

    # Before filters

    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_url) unless current_user?(@user)
    end

    def admin_user
      redirect_to(root_url) unless current_user.admin?
    end
end