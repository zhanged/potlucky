require 'spec_helper'

describe "Static pages" do
  
  describe "Home page" do
    
    it "should have the content 'Potlucky'" do
    	visit '/static_pages/home'
    	expect(page).to have_content('Potlucky')
    end

    it "should have the right title" do
    	visit '/static_pages/home'
    	expect(page).to have_title('Potlucky | Home')
    end
  end

  describe "Help page" do

  	it "should have the content 'Help'" do
  		visit '/static_pages/help'
  		expect(page).to have_content('Help')
  	end
      
      it "should have the right title" do
    	visit '/static_pages/help'
    	expect(page).to have_title('Potlucky | Help')
    end
  end

  describe "About page" do

  	it "should have the content 'About'" do
	  	visit '/static_pages/about'
	  	expect(page).to have_content('About')	
  	end

  	it "should have the right title" do
    	visit '/static_pages/about'
    	expect(page).to have_title('Potlucky | About')
    end
  end
end
