# mruby script to  control Tello drones
# Adapted from: https://github.com/katoy/dron-tello/blob/master/tello.rb

if RUBY_VERSION == '3.0'
  puts 'Using mruby 3.0 compiled using "mruby-socket" core gem'
else
 require 'socket'
end

# Uses fibers instead of threads for communication with Tello
class Tello

  FIXED_IP     = '192.168.10.1'  ## Defined by Tello
  COMMAND_PORT = 8889            ## Port to which command  is sent - fixed by Tello firmware
  RESPOND_PORT = 9000            ## Port on which response is received - can be any other port

  RESPONSE_BUFFLEN = 1518        ## Length of the response buffer - as per Tello sample python code Tello3.py

  def initialize(tello_ip)
    @fiber    = nil
    @swarm    = (tello_ip == FIXED_IP)
    @sockaddr = Socket.pack_sockaddr_in(COMMAND_PORT, tello_ip)
    port      = RESPOND_PORT
    @udps     = UDPSocket.open
    @udps.bind('0.0.0.0', port)
  end

  def self.create(*args)
    ip_str = args.first.to_s.strip.downcase

    case
    when ip_str == 'local'
      tello_ip = '127.0.0.1'
    when ip_str.size == 3
      tello_ip = "192.168.0.#{ip_str}"
    when valid_IPv4?(ip_str)
      tello_ip = ip_str
    else
      tello_ip = FIXED_IP
    end

    p({tello_ip: tello_ip, port: RESPOND_PORT})
    me = self.new(tello_ip)
    me.receiver

    if block_given?
      me.do('command')
      me.do('battery?')
      me.do('takeoff')
      yield(me)
      me.close
    end
    me
  end

  def receiver
    @fiber ||= Fiber.new do
      loop do
        begin
          resp = @udps.recv(RESPONSE_BUFFLEN).to_s.strip
          puts "# response = '#{resp}'"

          Fiber.yield if (resp.size > 0)

        rescue StandardError => e
          puts "# error = '#{e.message}'"
        end
      end
    end
  end

  def close
    self.do('land')
    puts '# close Tello'
    @udps.close
  end

  def do(message)
    message = sanitize(message)
    puts "# send #{message}"
    @udps.send(message, 0, @sockaddr)
    puts('# waiting for response')
    @fiber.resume if @fiber
  end

private

  def self.valid_IPv4?(ip)
    if RUBY_VERSION == '3.0'
      (ip.to_s.split('.').size == 4)
    else
      ip.to_s =~ /^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$/
    end
  end

  def sanitize_distance(d)
    dist = d.to_i
    dist = 20  if dist < 20
    dist = 500 if dist > 500
    dist.to_s
  end

  def sanitize_speed(s)
    speed = s.to_i
    speed = 10  if speed < 10
    speed = 100 if speed > 100
    speed.to_s
  end

  def sanitize(message)
    arr = message.to_s.downcase.split(' ')
    return (arr[0] || 'land') if arr.size < 2

    case arr[0]
    when 'up', 'down', 'left', 'right', 'forward', 'backward'
       arr[1] = sanitize_distance(arr[1])
    when 'cw', 'ccw'
       degrees = arr[1].to_i
       degrees = 1   if degrees < 1
       degrees = 360 if degrees > 360
       arr[1] = degrees.to_s
    when 'flip'
       arr[1] = 'l' unless ['l','r','f','b'].include?(arr[1])
    when 'speed'
       arr[1] = sanitize_speed(arr[1])
    when 'go'
       _,x,y,z,s = arr
       arr[1],arr[2],arr[3],arr[4] = sanitize_distance(x),sanitize_distance(y),sanitize_distance(z),sanitize_speed(s)
    else
      # do nothing
    end

    arr.join(' ')
  end

end

if __FILE__ == $0
  Tello.create(*ARGV) do |tello|
    ## Do something
    tello.do('cw 90')
    # tello.do('ccw 90')
    # tello.do('flip l')
    # tello.do('flip r')
  end
end
