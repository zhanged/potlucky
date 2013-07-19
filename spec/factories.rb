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
		invited "friend1@gmail.com, friend2@gmail.com, friend3@gmail.com"
#      	location "Ladies of Avalon"
 #     	date "July 15"
  #    	time "7-10pm"
      	details "lorem ipsum"
      	tilt "4"
		user
	end
end