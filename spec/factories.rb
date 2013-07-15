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
		invited "SF Friends"
      	location "Ladies of Avalon"
      	date "July 15"
      	time "7-10pm"
      	details "lorem ipsum"
      	tilt "5"
		user
	end
end