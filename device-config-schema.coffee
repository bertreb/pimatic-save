module.exports = {
  title: "pimatic-save device config schemas"
  SaveFtpDevice: {
    title: "SaveFtp config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      host:
        description: "Url to the backup server"
        type: "string"
      port:
        description: "Port of the backup server"
        type: "number"
        default: 21
      username:
        description: "Username of the backup server"
        type: "string"
      password:
        description: "Password of the backup server"
        type: "string"
      path:
        description: "Remote path of the backup server where the config should be saved"
        type: "string"
  }
  SaveDropboxDevice: {
    title: "SaveDropbox config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      accessToken:
        description: "AccesToken generated for your pimatic-save upload folder"
        type: "string"
      path:
        description: "Remote path of the backup server where the config should be saved"
        type: "string"
      overwrite:
        description: "If enabled and a file already exists on Dropbox the new version will overwrite the old one. If disabled the file will get a (version nr) added in the filename"
        type: "boolean"
  }
}
