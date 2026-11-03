const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const Module = require('node:module');
require('coffee-script/register');
const nodemailer = require('nodemailer');

test('updated dependencies preserve plugin registration, mail attachments and FTP paths', async () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'pimatic-save-test-'));
  const content = Buffer.from('backup fixture: café\n');
  fs.writeFileSync(path.join(root, 'backup.txt'), content);
  const classes = {};
  const uploads = [];
  let transportOptions;
  let mailDone;
  let mail;
  const rendered = new Promise((resolve, reject) => { mailDone = { resolve, reject }; });
  const stream = nodemailer.createTransport({streamTransport: true, buffer: true});
  class Ftp {
    connect(options) { this.options = options; return Promise.resolve(); }
    put(bytes, target) { uploads.push({bytes, target, options: this.options}); return Promise.resolve(); }
    destroy() {}
  }
  const realLoad = Module._load;
  Module._load = function (id, parent, main) {
    if (id === 'promise-ftp') return Ftp;
    if (id === 'nodemailer') return { createTransport(options) {
      transportOptions = options;
      return {
        verify(callback) { callback(null, true); },
        sendMail(options, callback) {
          mail = options;
          stream.sendMail(options, (error, info) => {
            callback(error, info);
            if (error) mailDone.reject(error); else mailDone.resolve(info);
          });
        }
      };
    }};
    return realLoad.call(this, id, parent, main);
  };
  try {
    const framework = {
      maindir: path.join(root, 'node_modules', 'pimatic'),
      config: {devices: []},
      deviceManager: {registerDeviceClass(name, definition) { classes[name] = definition; }},
      ruleManager: {addActionProvider(provider) { this.provider = provider; }}
    };
    function PresenceSensor() {}
    PresenceSensor.prototype._setPresence = function(value) { this.presence = value; };
    const env = {
      require, plugins: {Plugin: function() {}}, devices: {PresenceSensor},
      actions: {ActionProvider: function() {}, ActionHandler: function() {}},
      matcher() {}, logger: {debug() {}, info() {}, error() {}}
    };
    const plugin = require('../save.coffee')(env);
    plugin.init(null, framework, {});
    assert.deepEqual(Object.keys(classes).sort(), ['SaveFtpDevice', 'SaveMailDevice']);
    assert.ok(framework.ruleManager.provider);
    const config = {id: 'mail', name: 'Mail', address: 'sender@example.test',
      password: 'test-only', server: 'smtp.example.test', subject: 'Backup'};
    framework.config.devices.push(config);
    const device = classes.SaveMailDevice.createCallback(config, {});
    await device.upload('backup.txt', true, 'backup.txt', 'mail');
    const result = await rendered;
    assert.equal(transportOptions.port, 587);
    assert.equal(transportOptions.auth.user, config.address);
    assert.equal(mail.to, config.address);
    assert.deepEqual(mail.attachments[0].content, content);
    assert.match(mail.attachments[0].filename, /^\d{4}-\d{2}-\d{2} .* backup\.txt$/);
    assert.match(result.message.toString(), /Content-Type: multipart\/mixed/);
    assert.ok(result.message.toString().includes(content.toString('base64')));
    const ftpConfig = {id: 'ftp', name: 'FTP', host: 'ftp.example.test',
      username: 'fixture', password: 'test-only', path: '/backups'};
    framework.config.devices.push(ftpConfig);
    const ftp = classes.SaveFtpDevice.createCallback(ftpConfig, {});
    await ftp.upload('backup.txt', false, 'backup.txt', 'ftp');
    assert.equal(uploads[0].target, '/backups/backup.txt');
    assert.equal(uploads[0].options.port, 21);
    assert.deepEqual(uploads[0].bytes, content);
    ftpConfig.path = '/backups/';
    await ftp.upload('backup.txt', true, 'backup.txt', 'ftp');
    assert.match(uploads[1].target, /^\/backups\/\d{4}-\d{2}-\d{2}_\d{6}_backup\.txt$/);
  } finally {
    Module._load = realLoad;
    fs.rmSync(root, {recursive: true, force: true});
  }
});
