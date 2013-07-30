require 'spec_helper'

describe TwilioController do

  describe "GET 'firstsms'" do
    it "returns http success" do
      get 'firstsms'
      response.should be_success
    end
  end

  describe "GET 'respond'" do
    it "returns http success" do
      get 'respond'
      response.should be_success
    end
  end

end
