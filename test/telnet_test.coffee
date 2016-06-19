chai = require 'chai'
chai.should()
assert = chai.assert

telnet = require '../src/telnet'
TelnetStream = telnet.TelnetStream
Tel = telnet.Tel
Opt = telnet.Opt


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
        target.push Buffer.from [Tel.IAC, Tel.DO, Opt.NAWS]
        assert.deepEqual [[Tel.DO, Opt.NAWS]], commands
        assert.deepEqual [], data

    it 'can handle long commands', ->
        target = new TelnetStream()
        data = []
        commands = []
        target.on 'data', (d) -> data.push d
        target.on 'command', (d) -> commands.push d
        target.push Buffer.from [Tel.IAC, Tel.SB, Opt.NAWS, 0, 80, 0, 24, Tel.IAC, Tel.SE]
        assert.deepEqual [[Opt.NAWS, 0, 80, 0, 24]], commands
        assert.deepEqual [], data

    it 'can handle long commands across packet boundaries', ->
        target = new TelnetStream()
        data = []
        commands = []
        target.on 'data', (d) -> data.push d
        target.on 'command', (d) -> commands.push d
        target.push Buffer.from [Tel.IAC, Tel.SB, Opt.NAWS, 0]
        assert.deepEqual [], commands
        target.push Buffer.from [80, 0, 24, Tel.IAC, Tel.SE]
        assert.deepEqual [[Opt.NAWS, 0, 80, 0, 24]], commands
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
        buf.writeUInt8 Tel.IAC, 3
        buf.writeUInt8 Tel.DO, 4
        buf.writeUInt8 Opt.NAWS, 5
        k = buf.write 'lo world!\n', 6
        target.push buf.slice 0, k + 6
        assert.deepEqual [[Tel.DO, Opt.NAWS]], commands
        assert.deepEqual ['hello world!'], data

