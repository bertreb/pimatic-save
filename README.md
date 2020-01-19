# pimatic-save
Plugin for saving files to backup media

With this plugin you can save files from the system Pimatic is running to a backup medium. The supported media in this first release are FTP and Dropbox.

The save of a file is done via an action rule. The medium independent action syntax is
```
save "[localpath/]filename" [with timestamp] to SaveFtpDevice | SaveDropboxDevice
```

The optional 'with timestamp' adds a timestamp in front of the filename.
The timestamp format is "yyyy-mm-dd_hhmmss". With hours in 24-hour format.
The filename can hold a local path and should the local operating system conventions (linux, windows). When adding an action the existance of the file is checked. The file needs to exist for the rule to be saved.
The base of the filename is the home directory of Pimatic. For rpi thats mostly the /home/pi/pimatic-app directory. You could use directory navigation like "../.." in the filename to select files outside the base directory.

To make a daily backup during the night at 1:00 your config.json the rule is

```
when 'its 1:00' then 'save "config.json" with timestamp to <your FtpOrDropbox Device>'
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

# The SaveDropboxDevice

With this device files will be saved to Dropbox.
The following device config.

```
accessToken:
  description: "AccessToken generated for your pimatic-save upload folder"
  type: "string"
path:
  description: "Remote path of the backup server where the config should be saved"
  type: "string"
dateStructure:
  description: "Automatic creation of /year/month/day/ directories for datebased timestamping. Structure is created after path"
  type: "boolean"
overwrite:
  description: "If enabled and a file already exists on Dropbox the new version will overwrite the old one.
    If disabled the file will get a (version nr) added in the filename"
  type: "boolean"
```

The path doesn't have to exist in Dropbox. Its automatically created when the file is saved. The root of the path is the directory you selected when you created the Dropbox app. When dateStructure is enabled, behind the path a date based directory structure /year/month/day/ is created and the file is saved to /path/year/month/day/file.

### How to get the Dropbox accessToken?

In your Dropbox account you go to "https://www.dropbox.com/developers/" and open the app console. Create an app, select the Dropbox Api and select "App folder– Access to a single folder created specifically for your app." You could choose assess to all files, and give it a name (not relevant for plugin).
In the dropbox app configuration page under "OAuth 2" you generate an access token. This token should be copied and put into the accessToken field of the device config

The presence dot goes present after first successful save and absent after an error in save.


The plugin is in development. You could backup Pimatic before you are using this plugin!
