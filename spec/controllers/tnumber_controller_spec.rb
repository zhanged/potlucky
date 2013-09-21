require 'spec_helper'

describe TnumberController do

  describe "GET 'tphone:string'" do
    it "returns http success" do
      get 'tphone:string'
      response.should be_success
    end
  end

end
