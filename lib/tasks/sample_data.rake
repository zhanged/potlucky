namespace :db do
  desc "Fill database with sample data"
  task populate: :environment do
    admin = User.create!(name: "Example User",
                 email: "example@railstutorial.org",
                 password: "foobar",
                 password_confirmation: "foobar",
                 admin: true)
    99.times do |n|
      name  = Faker::Name.name
      email = "example-#{n+1}@railstutorial.org"
      password  = "password"
      User.create!(name: name,
                   email: email,
                   password: password,
                   password_confirmation: password)
    end

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
end