require 'spec_helper'

describe Gather do
  
  let(:user) { FactoryGirl.create(:user) }
  before do
  	@gather = user.gathers.build(
  		activity: "Potluck", 
  		invited: "user1@example.com; user2@example.com,user3@example.com",
  		details: "lorem ipsum",
  		tilt: 2)
  end

  subject { @gather }

  it { should respond_to(:activity) }
  it { should respond_to(:invited) }
  it { should respond_to(:details) }
  it { should respond_to(:tilt) }
  its(:user) { should eq user }

  it { should be_valid }

  describe "when user_id is not present" do
  	before { @gather.user_id = nil }
  	it { should_not be_valid }
  end

  describe "with blank activity name" do
  	before { @gather.activity = " " }
  	it { should_not be_valid }
  end

  describe "with activity name that is too long" do
  	before { @gather.activity = "a" * 41 }
  	it { should_not be_valid }
  end

  describe "with tilt that is greater than emails" do
    before { @gather.tilt = 2 + @gather.invited.count("@") }
    it { should_not be_valid }
  end
end