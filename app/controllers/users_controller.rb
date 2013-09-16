class UsersController < ApplicationController
  before_action :signed_in_user, only: [:index, :edit, :update, :destroy]
  before_action :correct_user,   only: [:edit, :update]
  before_action :admin_user,     only: :destroy

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
    if :link_email.present?
      @user = User.find_by(email: params[:link_email])
    end
    UserMailer.welcome_email(@user).deliver
    flash[:success] = "Check your email now to complete your registration"
  end

  def email_redirect
    if User.find_by(auth_token: params[:auth_token]).present?
      @user = User.find_by(auth_token: params[:auth_token])
      sign_in @user
      render 'edit'    
    else
      redirect_to 'signin'
    end
  end

  def edit
  end

  def update
    if @user.update_attributes(user_params)
      @user.update_attributes(auth_token: SecureRandom.urlsafe_base64)
      flash[:success] = "Profile updated"
      sign_in @user
      redirect_to(root_path)
    else
      render 'edit'
    end
  end

  def create
    @user = User.new(user_params) 
    if @user.save
      sign_in @user
      UserMailer.welcome_email(@user).deliver
      flash[:success] = "Welcome to Potlucky!"
      redirect_to(root_path)
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
      redirect_to(root_path) unless current_user?(@user)
    end

    def admin_user
      redirect_to(root_path) unless current_user.admin?
    end
end