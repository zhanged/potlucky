require 'spec_helper'

describe "Static pages" do
  
  subject { page }

  describe "Home page" do
  	before { visit root_path }
    
    it { should have_content('Potlucky') }
    it { should have_title(full_title('')) }
    it { should_not have_title('| Home') }

    describe "for signed-in users" do
      let(:user) { FactoryGirl.create(:user) }
      let(:other_user) { FactoryGirl.create(:user) }
      before do
        FactoryGirl.create(:gather, user: user, activity: "Lorem ipsum", invited: other_user.email, tilt:2)
        FactoryGirl.create(:gather, user: user, activity: "Dolor sit amet")
        sign_in user
        visit root_path
      end

      it "should render the user's feed" do
        user.feed.each do |item|
          expect(page).to have_selector("li##{item.id}", text: item.activity)
        end
      end

      describe "should be already joining" do
        it { should have_button("Joining") } 
        it { should_not have_button("Join!") }
      end

      describe ", the invited user" do
        before do
          sign_in other_user
          visit root_path
        end

        describe "should not be joining to begin with" do
          it { should have_button("Join!") }
          it { should_not have_button("Joining") }
        end

        describe "has joined the gathering" do
          before { click_button "Join!" }

          describe "should change the invitee status" do
            it { should have_button("Joining") }
            it { should_not have_button("Join!") }
            it { should have_xpath("//input[@value='Joining']") }
          end

          describe "and decided to unjoin" do
            before { click_button "Joining"}

            describe "should change the invitee status back" do
              it { should have_button("Join!") }
              it { should_not have_button("Joining") }
              it { should have_xpath("//input[@value='Join!']") }
            end
          end
        end
      end        
    end
  end

  describe "Help page" do
  	before { visit help_path }

  	it { should have_content('Help') }
  	it { should have_title(full_title('Help')) }
  end

  describe "About page" do
  	before { visit about_path }

  	it { should have_content('About') }
  	it { should have_title(full_title('About')) }
  end
end