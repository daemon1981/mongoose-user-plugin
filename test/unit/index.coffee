require '../bootstrap.coffee'

assert       = require 'assert'
should       = require 'should'
async        = require 'async'
mongoose     = require 'mongoose'

UserPlugin = require '../../src/index'
User = mongoose.model "User", (new mongoose.Schema()).plugin UserPlugin, languages: ['en', 'fr']

UserOtherEmailMatchSchema = new mongoose.Schema()
UserOtherEmailMatchSchema.plugin UserPlugin, languages: ['en', 'fr']
UserOtherEmailMatchSchema.add
  email:       type: String, required: true, unique: true, match: /@domain.com/
UserOtherEmailMatch = mongoose.model "UserOtherEmailMatch", UserOtherEmailMatchSchema


describe "UserPlugin", ->
  beforeEach (done) ->
    async.series([(next) ->
        User.remove(next)
      , (next) ->
        UserOtherEmailMatch.remove(next)
    ], done);

  describe "document.signup(email, password, language, callback)", ->
    email = 'toto@toto.com'
    checkSignupWorks = (Model, email, done) ->
      Model.signup email, 'passwd', 'fr', (err) ->
        should.not.exist(err)
        Model.find {}, (err, users) ->
          users.length.should.equal(1)
          users[0].email.should.equal(email)
          should.exist(users[0].salt)
          should.exist(users[0].passwordHash)
          users[0].validated.should.equal(false)
          should.exist(users[0].validationKey)
          done()
    checkSignupFails = (Model, email, done) ->
      Model.signup email, 'passwd', 'fr', (err) ->
        should.exist(err)
        done()

    it "create a user and set validated to false", (done) ->
      checkSignupWorks(User, email, done)

    it "fails and set validated to false when email not matching", (done) ->
      checkSignupFails(UserOtherEmailMatch, 'titi@toto.com', done)

    it "fails with the same email", (done) ->
      checkSignupWorks User, email, (err) ->
        should.not.exist(err)
        checkSignupFails(User, email, done)

  describe "document.accountValidator(validationKey, callback)", ->
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
    it "fails if validationKey doesn't exist", (done) ->
      User.accountValidator 'key-not-exists', (err, user) ->
        should.exist(err)
        done()

  describe "document.isValidUserPassword(email, password, callback)", ->
    passwd = 'passwd'
    email = 'toto@toto.com'
    user = {}
    beforeEach (done) ->
      User.signup email, passwd, 'fr', (err, newUser) ->
        user = newUser
        done()
    describe "when user account is not validated", ->
      it "not validating user password even if password is correct", (done) ->
        User.isValidUserPassword email, passwd, (err, data, msg) ->
          should.not.exist(err)
          should.exist(msg)
          assert.equal false, data
          assert.deepEqual msg, message: 'Account not validated.'
          done()
    describe "when user account is validated", ->
      beforeEach (done) ->
        user.validated = true
        user.save done
      it "validating user password if password is correct", (done) ->
        User.isValidUserPassword email, passwd, (err, data, msg) ->
          should.not.exist(err)
          should.not.exist(msg)
          assert.equal user.email, data.email
          done()
      it "not validating user password if password is not correct", (done) ->
        User.isValidUserPassword email, 'badpasswd', (err, data, msg) ->
          should.not.exist(err)
          should.exist(msg)
          assert.equal false, data
          assert.deepEqual msg, message: 'Incorrect password.'
          done()

  describe "document.requestResetPassword(callback)", ->
    passwd = 'passwd'
    email = 'toto@toto.com'
    user = {}
    beforeEach (done) ->
      User.signup email, passwd, 'fr', (err, newUser) ->
        user = newUser
        done()
    it "set required fields for forgot password process", (done) ->
      user.requestResetPassword (err, modifedUser) ->
        should.not.exist(err)
        should.exist(modifedUser.regeneratePasswordKey)
        should.exist(modifedUser.regeneratePasswordDate)
        done()

  describe "document.findOrCreateFaceBookUser(profile, done)", ->
    email = 'toto@toto.com'
    profile =
      id: '4ds5fd6'
      emails: [value: email]
      displayName: 'Toto Dupond'
      language: 'fr'
    it "create facebook user when user doesn't exists", (done) ->
      User.findOrCreateFaceBookUser profile, (err, user) ->
        should.not.exist(err)
        User.find {}, (err, users) ->
          users.length.should.equal(1)
          users[0].email.should.equal(email)
          users[0].validated.should.equal(true)
          done()
    it "retrieve facebook user when user exists", (done) ->
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
