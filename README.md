# pimatic-save
Plugin for saving files to backup media

With this plugin you can save files from the system Pimatic is running to a backup medium. The supported media are FTP and Dropbox.

The save of a file is done via an action rule. The medium independent action syntax is
```
save "[localpath/]filename" [with timestamp] to <SaveFtpDive | SaveDropboxDevice>
```

The optional 'with timestamp' adds a timestamp in front of the filename.
The timestamp format is "yyyymmdd-hhmmss_".
The filename can hold a local path and should the local operating system conventions (linux, windows). When adding an action the existance of the file is checked. The file needs to exist for the rule to be saved.
The base of the filename is the home directory of pimatic. For rpi thats mostly the /home/pi/pimatic-app directory. You could use directory navigation like "../.." in the filename to select files outside the base directory.

To make a daily backup during the night at 1:00 your config.json the rule is
When
  its 1:00
Then
  save "config.json" with timestamp to <your FtpOrDropbox Device>

# The SaveFtpDevice

With this device files will be daved to a Ftp server.
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
  required: false
```

The path is the path from the login root that is specific for your ftp account. The path needs to exist on the ftp server!

# The SaveDropDevice

With this device files will be saved to Dropbox.
The following device config.

```
accessToken:
  description: "AccessToken generated for your pimatic-save upload folder"
  type: "string"
path:
  description: "Remote path of the backup server where the config should be saved"
  type: "string"
  required: false
```

How to get the Dropbox accessToken?
In your Dropbox account you go to "https://www.dropbox.com/developers/" and open the app console. Your create an app, and select the Dropbx Api and select "App folder– Access to a single folder created specifically for your app." You could choose assess to all files, and give it a name (not relevant for plugin).
In the dropbox app configuration page under "OAuth 2" you generate an access token. This token should be copied and put into the accessToken field of the device config
