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
  SaveMailDevice: {
    title: "SaveMail config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      address:
        description: "Your email address"
        type: "string"
      password:
        description: "Your email password"
        type: "string"
      server:
        description: "smtp server address"
        type: "string"
      port:
        description: "smtp port used, default 587"
        type: "number"
        default: 587
      to:
        description: "The email address the mail is sent to. If empty the from email is used"
        type: "string"        
      subject:
        description: "The optional subject for the save mail"
        type: "string"
      text:
        description: "The optional text for the save mail"
        type: "string"
  }
}
