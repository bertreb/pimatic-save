# #pimatic-save configuration options
module.exports = {
  title: "pimatic-save configuration options"
  type: "object"
  properties:
    debug:
      description: "Debug mode. Writes debug messages to the pimatic log, if set to true."
      type: "boolean"
      default: false
}