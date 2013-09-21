class TnumberController < ApplicationController
	def new
		@newtphone = Tnumber.new
	end

	def create
		@newtphone = Tnumber.new(tphone: params[:tnumber][:tphone]) 
		@newtphone.save
	end
end
