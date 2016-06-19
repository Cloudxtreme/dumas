net = require 'net'
log = require('./log').childLogger 'telnet'
EventEmitter = require 'events'

class TelnetServer extends EventEmitter
  constructor: (@host, @port) ->

  listen: ->
    @server = net.createServer {pauseOnConnect: true}
    @server.on 'connection', (sock) => @newClient sock
    @server.listen @port, @host

  shutdown: ->
    if @server?
      @server.close()
      @server = null
    else
      log.warn 'closed an already closed TelnetServer'


  newClient: (sock) ->
    s = new TelnetSocket sock
    s.start()
    @emit 'connection', s

# Subcommands.
Opt =
  NAWS: 30
  CHARSET: 42
  GMCP: 201

Charset =
  REQUEST: 1
  ACCEPT: 2
  REJECT: 3

# General protocol stuff
Tel =
  SE: 240
  NOP: 241
  DM: 242
  BRK: 243
  IP: 244
  AO: 245
  AYT: 246
  EC: 247
  EL: 248
  GA: 249
  SB: 250
  WILL: 251
  WONT: 252
  DO: 253
  DONT: 254
  IAC: 255


class TelnetSocket
  ACCEPTABLE_ENCODINGS = ['ascii', 'utf8', 'utf-8', 'utf_8']
  constructor: (@sock) ->
    @inputStream = new TelnetStream @sock
    @inputStream.on 'data', (data) => @emit 'data', data
    @inputStream.on 'command', (cmd) => @acceptCommand

  start: ->
    @sock.resume()
    if not TelnetSocket.INIT?
      i = 0
      buf = Buffer.from [
        # Window size is essential.
        Tel.IAC,
        Tel.DO,
        Opt.NAWS,

        # We hope that the client will do charset negotiations.
        # Sadly, none do.
        Tel.IAC,
        Tel.WILL,
        Opt.CHARSET,

        Tel.IAC,
        Tel.WONT,
        Opt.GMCP
      ]
      TelnetSocket.INIT = buf
    @sock.write TelnetSocket.INIT

  write: (str) ->
    @sock.write str

  close: -> @sock.end()

  askAboutCharsets: ->
    if not TelnetSocket.CHARSET_NEGOTIATION?
      basic = ';'.join TelnetSocket.ACCEPTABLE_ENCODINGS
      all = "#{basic};#{basic.toUpperCase()}"
      buf = new Buffer(all.length + 5)
      buf.writeUInt8 Tel.IAC, 0
      buf.writeUInt8 Tel.SB, 1
      buf.writeUInt8 Opt.CHARSET, 2
      buf.write all, 3, 'ascii'
      buf.write Tel.IAC, buf.length - 2
      buf.write Tel.SE, buf.length - 1
      TelnetSocket.CHARSET_NEGOTIATION = buf
    @sock.write TelnetSocket.CHARSET_NEGOTIATION

  acceptCommand: (cmd) ->
    switch cmd[0]
      when Opt.NAWS
        console.log "window size"
      when Opt.GMCP
        console.log "gmcp"
      when Opt.CHARSET
        if cmd[1] == Charset.ACCEPT
          buf = Buffer.from cmd.slice 2
          charset = buf.toString 'ascii'
          switch charset.toLowerCase()
            when 'utf-8', 'utf8', 'utf_8'
              @charset = 'utf8'
            else
              @charset = 'ascii'

      when Tel.DO
        type = cmd[1]
        if type == Opt.CHARSET
          @askAboutCharsets()
        else
          # They want us to do something we can't do.
          @sock.write Buffer.from [Tel.IAC, Tel.WONT, type]
      when Tel.WILL
        # Okay, you'll do it. Nice.
        log.info "client wants to #{cmd[1]}"
      when Tel.DONT, Tel.WONT
        # Not much 
        log.info "client refuses option #{cmd[1]}"



# A stream to handle telnet input in a convenient streaming fashion.
#
# This takes raw input and emits two streams:
#  * A command stream, on the 'command' event.
#  * A data (text) stream, on the 'data' event.
#
# Commands come in two forms:
#  - WILL/WONT/DO/DONT [type]
#  - [type] data...
#
# For instance, let's say the client wants to negotiate about window size.
# It sends [IAC WILL NAWS].
# TelnetStream raises the 'command' event with data [WILL NAWS].
# Then the server sends back [IAC DO NAWS].
# The client sends its window size info: [IAC SB NAWS 0 80 0 24 IAC SE].
# TelnetStream raises the 'command' event with data [NAWS 0 80 0 24].
#
# You get the stuff that's interesting without having to slice off anything
# you don't care about. It *is* pretty raw, but you can handle that.
class TelnetStream extends EventEmitter
  TEXT = 0
  SHORTCMD = 1
  EXTCMD = 2
  SOMECMD = 3
  EXTCMDIAC = 4
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
        if octet == Tel.IAC
          @joinState SOMECMD
          continue
        @pushTextOctet octet
      if state == SOMECMD
        switch octet
          when Tel.IAC
            @popState()
            if state == EXTCMD
              @command.push Tel.IAC
            else
              @pushTextOctet Tel.IAC
          when Tel.DO, Tel.DONT, Tel.WILL, Tel.WONT
            @command.push octet
            @joinState SHORTCMD
          when Tel.SB
            @joinState EXTCMD
            continue
      if state == EXTCMD
        if octet == Tel.IAC
          @joinState EXTCMDIAC
          continue
        @command.push octet
      if state == EXTCMDIAC
        if octet == Tel.IAC
          @command.push Tel.IAC
        else if octet == Tel.SE
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
exports.Tel = Tel
exports.Opt = Opt

