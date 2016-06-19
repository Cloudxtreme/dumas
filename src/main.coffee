argparse = require 'argparse'
fs = require 'fs'
#telnet = require './telnet'
#loader = require './loader'


main = () ->
  obj = JSON.parse fs.readFileSync __dirname + "/../package.json", {encoding: 'utf8'}
  parser = new argparse.ArgumentParser {
    version: obj.version
    addHelp: true
    description: "MUD friend!"
  }
  parser.addArgument ['-p', '--port'],
    help: 'port to listen on'
    defaultValue: 7447
  parser.addArgument ['-r', '--root'],
    help: 'root of the data directory'
    defaultValue: 'data/'
  args = parser.parseArgs()

main()
