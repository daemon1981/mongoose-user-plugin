require './bootstrap.coffee'

assert       = require 'assert'
should       = require 'should'
async        = require 'async'
mongoose     = require 'mongoose'
fixtures     = require 'pow-mongoose-fixtures'

User         = require "./models/user"

describe "User", ->
  beforeEach (done) ->
    fixtures.load {User: []}, mongoose.connection, done

  describe "When signing up 'signup()'", ->
    it "should create a user and set validated to false", (done) ->
      email = 'toto@toto.com'
      User.signup email, 'passwd', 'fr', (err) ->
        should.not.exist(err)
        User.find {}, (err, users) ->
          users.length.should.equal(1)
          users[0].email.should.equal(email)
          should.exist(users[0].salt)
          should.exist(users[0].passwordHash)
          users[0].validated.should.equal(false)
          should.exist(users[0].validationKey)
          done()
    it "should not be possible to create a user with the same email", (done) ->
      email = 'toto@toto.com'
      User.signup email, 'passwd', 'fr', (err) ->
        User.signup email, 'other-passwd', 'fr', (err) ->
          should.exist(err)
          done()

  describe "When validating an account 'accountValidator()'", ->
    it "should valid account", (done) ->
      email = 'toto@toto.com'
      userTest  = {}
      async.series [(callback) ->
        User.signup email, 'passwd', 'fr', (err, user) ->
          userTest = user
          callback()
      , (callback) ->
        User.accountValidator userTest.validationKey, callback
      , (callback) ->
        User.findOne {email: email}, (err, user) ->
          user.validated.should.equal(true)
          should.not.exist(user.validationKey)
          done()
      ], done
    it "should fails if validationKey doesn't exist", (done) ->
      User.accountValidator 'key-not-exists', (err, user) ->
        should.exist(err)
        done()

  describe "When checking user password is valid 'isValidUserPassword()'", ->
    passwd = 'passwd'
    email = 'toto@toto.com'
    user = {}
    beforeEach (done) ->
      User.signup email, passwd, 'fr', (err, newUser) ->
        user = newUser
        done()
    describe "User not validated", ->
      describe "Password is correct", ->
        it "should not valid user password", (done) ->
          User.isValidUserPassword email, passwd, (err, data, msg) ->
            should.not.exist(err)
            should.exist(msg)
            assert.equal false, data
            assert.deepEqual msg, message: 'Account not validated.'
            done()
    describe "User validated", ->
      beforeEach (done) ->
        user.validated = true
        user.save done
      describe "Password is correct", ->
        it "should valid user password", (done) ->
          User.isValidUserPassword email, passwd, (err, data, msg) ->
            should.not.exist(err)
            should.not.exist(msg)
            assert.equal user.email, data.email
            done()
      describe "Password is not correct", ->
        it "should not valid user password", (done) ->
          User.isValidUserPassword email, 'badpasswd', (err, data, msg) ->
            should.not.exist(err)
            should.exist(msg)
            assert.equal false, data
            assert.deepEqual msg, message: 'Incorrect password.'
            done()

  describe "When requesting for password reset 'requestResetPassword()'", ->
    passwd = 'passwd'
    email = 'toto@toto.com'
    user = {}
    beforeEach (done) ->
      User.signup email, passwd, 'fr', (err, newUser) ->
        user = newUser
        done()
    it "should set required fields for forgot password process", (done) ->
      user.requestResetPassword (err, modifedUser) ->
        should.not.exist(err)
        should.exist(modifedUser.regeneratePasswordKey)
        should.exist(modifedUser.regeneratePasswordDate)
        done()

  describe "When finding facebook user 'findOrCreateFaceBookUser()'", ->
    email = 'toto@toto.com'
    profile =
      id: '4ds5fd6'
      emails: [value: email]
      displayName: 'Toto Dupond'
      language: 'fr'
    describe "When user doesn't exists", (done) ->
      it "should create facebook user", (done) ->
        User.findOrCreateFaceBookUser profile, (err, user) ->
          should.not.exist(err)
          User.find {}, (err, users) ->
            users.length.should.equal(1)
            users[0].email.should.equal(email)
            users[0].validated.should.equal(true)
            done()
    describe "When user exists", (done) ->
      it "should retrieve facebook user", (done) ->
        User.findOrCreateFaceBookUser profile, (err, user) ->
          should.not.exist(err)
          userId = user._id
          User.findOrCreateFaceBookUser profile, (err, user) ->
            should.not.exist(err)
            assert.deepEqual userId, user._id
            User.find {}, (err, users) ->
              users.length.should.equal(1)
              users[0].email.should.equal(email)
              done()
