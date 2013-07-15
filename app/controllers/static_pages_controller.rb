class StaticPagesController < ApplicationController
  def home
  	if signed_in?
  		@gather = current_user.gathers.build
  		@feed_items = current_user.feed.paginate(page: params[:page])
  	end
  end

  def help
  end

  def about
  end
end
