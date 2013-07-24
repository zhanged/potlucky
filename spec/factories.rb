FactoryGirl.define do
	factory :user do
		sequence(:name)			{ |n| "Person #{n}" }
		sequence(:email)		{ |n| "person_#{n}@example.com" }
		password				"foobar"
		password_confirmation	"foobar"

		factory :admin do
			admin true
		end
	end

	factory :gather do
		activity "Lorem ipsum"
		invited "person_92@example.com, person_103@example.com, person_54@example.com"
      	details "the details"
      	tilt "4"
		user
	end
end