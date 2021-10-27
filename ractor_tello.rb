# https://github.com/katoy/dron-tello/blob/master/tello.rb

## Ruby 3.0 script to control Tello drones using Ractors

require 'socket'

class Tello
  def initialize(local)
    @sockaddr = Socket.pack_sockaddr_in(8889, (local ? '127.0.0.1' : '192.168.10.1'))

    @udps = UDPSocket.open
    @udps.bind('0.0.0.0', 9000)

    @ractor = nil
  end

  def self.create(local=nil)
    me = self.new(local)
    me.receiver
    sleep(0.1)
    if block_given?
      me.do('command')
      me.do('takeoff')
      yield(me)
      me.close
    end
    me
  end

  def receiver
    @ractor ||= Ractor.new(@udps) do |udps|
      loop do
        begin
          retries ||= 0
          while(retries < 2) do
            sleep(0.1)
            resp = udps.recv(1518)
            puts "# #{retries+1}. response #{resp}"
            break if (resp.to_s.upcase == 'OK')
            retries += 1
          end
        rescue StandardError => e
          puts "# #{retries+1}. error #{e.message}"
          retry if (retries += 1) < 2
        end
      end
    end
  end

  def close
    puts '# close Tello'
    self.do('battery?')
    @udps.send('land', 0, @sockaddr)
    @udps.close
  end

  def do(message)
    puts "# send #{message}"
    @udps.send(message, 0, @sockaddr)
    sleep_well(message)
  end

private

  def sleep_well(cmd)
    verb = cmd.to_s.downcase.split(' ').first
    well = case verb
      when 'command'
        1
      when 'land'
        2
      when 'cw', 'ccw'
        3
      when 'up', 'down', 'left', 'right'
        4
      when 'takeoff'
        5
      else
        6 
      end

    puts "# sleeping for #{well} seconds"
    sleep(well)
    return well
  end
end

if __FILE__ == $0
  Tello.create(ARGV[0].to_s.downcase == 'local') do |tello|
    tello.do('flip r')
  end
end
