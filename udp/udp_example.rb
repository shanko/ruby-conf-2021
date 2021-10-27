if RUBY_VERSION == '3.0'
  puts 'Using mruby 3.0 compiled using "mruby-socket" core gem'
else
 require 'socket'
end

host = '127.0.0.1'
port = 7777
mesg = 'message to self'
u1 = UDPSocket.new
u1.bind(host, port)
u1.send(mesg, 0, host, port)
data = u1.recvfrom(mesg.size)
p data

