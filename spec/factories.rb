FactoryGirl.define do
	factory :user do
		name					"Edison Zhang"
		email					"edison@example.com"
		password				"foobar"
		password_confirmation	"foobar"
	end
end