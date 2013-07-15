require 'spec_helper'

describe "Gather pages" do
  
  subject { page }

  let(:user) { FactoryGirl.create(:user) }
  before { sign_in user }

  describe "gather creation" do
  	before { visit root_path }

  	describe "with invalid information" do
  		
  		it "should not create a gather" do
  			expect { click_button "Gather" }.not_to change(Gather, :count)
  		end

  		describe "error messages" do
  			before { click_button "Gather" }
  			it { should have_content('error') }
  		end
  	end

  	describe "with valid information" do
  		
  		before { fill_in 'gather_activity', with: "Lorem ipsum" }
  		it "should create a gather" do
  			expect { click_button "Gather" }.to change(Gather, :count).by(1)
  		end
  	end
  end

  describe "gathering destruction" do
  	before { FactoryGirl.create(:gather, user: user) }

  	describe "as current user" do
  		before { visit root_path }

  		it "should should delete a gathering" do
  			expect { click_link "delete" }.to change(Gather, :count).by(-1)
  		end
  	end
  end
end
