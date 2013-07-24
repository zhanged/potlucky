require 'spec_helper'

describe Invitation do
  let(:invitee) { FactoryGirl.create(:user) }
  let(:gathering) { FactoryGirl.create(:gather) }
  let(:invitation) { gathering.invitations.build(invitee_id: invitee.id) }

  subject { invitation }

  it { should be_valid }

  describe "invitee and gathering methods" do
  	it { should respond_to(:invitee) }
  	it { should respond_to(:gathering) }
  	its(:invitee) { should eq invitee }
  	its(:gathering) { should eq gathering }
  end

  describe "when gathering id is not present" do
  	before { invitation.gathering_id = nil }
  	it { should_not be_valid }
  end

  describe "when invitee id is not present" do
  	before { invitation.invitee_id = nil }
  	it { should_not be_valid }
  end
end
