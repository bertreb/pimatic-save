module.exports = (env) ->

  events = env.require 'events'
  fs = require 'fs'
  path = require 'path'
  FtpClient = require 'promise-ftp'
  Dropbox = require('dropbox').Dropbox
  nodemailer = require('nodemailer')
  fetch = require 'isomorphic-fetch'
  M = env.matcher
  _ = require 'lodash'
  dateFormat = require('dateformat')

  class SavePlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>

      @baseDir = path.resolve @framework.maindir, '../..'


      deviceConfigDef = require("./device-config-schema")
      @framework.deviceManager.registerDeviceClass('SaveFtpDevice', {
        configDef: deviceConfigDef.SaveFtpDevice,
        createCallback: (config, lastState) => new SaveFtpDevice(config, lastState, @framework)
      })
      @framework.deviceManager.registerDeviceClass('SaveDropboxDevice', {
        configDef: deviceConfigDef.SaveDropboxDevice,
        createCallback: (config, lastState) => new SaveDropboxDevice(config, lastState, @framework)
      })
      @framework.deviceManager.registerDeviceClass('SaveMailDevice', {
        configDef: deviceConfigDef.SaveMailDevice,
        createCallback: (config, lastState) => new SaveMailDevice(config, lastState, @framework)
      })
      saveClasses = ["SaveFtpDevice","SaveDropboxDevice","SaveMailDevice"]
      @framework.ruleManager.addActionProvider(new SaveActionProvider(@framework, saveClasses, @baseDir))


  class SaveFtpDevice extends env.devices.PresenceSensor

    constructor: (@config, lastState, @framework) ->

      @id = @config.id
      @name = @config.name

      @host = @config.host
      @port = @config.port
      @username = @config.username
      @password = @config.password
      @root = path.resolve @framework.maindir, '../..'
      @_setPresence(off)

      super()

    upload: (readFilename, timestamp, saveFilename, @saveDeviceId) =>
      return new Promise((resolve,reject) =>
        _config = (_.find(@framework.config.devices, (d) => d.id is @saveDeviceId))
        client = new FtpClient() 
        client.connect({
          host: _config.host,
          port: _config.port or 21,
          user: _config.username,
          password: _config.password
        })
        .then((serverMessage) =>
          fs.readFile(path.join(@root, readFilename), (err, content) =>
            if (err)
              env.logger.error "File '#{readFilename}' not found in FTP readFile: "
              client.destroy()
              reject()
            _saveFilename = saveFilename
            if timestamp
              d = new Date()
              ts = dateFormat(d,"yyyy-mm-dd_HHMMss")
              _saveFilename = ts + "_" + _saveFilename
            # If the path does not end with a slash, add one
            if _config.path.endsWith('/')
              slash = ''
            else
              slash = '/'
            client.put(content, _config.path + slash + _saveFilename)
            .then(() =>
              env.logger.info "File '#{_saveFilename}' saved to FTP server"
              client.destroy()
              resolve()
            )
            .catch((err) =>
              env.logger.error "Error put, probably wrong path (not existing on ftp server): " + err
              client.destroy()
              reject()
            )
          )
        )
        .catch((err) =>
          switch err.code
            when "ECONNREFUSED"
              env.logger.error "Can't connect to FTP server, server probably offline"
            else
              env.logger.error "Error: " + err.message
          client.destroy()
          reject()
        )
      )

    destroy: () =>
      super()

  class SaveDropboxDevice extends env.devices.PresenceSensor

    constructor: (@config, lastState, @framework) ->
      @id = @config.id
      @name = @config.name

      @accessToken = @config.accessToken
      @root = path.resolve @framework.maindir, '../..'

      @_setPresence(off)

      super()

    upload: (readFilename, timestamp, saveFilename, saveDeviceId) =>
      return new Promise((resolve,reject) =>
        _config = (_.find(@framework.config.devices, (d) => d.id is saveDeviceId))
        fs.readFile(path.join(@root, readFilename), (err, content) =>
          if (err)
            env.logger.error "File '#{readFilename}' not found in Dropbox readFile: "
            reject()
          if timestamp
            d = new Date()
            ts = dateFormat(d,"yyyy-mm-dd_HHMMss")
            saveFilename = ts + "_" + saveFilename
          if _config.dateStructure?
            if _config.dateStructure
              _dateStructure = dateFormat(d,"yyyy") + "/" + dateFormat(d,"mm") + "/" + dateFormat(d,"dd") + "/"
              saveFilename = _dateStructure + saveFilename
          if _config.path.endsWith('/') then slash = '' else slash = '/'
          saveFilename = _config.path + slash + saveFilename
          unless saveFilename.startsWith("/") then saveFilename = "/" + saveFilename
          env.logger.debug "Writing file '#{readFilename}' to dropbox " + saveFilename
          if _config.overwrite then _mode = "overwrite" else _mode = "add"
          dbx = new Dropbox({accessToken: @accessToken, fetch: fetch})
          dbx.filesUpload({path: saveFilename, strict_conflict: false,  mode: _mode, autorename: true, contents: content})
          .then((response) ->
            env.logger.info "File '#{saveFilename}' saved to Dropbox"
            resolve()
          ).catch ((err) ->
            env.logger.error "Error on save to Dropbox: " + JSON.stringify(err.error,null,2)
            reject()
          )
        )
      )

    destroy:() =>
      super()


  class SaveMailDevice extends env.devices.PresenceSensor

    constructor: (@config, lastState, @framework) ->
      @id = @config.id
      @name = @config.name

      @address = @config.address
      @to = @config.to ? @config.address
      @password = @config.password
      @server = @config.server
      @port = @config.port ? 587
      @subject = @config.subject ? ""
      @text = @config.text ? "Message from pimatic-save."

      @accessToken = @config.accessToken
      @root = path.resolve @framework.maindir, '../..'

      @_setPresence(off)

      super()

    upload: (readFilename, timestamp, saveFilename, saveDeviceId) =>
      return new Promise((resolve,reject) =>
        unless @address? and @password? then reject("Credentials not set")
        _config = (_.find(@framework.config.devices, (d) => d.id is saveDeviceId))
        env.logger.debug "Resolved path " + path.resolve(@root, readFilename)
        fs.readFile(path.join(@root, readFilename), (err, content) =>
          if (err)
            env.logger.error "File '#{readFilename}' not found in mail readFile: "
            reject()
          d = new Date()
          ts = dateFormat(d,"yyyy-mm-dd HH:MM:ss")
          if timestamp
            saveFilename = ts + " " + saveFilename
          env.logger.debug "Sending file '#{readFilename}' to '#{@to}'"

          transporter = nodemailer.createTransport({
            host: @server,
            port: @port,
            auth:
              user: @address
              pass: @password
          })

          if @subject?
            _subject = @subject + ', '
          else
            _subject = ""

          mailOptions =
            from: @address
            to: @to
            subject: _subject + ts 
            text: @text
            attachments: [ 
              {
                filename: saveFilename
                content: content
              }
            ]

          transporter.verify((err, success) =>
            if err 
              env.logger.debug "Error verifying server " + err
              reject("Error verifying server")
            else
              env.logger.debug "Server is ready"
              transporter.sendMail(mailOptions, (err, info) =>
                if err
                  env.logger.error "Error on save to mail: " + JSON.stringify(err.error,null,2)
                  reject()
                else
                  env.logger.info "File '#{readFilename}' saved to " + @to
                  resolve()
              )
              resolve()
          )
        )
      )

    destroy:() =>
      super()



  class SaveActionProvider extends env.actions.ActionProvider

    constructor: (@framework, @saveClasses, @dir) ->
      @root = path.resolve @framework.maindir, '../..'

    _saveClasses: (_cl) =>
      for _saveClass in @saveClasses
        if _cl is _saveClass
          return true
      return false

    parseAction: (input, context) =>
      @saveDevices = _(@framework.deviceManager.devices).values().filter(
        (device) => @_saveClasses(device.config.class)
      ).value()
      readFilename = null
      saveDevice = null
      saveFilename = null
      match = null
      timestamp = null

      setFilename = (m, tokens) =>
        readFilename = tokens
        if (readFilename.join('')).indexOf(" ") >= 0
          context?.addError("no spaces allowed in filestring")
          return
        return

      ###
      setFilename = (m, filename) =>
        fullfilename = path.join(@root, filename)
        try
          stats = fs.statSync(fullfilename)
          if stats.isFile()
            readFilename = filename
            return
          else if stats.isDirectory()
            context?.addError("'" + fullfilename + "' is a directory")
            return            
          else 
            context?.addError("File " + fullfilename + "' does not excist")
            return            
        catch err
          context?.addError("File " + fullfilename + "' does not excist")
          return
      ###

      # Action arguments: save "filename" [with timestamp] to <saveDevice>
      m = M(input, context)
        .match('save ')
        .matchStringWithVars(setFilename)
        .match(' with timestamp',{optional: true}, (m, t) ->
          timestamp = t
        )
        .match(' to ')
        .matchDevice(@saveDevices, (m, d) ->
          # Already had a match with another device?
          if device? and device.id isnt d.id
            context?.addError(""""#{input.trim()}" is ambiguous.""")
            return
          saveDevice = d
        )

      saveFilename = path.basename(String readFilename)

      if m.hadMatch()
        match = m.getFullMatch()
        env.logger.debug "Rule matched: '", match, "' and passed to Action handler"
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new SaveActionHandler(@framework, @, readFilename, timestamp, saveFilename, saveDevice, @dir)
        }
      else
        return null


  class SaveActionHandler extends env.actions.ActionHandler

    constructor: (@framework, @actionProvider, @readFilename, @timestamp, @saveFilename, @saveDevice, @dir) ->

    executeAction: (simulate) =>
        if simulate
          return __("would save file \"%s\"", @readFilename)
        else
          @framework.variableManager.evaluateStringExpression(@readFilename).then( (strToLog) =>
            filename = strToLog
            saveFilename = filename
            fullfilename = path.join(@dir, filename)
            try
              #stats = fs.statSync(fullfilename)
              if fullfilename.indexOf(" ")>=0
                return __("\"%s\" no spaces allowed in filename",filename)
              else if fs.existsSync(fullfilename)
                @saveDevice.upload(filename, @timestamp, saveFilename, @saveDevice.id).then(() =>
                  @saveDevice._setPresence(on)
                  return __("\"%s\" was saved", filename)
                ).catch((err)=>
                  @saveDevice._setPresence(off)
                  return __("\"%s\" was not saved", filename)
                )
              else
                return __("\"%s\" does not excist", filename)
            catch err
              return __("\"%s\" error in save execute", err)
          )

    destroy: () ->
      super()

  savePlugin = new SavePlugin
  return savePlugin
