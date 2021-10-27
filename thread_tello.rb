# https://github.com/katoy/dron-tello/blob/master/tello.rb
require 'socket'

## Ruby 2.x script to control Tello drones using Threads

class Tello
  def initialize(local)
    @udps = UDPSocket.open
    @sockaddr = Socket.pack_sockaddr_in(8889, (local ? '127.0.0.1' : '192.168.10.1'))
    @udps.bind('0.0.0.0', 9000)
    @th = nil
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
    @th ||= Thread.start(@udps) do |udps|
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
    @udps.send('land', 0, @sockaddr)
    @th.kill
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
        0.5
      when 'land'
        1.5
      when 'cw', 'ccw'
        2.5
      when 'up', 'down', 'left', 'right'
        3.5
      when 'takeoff'
        4.5
      when 'flip'
        5.5
      else
        6.5
      end

    puts "# sleeping for #{well} seconds"
    sleep(well)
    return well
  end
end

if __FILE__ == $0
  Tello.create(ARGV[0].to_s.downcase == 'local') do |tello|
    tello.do('flip l')
  end
end
