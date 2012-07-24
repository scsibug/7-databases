require 'rubygems'
require 'riak'
STYLES = %w{single double queen king suite}

client = Riak::Client.new(:http_port => 8091)
bucket = client.bucket('rooms')
# Create 100 floors to the building
for floor in 1..100
  current_rooms_block = floor * 100
  puts "Making rooms #{current_rooms_block} - #{current_rooms_block + 100}"
  # Put 100 rooms on each floor (huge hotel!)
  for room in 1..100
    # create a unique room number as the key
    ro = Riak::RObject.new(bucket, (current_rooms_block + room))
    # randomly grab a room style, and make up a capacity
    style = STYLES[rand(STYLES.length)]
    capacity = rand(8) + 1
    # store the room information as a json value
    ro.content_type = "application/json"
    ro.data = {'style' => style, 'capacity' => capacity}
    ro.store
  end
end
