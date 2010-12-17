require 'webrick'
server = WEBrick::HTTPServer.new :DocumentRoot => File.dirname(__FILE__) + '/html', :Port => 42225
trap('INT') { server.shutdown }
server.start
