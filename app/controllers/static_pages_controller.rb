class StaticPagesController < ApplicationController
  def home
  	if signed_in?
  		@gather = current_user.gathers.build
      @list = current_user.lists.build
  		# @feed_items = current_user.feed.paginate(page: params[:page], per_page: 5) #Also in gathers_controller
      gather_items = current_user.feed
      # list_items = current_user.full_list
      friends_lists = current_user.friends_list_feed
      require 'will_paginate/array'
      @feed_items = (friends_lists + gather_items).sort_by(&:created_at).reverse.paginate(page: params[:page], per_page: 10) #Also in gathers_controller
  	end
  end

  def help
  end

  def about
  end
end
