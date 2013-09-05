namespace :db do
  desc "Fill database with sample data"
  task populate: :environment do
    make_users
    make_gathers
#    make_invitations
  end
end

def make_users
  admin = User.create!(name: "Example User",
                 email: "example@railstutorial.org",
                 phone: "347-603-2899",
                 password: "foobar",
                 password_confirmation: "foobar",
                 admin: true)
  99.times do |n|
    name  = Faker::Name.name
    email = "example-#{n+1}@railstutorial.org"
    phone = "(347) 603-2899"
    password  = "password"
    User.create!(name: name,
                 email: email,
                 phone: phone,
                 password: password,
                 password_confirmation: password)
  end
end
    
def make_gathers
  users = User.all(limit: 6)
  50.times do |n|
    activity = "Activity Name #{n+1}"
    details = Faker::Lorem.sentence(word_count = 1)
    invited = User.find_by(id: Random.new.rand(1..99)).email*Random.new.rand(0..1) + ", " +
              User.find_by(id: Random.new.rand(1..99)).email*Random.new.rand(0..1) + ", " +
              User.find_by(id: Random.new.rand(1..99)).email*Random.new.rand(0..1) + ", " +
              User.find_by(id: Random.new.rand(1..99)).email*Random.new.rand(0..1) + ", " +
              User.find_by(id: Random.new.rand(1..99)).email*Random.new.rand(0..1) + ", " +
              User.find_by(id: Random.new.rand(1..99)).email*Random.new.rand(0..1) + ", " +
              User.find_by(id: Random.new.rand(1..99)).email*Random.new.rand(0..1) + ", " +
              User.find_by(id: Random.new.rand(1..99)).email*Random.new.rand(0..1) + ", " +
              User.find_by(id: Random.new.rand(1..99)).email*Random.new.rand(0..1) + ", " +
              User.find_by(id: Random.new.rand(1..99)).email*Random.new.rand(0..1)
    tilt = rand(1..invited.count("@"))
    users.each { |user| user.gathers.create!(activity: activity, details: details, invited: invited, tilt: tilt) }
  end
end

def make_invitations  # NOT IN USE!
  gathers = Gather.all
  300.times do |n|
    gather = gathers.find(n+1)
    #gather = gathers.first
    invitees = gather.invited.scan(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i)
    invitees.each { |invitee| gather.invite!(User.find_by(email: invitee)) }
  end
end