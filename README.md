# pimatic-save
Plugin for saving files to backup media

With this plugin you can save files from the system Pimatic is running to a backup medium. The supported media in this release are FTP and mail.

The save of a file is done via an action rule. The medium independent action syntax is
```
save "[localpath/]filename" [with timestamp] to SaveFtpDevice | SaveMailDevice
```

The optional 'with timestamp' adds a timestamp in front of the filename.
The 24-hour timestamp format is "yyyy-mm-dd_hhmmss". With 24-hour format.
The filename can hold a local path and should follow the local operating system conventions (linux, windows). When adding an action the existance of the file is checked. The file needs to exist for the rule to be saved.
The base of the filename is the home directory of Pimatic. For rpi thats mostly the /home/pi/pimatic-app directory. You could use directory navigation like "../.." in the filename to select files outside the base directory.

To make a daily backup during the night at 1:00 of your config.json the rule is

```
when 'its 1:00' then 'save "config.json" with timestamp to <your FtpOrMail Device>'
```

# The SaveFtpDevice

With this device files will be saved to a Ftp server.
The following device config.

```
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
```

The path is the path from the login root that is specific for your ftp account. The path needs to exist on the ftp server! When a file already exists, the old version will be overwritten!

The FTP connection is made only when a file is saved. So the presence dot will only be presence on saving a file.

# The SaveDropboxDevice (NOT AVAILABLE ANYMORE)


# The SaveMailDevice

With this device a file (attachement) will be saved (sent) to an email address.
The following device config.

```
address:
  description: "Your email address"
  type: "string"
password:
  description: "The password for your email"
  type: "string"
server:
  description: "The mailserver smtp address"
  type: "string"
port:
  description: "The smtp port used, default 587"
  type: "number"
to:
  description: "The email address the mail is sent to. If empty the 'from' email is used (=address)"
  type: "string"
subject:
  description: "The optional subject for the save mail"
  type: "string"
text:
  description: "The optional text for the save mail"
  type: "boolean"
```


The presence dot goes present after first successful save and absent after an error in save.

---
The plugin is in development. You could backup Pimatic before you are using this plugin!
