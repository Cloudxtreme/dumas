chai = require 'chai'
chai.should()
assert = chai.assert

telnet = require '../src/telnet'
TelnetStream = telnet.TelnetStream

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

describe 'Telnet stream', ->
    it 'can handle data', ->
        target = new TelnetStream()
        data = []
        commands = []
        target.on 'data', (d) -> data.push d
        target.on 'command', (d) -> commands.push d
        target.push Buffer.from 'hello there!\n'
        assert.deepEqual [], commands
        assert.deepEqual ['hello there!'], data

    it 'can handle a telnet escape sequence', ->
        target = new TelnetStream()
        data = []
        commands = []
        target.on 'data', (d) -> data.push d
        target.on 'command', (d) -> commands.push d
        target.push Buffer.from [IAC, DO, NAWS]
        assert.deepEqual [[DO, NAWS]], commands
        assert.deepEqual [], data

    it 'can handle long commands', ->
        target = new TelnetStream()
        data = []
        commands = []
        target.on 'data', (d) -> data.push d
        target.on 'command', (d) -> commands.push d
        target.push Buffer.from [IAC, SB, NAWS, 0, 80, 0, 24, IAC, SE]
        assert.deepEqual [[NAWS, 0, 80, 0, 24]], commands
        assert.deepEqual [], data

    it 'can handle long commands across packet boundaries', ->
        target = new TelnetStream()
        data = []
        commands = []
        target.on 'data', (d) -> data.push d
        target.on 'command', (d) -> commands.push d
        target.push Buffer.from [IAC, SB, NAWS, 0]
        assert.deepEqual [], commands
        target.push Buffer.from [80, 0, 24, IAC, SE]
        assert.deepEqual [[NAWS, 0, 80, 0, 24]], commands
        assert.deepEqual [], data

    it 'can handle data across packet boundaries', ->
        target = new TelnetStream()
        data = []
        commands = []
        target.on 'data', (d) -> data.push d
        target.on 'command', (d) -> commands.push d
        target.push Buffer.from 'hello '
        target.push Buffer.from 'there!\n'
        assert.deepEqual [], commands
        assert.deepEqual ['hello there!'], data

    it 'can handle multiple data bits in one piece', ->
        target = new TelnetStream()
        data = []
        commands = []
        target.on 'data', (d) -> data.push d
        target.on 'command', (d) -> commands.push d
        target.push Buffer.from 'hello\nworld!\n'
        assert.deepEqual [], commands
        assert.deepEqual ['hello', 'world!'], data

    it 'can handle commands interleaved with data', ->
        target = new TelnetStream()
        data = []
        commands = []
        target.on 'data', (d) -> data.push d
        target.on 'command', (d) -> commands.push d
        buf = new Buffer(1024)
        buf.write 'hel', 0
        buf.writeUInt8 IAC, 3
        buf.writeUInt8 DO, 4
        buf.writeUInt8 NAWS, 5
        k = buf.write 'lo world!\n', 6
        target.push buf.slice 0, k + 6
        assert.deepEqual [[DO, NAWS]], commands
        assert.deepEqual ['hello world!'], data

