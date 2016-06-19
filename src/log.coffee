bunyan = require 'bunyan'

log = bunyan.createLogger {name: 'dumas'}

exports.childLogger = (name) -> log.child {module: name}
