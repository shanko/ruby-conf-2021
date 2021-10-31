
## Adapted from Python:
#   https://raw.githubusercontent.com/dbaldwin/DroneBlocks-TelloEDU-Python/master/swarm-box-mission.py
#
## Ruby script to connect to two TelloEDU drones and control them simultaneously

require 'socket'
require 'time'

SEND_PORT = 8889         # Defined by Tello
SEND_IP   = '192.168.0.' # Defined by TP-LINK

IP_1 = SEND_IP + (ARGV[0] || '101')
IP_2 = SEND_IP + (ARGV[1] || '102')

# Create UDP sockets that we'll send the command to
$sock_1 = Socket.pack_sockaddr_in(SEND_PORT, IP_1)
$sock_2 = Socket.pack_sockaddr_in(SEND_PORT, IP_2)

# Create UDP sockets which will recieve the response
$udps_1 = UDPSocket.new; $udps_1.bind('0.0.0.0', 9001)
$udps_2 = UDPSocket.new; $udps_2.bind('0.0.0.0', 9003)

# set error
$error = false

# Send the message to Tello and allow for a delay in seconds
def send(commands, delay)
  begin
    if commands.size == 2
      cmd_1, cmd_2 = commands
    else
      cmd_1 = cmd_2 = commands.first
    end
    $udps_1.send(cmd_1, 0, $sock_1)
    $udps_2.send(cmd_2, 0, $sock_2)
    puts("Sent commands: #{[cmd_1, cmd_2]} at #{Time.now.to_s}")
  rescue Exception => e
    puts("Error sending commands #{[cmd_1, cmd_2]}: #{e.to_s}")
  end

  # Delay for a user-defined period
  sleep(delay)
end

# Receive the message from Tello
def receive
  # Continuously loop and listen for incoming messages
  while true
    begin
      resp_1 = $udps_1.recv(512).to_s ## Buffer length must be longer than the message
      resp_2 = $udps_2.recv(512).to_s

      puts("Received message from Tello EDU #1: #{resp_1}")
      puts("Received message from Tello EDU #2: #{resp_2}")
      $error = ((resp_1 =~ /error/i) || (resp_2 =~ /error/i)) if ($error == false)
    rescue Exception => e
      # If there's an error close the socket and break out of the loop
      $udps_1.close
      $udps_2.close
      puts("Error receiving: #{e.to_s}") if $DEBUG
      $error = true
      break
    end
  end
end

## Capture Video of the flying drones if connected to 
## Raspberry Pi with camera
def capture_video(milli_seconds)
  return if ($error || (RUBY_PLATFORM != 'arm-linux-gnueabihf'))

  get_camera_status = `vcgencmd get_camera`.strip
  return if (get_camera_status != 'supported=1 detected=1')

  Thread.new do
    cmd = "capture_vdo.sh #{milli_seconds}"
    sleep(0.1) ## so that the main thread gets scheduled
    puts `#{cmd}`
  end
end

# Create and start a listening thread that runs in the background
# This utilizes our receive functions and will continuously 
# monitor for incoming messages
th = Thread.new { receive }

# Put Tello into command mode
send(['command'], 1)

# start video capture if possible
capture_video((1+7+2) * 1000) ## sum of the delays in commands below

# Get battery levels
send(['battery?'], 1)

# Send the takeoff command
send(['takeoff'], 7)

# Flip
# send(['flip r','flip l'], 7)

# Flip again
# send(['flip l','flip r'], 7)
# send(['ccw 90','cw 90'], 4)

# Land
send(['land'], 2)

puts("Mission completed with #{$error ? 'error' : 'success'}!")

# Close the sockets
$udps_1.close
$udps_2.close

