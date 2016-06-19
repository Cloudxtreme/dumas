argparse = require 'argparse'
fs = require 'fs'
telnet = require './telnet'
#loader = require './loader'


main = () ->
  pkg = JSON.parse fs.readFileSync __dirname + "/../package.json", {encoding: 'utf8'}
  config = JSON.parse fs.readFileSync __dirname + "/../config.json", {encoding: 'utf8'}
  port = config.port or 2117
  host = config.host or '0.0.0.0'
  server = new telnet.TelnetServer host, port
  server.on 'connection', (c) ->
    c.write "Hi there!\n"
    c.close()
    #setTimeout (-> c.close()), 100
  server.listen()
  console.log "listening on #{host}:#{port}"


main()
