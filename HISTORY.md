# Release History

* 20200118, v0.1.0
	* initial release
* 20200118, v0.1.1
	* update package
* 20200118, v0.1.2
	* added info on saving file
* 20200118, v0.1.3
	* optional automatic date directory structure /yyyy/mm/dd/
	* replaced event based by promise based ftp client
	* update presence dot
* 20200119, v0.1.5
	* more compatible file format in dropbox and Ftp
* 20200119, v0.1.6
	* more readable timestamp (identical to pimatic-backup)
	* complete path+filename in missing file error in rule editor
* 20200120, v0.1.7
	* improved error handling on file existance
* 20200121, v0.1.8
	* consequent destroy client after upload
* 20200121, v0.1.9
	* to allow multiple upload rules at same time, FTP and Dropbox connections are now multi instance, and disconnected  after upload
* 20200329, v0.1.12
	* edit path / file structure for dropbox save
* 20200913, v0.1.14
	* fix node-fetch vulnerability
* 20200920, v0.1.19
	* added mail save
* 20200921, v0.1.20
	* added $variable in filename string
* 20200922, v0.1.24
	* edit pimatic-app dir as root
* 20220120, v0.2.0
	* removal of DropboxSave due to new auth api
