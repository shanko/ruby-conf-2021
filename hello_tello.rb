# Ruby script to connect to 2 EDU drones and control them simultaneously: basic takeoff and land

# Adapted from Python: https://raw.githubusercontent.com/dbaldwin/DroneBlocks-TelloEDU-Python/master/swarm-box-mission.py

require 'socket'
require 'time'

## Constants defined by Tello
HOST = '192.168.10.1'
PORT = 8889
BUFF_LEN = 1518

# Create UDP sockets which will recieve the response on any other port
$udps = UDPSocket.new; $udps.bind('0.0.0.0', 9001)

# Send the message to Tello and allow for a delay in seconds
def send(message, delay)

  bytes = 0

  # Try to send the message otherwise print the exception
  begin
    bytes = $udps.send(message, 0, HOST, PORT)
    puts("Sent message: '#{message}' of #{bytes} bytes")
  rescue Exception => e
    puts("Error sending message '#{message}': " + e.to_s)
  end

  # Delay for a user-defined period
  sleep(delay)

  bytes
end

# Receive the message from Tello
def receive
  # Continuously loop and listen for incoming messages
  while true
    # Try to receive the message otherwise print the exception
    begin
      resp, sender = $udps.recvfrom(BUFF_LEN)
      puts("Received message: '#{resp.to_s.chomp}' from #{sender}")
    rescue Exception => e
      # If there's an error close the socket and break out of the loop
      $udps.close
      # puts("Error receiving message: " + e.to_s)
      break
    end
  end
end

# Create and start a listening thread that runs in the background
# This utilizes our receive functions and will continuously monitor
# for incoming messages
th = Thread.new { receive }

# Put Tello into command mode
send("command", 2)

# Check battery status
send("battery?", 2)

# Check battery status
send("time?", 2)

# Takeoff
send("takeoff", 8)

# Flip
send("flip l", 8)
send("flip r", 8)

# Land
send("land", 4)

# Close the socket
#$udps.close

puts 'Mission Accomplished'
