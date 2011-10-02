mailer   = require "mailer"
path     = require "path"
mongoose = require "mongoose"
User     = mongoose.model "User"
Update   = mongoose.model "Update"
mail     = require "../lib/mail"

exports.signup = (req, res) ->
  res.render "users/new", locals:
    user: new User()
    title: "Sign Up"

exports.logout = (req, res) ->
  req.session.destroy ->
    res.redirect "/"

exports.showLogin = (req, res) ->
  res.redirect "/"  if req.session.user
  res.render "sessions/new", locals: title: "Login"

# Can be either username or email
authenticate = (namemail, pass, next) ->
  query = username: namemail
  if namemail.match /@/
    query = email: namemail
    console.log 'Logging in via email'
  User.findOne query, (err, user) ->
    return next(new Error("cannot find user"))  if err or not user
    return next(null, user)  if user.authenticate
    next new Error("invalid password")

exports.login = (req, res) ->
  authenticate req.body.user.namemail, req.body.user.password, (err, user) ->
    if user
      console.log "Found user"
      req.session.regenerate ->
        req.flash "info", "Logged in"
        console.log "Regenerated session"
        req.session.user = user
        res.redirect "/"
    else
      req.flash "error", "Could not find user"
      console.log "Couldn't find user"
      req.session.error = "Authentication failed, please check your " + " username and password." + " (use \"tj\" and \"foobar\")"
      res.redirect "back"

exports.create = (req, res) ->
  userSaveFailed = ->
    console.log "Save failed"
    req.flash "error", "Account creation failed"
    res.render "users/new", locals:
      title: 'Sign up'
      user: user

  if req.body.user.password != req.body.user.confirmPassword
    req.flash "error", "Passwords do not match"
    return userSaveFailed()

  user = new User(req.body.user)
  user.save (err) ->
    if err
      console.log err
      return userSaveFailed()
    console.log "Save complete"
    sendConfirmation user
    req.flash "info", "Your account has been created"
    switch req.params.format
      when "json"
        res.send user.toObject()
      else
        req.session.user_id = user.id
        res.redirect "/"

exports.top = (req, res, next) ->
  User.find().sort('score').limit(20).run (err, users) ->
    return next(new NotFound("Top users not found")) unless users
    res.render 'users/top', locals:
      title: 'Top Users'
      users: users

exports.show = (req, res, next) ->
  User.findOne( username: req.params.username ).run (err, user) ->
    return next(new NotFound("Entry not found")) unless user
    console.log user
    
    # TODO Produce # of edits per week?
    objid = mongoose.Types.ObjectId(user.id)
    rawid = user._id
    stringid = user.id
    #Update.find( 'user': user._id ).sort('date').limit(20).run (err, updates) ->
    # TODO Ideally want to make 1 request, then reorganise
    # TODO Work out percentages, make pie charts
    # TODO change this to that parallel async thing
    Update.count( user: objid, type: 'new' ).run (err, added) ->
      Update.count( user: objid, type: 'edit' ).run (err, edited) ->
        Update.count( user: objid, type: 'delete' ).run (err, deleted) ->
          Update.count( user: objid, 'status.type': 'approved' ).run (err, approved) ->
            Update.count( user: objid, 'status.type': 'rejected' ).run (err, rejected) ->
              Update.count( user: objid, 'status.type': 'pending' ).run (err, pending) ->
                Update.count( 'status.user': objid, 'status.type': 'approved' ).run (err, made_approved) ->
                  Update.count( 'status.user': objid, 'status.type': 'rejected' ).run (err, made_rejected) ->
                    Update.find( user: objid ).sort('created_at', 1).limit(20).run (err, updates) ->
                      #updates = [] unless updates # if we found none that's OK
                      console.log updates
                      res.render "users/show", locals:
                        title: user.display_name + ' (' + user.username + ')'
                        user:  user
                        updates: updates
                        counts:
                          added: added
                          edited: edited
                          deleted: deleted
                          status:
                            pending: pending
                            approved: approved
                            rejected: rejected
                          made:
                            approved: made_approved
                            rejected: made_rejected



exports.showResetEmail = (req, res, next) ->
  res.render 'sessions/reset', locals:
    title: 'Reset Password'
  
exports.sendResetEmail = (req, res, next) ->
  console.log req.body
  User.findOne email: req.body.email, (err, results) ->
    if err or !results
      req.flash "error", "No user with that email address"
      res.redirect '/login/reset'
      return


    # Not sure if this is random enough
    token = Math.round((new Date().valueOf() * Math.random())) + '';
    link = "http://kdict.org/login/reset/#{token}"

    User.update email: req.body.email,
              reset_code: token, (err, results) ->
      if err
        console.log err
        res.redirect "/"
      sendReset req.body.email, link
      res.render 'sessions/reset_sent', locals:
        title: 'Reset E-mail Sent'
        address: req.body.email
  

exports.showResetForm = (req, res, next) ->
  User.find reset_code: token, (err, results) ->
    if err
      console.log err
      res.redirect "/"
    res.render 'sessions/reset_password', locals:
      title: 'Reset Password'

# Actually reset the password
exports.resetPassword = (req, res, next) ->
  User.find reset_code: token, (err, results) ->
    if err
      console.log err
      res.redirect "/"
    if req.params.password != req.params.confirm
      req.flash "error", "Passwords do not match"
      res.render 'sessions/reset_password', locals:
        title: 'Reset Password'
      
    User.update reset_code: token,
              password: token, (err, results) ->

    #
    res.render 'sessions/reset_password', locals:
      title: 'Reset Password'



sendConfirmation = (user) ->
  mail.send_templated "confirm",
    to: user.email
    subject: "KDict - Please Confirm"
  , locals: user: user

sendReset = (email, link) ->
  mail.send_templated "reset",
    to: email
    subject: "KDict - Confirm Password Reset"
  , locals: email: email, link: link

