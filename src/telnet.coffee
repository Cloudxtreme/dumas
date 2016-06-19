net = require 'net'
log = require('./log').childLogger 'telnet'
EventEmitter = require 'events'

class TelnetServer extends EventEmitter
  constructor: (@host, @port) ->

    listen: ->
      @server = net.createServer {pauseOnConnect: true}, (sock) => @newClient sock

    shutdown: ->
      if @server?
        @server.close()
        @server = null
      else
        log.warn 'closed an already closed TelnetServer'


    newClient: (sock) ->
      @emit 'connection', new TelnetSocket sock

NAWS = 30

SE = 240
NOP = 241
DM = 242
BRK = 243
IP = 244
AO = 245
AYT = 246
EC = 247
EL = 248
GA = 249
SB = 250
WILL = 251
WONT = 252
DO = 253
DONT = 254
IAC = 255

TEXT = 0
SHORTCMD = 1
EXTCMD = 2
SOMECMD = 3
EXTCMDIAC = 4
class TelnetSocket
  constructor: (@sock) ->

class TelnetStream extends EventEmitter
  constructor: ->
    @encoding = 'ascii'
    @text = new Buffer(4096)
    @textOffset = 0
    @command = []
    @state = TEXT
    @lastState = TEXT

  joinState: (state) ->
    @lastState = @state
    @state = state

  popState: ->
    @state = @lastState

  pushTextOctet: (octet) ->
    # We only support ascii and utf8.
    # (I don't trust this to properly support utf8, but here's hoping.)
    if @textOffset >= @text.length or octet == 10 or octet == 13
      # Emit text thing!
      text = @text.slice(0, @textOffset).toString @encoding
      @emit 'data', text
      @textOffset = 0
    if octet != 10 and octet != 13
      @text.writeUInt8 octet, @textOffset
      @textOffset++

  push: (data) ->
    for octet in data
      state = @state
      if state == TEXT
        if octet == IAC
          @joinState SOMECMD
          continue
        @pushTextOctet octet
      if state == SOMECMD
        switch octet
          when IAC
            @popState()
            if state == EXTCMD
              @command.push IAC
            else
              @pushTextOctet IAC
          when DO, DONT, WILL, WONT
            @command.push octet
            @joinState SHORTCMD
          when SB
            @joinState EXTCMD
            continue
      if state == EXTCMD
        if octet == IAC
          @joinState EXTCMDIAC
          continue
        @command.push octet
      if state == EXTCMDIAC
        if octet == IAC
          @command.push IAC
        else if octet == SE
          @state = TEXT
          @emit 'command', @command
          @command = []
      if state == SHORTCMD
        @command.push octet
        @emit 'command', @command
        @command = []
        @joinState TEXT







exports.TelnetServer = TelnetServer
exports.TelnetStream = TelnetStream

