require 'rubygems'
require 'twilio-ruby'
 
account_sid = "ACbb2447b2100021b9e65920128431f756"
auth_token = "2ff59ce4c8f6b6b6eb871c61d9f9fc50"
client = Twilio::REST::Client.new account_sid, auth_token
 
from = "+14154231000" # Your Twilio number
 
friends = {
"+13476032899" => "Curious George"
#"+14155557775" => "Boots",
#"+14155551234" => "Virgil"
}
friends.each do |key, value|
  client.account.sms.messages.create(
    :from => from,
    :to => key,
    :body => "Hey #{value}, Monkey party at 6PM. Bring Bananas!"
  ) 
  puts "Sent message to #{value}"
end