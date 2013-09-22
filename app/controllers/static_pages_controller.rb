class StaticPagesController < ApplicationController
  def home
  	if signed_in?
  		@gather = current_user.gathers.build
  		@feed_items = current_user.feed.paginate(page: params[:page], per_page: 10) #Also in gathers_controller
  	end
  end

  def help
  end

  def about
  end
end
