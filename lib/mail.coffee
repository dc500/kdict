nodemailer = require "nodemailer"
jade       = require "jade" # for email rendering
conf       = require "./mail.conf" # secret!

nodemailer.SMTP = conf.smtp()

# Email stuff
exports.send_templated = (template, mailOptions, templateOptions, callback) ->
  jade.renderFile path.join(__dirname, "../views", "mailer", template + '.jade'), templateOptions, (err, text) ->
    console.error err if err
    mailOptions.body = text
    send(mailOptions, callback)

exports.send = (mailOptions, callback) ->
  mailOptions.sender = "auto@kdict.org"
  console.log "[SENDING MAIL]"
  console.log mailOptions
  #if app.settings.env == "production"  # SCREW IT
  nodemailer.send_mail mailOptions, callback
  #(err, result) ->
  #  console.error err if err


  ###
  keys = Object.keys(app.set("mailOptions"))
  i = 0
  len = keys.length

  while i < len
    k = keys[i]
    mailOptions[k] = app.set("mailOptions")[k]  unless mailOptions.hasOwnProperty(k)
    i++
  ###
