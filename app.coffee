app         = require('express')()
bcrypt      = require 'bcrypt'
bodyParser  = require 'body-parser'
cloudant    = require('cloudant')
               account:    process.env.DB_USER
               password:   process.env.DB_PASS
email       = require('email').server.connect
               user:      process.env.SMTP_EMAIL
               password:  process.env.SMTP_PASS
               host:      process.env.SMTP_HOST
               SSL:       process.env.SMTP_SSL || true
moment      = require 'moment'
session     = require 'express-session'
validator   = require 'validator'


jsonParser = bodyParser.json()


app.use session secret: process.env.SECRET, secure: true


register = (req, res) ->
   if not (req.body.email and validator.isEmail req.body.email)
      return res.json error: 'bad_email'
   else if not (req.body.name and req.body.name.length >= 2 and req.body.name.split(' ').every (v) -> validator.isAlpha v)
      return res.json error: 'bad_name'
   else if not (req.body.mod and typeof req.body.mod is 'boolean')
      return res.json error: 'bad_mod_bool'
   else
      accounts = cloudant.use process.env.DB_ACCOUNTS
      accounts.insert
         name: req.body.name
         mod: req.body.mod
         trusted: null
      ,  req.body.email

      , (e, body) ->
         if e
            console.error 'db_error', e
            return res.json error: 'db_error', data: e
         else
            next()


getKey = (req, res) ->
   if not (req.body.email and validator.isEmail req.body.email)
      return res.json error: 'bad_email'
   else
      accounts = cloudant.use process.env.DB_ACCOUNTS
      accounts.get req.body.email, (e, body) ->
         if e and e.error is 'not_found'
            return res.json error: 'unregistered'
         else if e
            console.error 'db_error', e
            return res.json error: 'db_error', data: e
         else
            valid = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
            key = ''
            key += valid[Math.floor Math.random() * (valid.length - 1)] for [0...6]

            bcrypt.hash key, 10, (e, hash) ->
               if e
                  console.error 'crypt_error', e
                  return res.json error: 'crypt_error', data: e
               else
                  accounts.insert
                     name: body.name
                     mod: body.mod
                     trusted: body.trusted
                     hash: hash
                     expires: moment().add 1, 'days'
                     _rev: body.rev
                  ,  req.body.email
                  , (e, body) ->
                     if e
                        console.error 'db_error', e
                        return res.json error: 'db_error', data: e
                     else
                        email.send
                           text:       "Welcome back, #{body.name}\n\n
                                        Your key is #{key}, and is valid until #{body.expires.format 'dddd Do MMMM'}.\n
                                        You can enter the system directly here: https://#{req.hostname}/auth?i=#{encodeURIComponent req.session.email}&key=#{key}\n\n
                                        Kind regards,\n
                                        Cpl Daly, Developer, nco"
                           from:       "nco <#{process.env.SMTP_EMAIL}"
                           to:         "#{body.name} <#{req.session.email}>"
                           subject:    "Your nco key"
                           attachment:
                              data:          app.render 'email'
                              alternative:   true

                        , (e, message) ->
                           if e
                              console.error 'send_error', e
                              return res.json error: 'send_error', data: e
                           else
                              return res.json done: 'key_sent'


auth = (req, res) ->
   if not (req.body.email and validator.isEmail req.body.email)
      return res.json error: 'bad_email'
   else if not (req.body.key and validator.isAlphanumeric req.body.key)
      return res.json error: 'bad_key'
   else
      accounts = cloudant.use process.env.DB_ACCOUNTS
      accounts.get req.body.email, (e, body) ->
         if e and e.error is 'not_found'
            return res.json error: 'unregistered'
         else if e
            console.error 'db_error', e
            return res.json error: 'db_error', data: e
         else
            bcrypt.compare req.body.key, body.hash, (e, match) ->
               if match
                  req.session.email = body.email
                  req.session.name = body.name
                  req.session.mod = body.mod
                  req.session.trusted = body.trusted
                  return res.json done: 'key_accepted'


app.post '/api/getkey', jsonParser, getKey

app.post '/api/register', jsonParser, register, getKey

app.post '/api/auth', jsonParser, auth

app.post '/api/entrust', jsonParser, (req, res) ->
   if not (req.session.email)
      return res.json error: 'logged_out'
   else if not (req.body.email and validator.isEmail req.body.email)
      return res.json error: 'bad_email'
   else
      accounts = cloudant.use process.env.DB_ACCOUNTS
      accounts.get req.body.email, (e, body) ->
         if e and e.error is 'not_found'
            return res.json error: 'unregistered'
         else if e
            console.error 'db_error', e
            return res.json error: 'db_error', data: e
         else
            accounts.insert
               name: body.name
               mod: body.mod
               trusted: req.session.email
               hash: body.hash
               expires: body.expires
               _rev: body.rev
            ,  req.body.email
            , (e, body) ->
               if e
                  console.error 'db_error', e
                  return res.json error: 'db_error', data: e
               else
                  return res.json done: 'entrusted_account'

app.get '/api/truststatus', jsonParser, (req, res) ->
   if not (req.session.email)
      return res.json error: 'logged_out'
   else
      accounts = cloudant.use process.env.DB_ACCOUNTS
      accounts.get req.session.email, (e, body) ->
         if e
            console.error 'db_error', e
            return res.json error: 'db_error', data: e
         else
            return res.json done: body.trusted


app.get '/auth'
, (req, res, next) ->
   req.body.email = decodeURIComponent req.query.i
   req.body.key = req.query.key
   next()
,  auth


app.use '/static', express.static 'public'

app.get '/*', (req, res) ->
   if req.session.expiry
      if req.session.expiry > new Date()
         if req.session.trusted
            return res.render 'skeleton.ejs', title: 'App', script: 'static/js/app.js'
         else
            return res.render 'skeleton.ejs', title: 'Locked', script: 'static/js/locked.js'
      else
         return res.render 'skeleton.ejs', title: 'Login', script: 'static/js/login.js', config: email: req.session.email
   else
      return res.render 'skeleton.ejs', title: 'Login', script: 'static/js/login.js'


app.listen process.env.PORT || 3000