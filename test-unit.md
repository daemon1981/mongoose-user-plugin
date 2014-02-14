# TOC
   - [UserPlugin](#userplugin)
     - [document.signup(email, password, language, callback)](#userplugin-documentsignupemail-password-language-callback)
     - [document.accountValidator(validationKey, callback)](#userplugin-documentaccountvalidatorvalidationkey-callback)
     - [document.isValidUserPassword(email, password, callback)](#userplugin-documentisvaliduserpasswordemail-password-callback)
       - [when user account is not validated](#userplugin-documentisvaliduserpasswordemail-password-callback-when-user-account-is-not-validated)
       - [when user account is validated](#userplugin-documentisvaliduserpasswordemail-password-callback-when-user-account-is-validated)
     - [document.requestResetPassword(callback)](#userplugin-documentrequestresetpasswordcallback)
     - [document.findOrCreateFaceBookUser(profile, done)](#userplugin-documentfindorcreatefacebookuserprofile-done)
<a name=""></a>

<a name="userplugin"></a>
# UserPlugin
<a name="userplugin-documentsignupemail-password-language-callback"></a>
## document.signup(email, password, language, callback)
create a user and set validated to false.

```js
return checkSignupWorks(User, email, done);
```

fails and set validated to false when email not matching.

```js
return checkSignupFails(UserOtherEmailMatch, 'titi@toto.com', done);
```

fails with the same email.

```js
return checkSignupWorks(User, email, function(err) {
  should.not.exist(err);
  return checkSignupFails(User, email, done);
});
```

<a name="userplugin-documentaccountvalidatorvalidationkey-callback"></a>
## document.accountValidator(validationKey, callback)
should valid account.

```js
var email, userTest;
email = 'toto@toto.com';
userTest = {};
return async.series([
  function(callback) {
    return User.signup(email, 'passwd', 'fr', function(err, user) {
      userTest = user;
      return callback();
    });
  }, function(callback) {
    return User.accountValidator(userTest.validationKey, callback);
  }, function(callback) {
    return User.findOne({
      email: email
    }, function(err, user) {
      user.validated.should.equal(true);
      should.not.exist(user.validationKey);
      return done();
    });
  }
], done);
```

fails if validationKey doesn't exist.

```js
return User.accountValidator('key-not-exists', function(err, user) {
  should.exist(err);
  return done();
});
```

<a name="userplugin-documentisvaliduserpasswordemail-password-callback"></a>
## document.isValidUserPassword(email, password, callback)
<a name="userplugin-documentisvaliduserpasswordemail-password-callback-when-user-account-is-not-validated"></a>
### when user account is not validated
not validating user password even if password is correct.

```js
return User.isValidUserPassword(email, passwd, function(err, data, msg) {
  should.not.exist(err);
  should.exist(msg);
  assert.equal(false, data);
  assert.deepEqual(msg, {
    message: 'Account not validated.'
  });
  return done();
});
```

<a name="userplugin-documentisvaliduserpasswordemail-password-callback-when-user-account-is-validated"></a>
### when user account is validated
validating user password if password is correct.

```js
return User.isValidUserPassword(email, passwd, function(err, data, msg) {
  should.not.exist(err);
  should.not.exist(msg);
  assert.equal(user.email, data.email);
  return done();
});
```

not validating user password if password is not correct.

```js
return User.isValidUserPassword(email, 'badpasswd', function(err, data, msg) {
  should.not.exist(err);
  should.exist(msg);
  assert.equal(false, data);
  assert.deepEqual(msg, {
    message: 'Incorrect password.'
  });
  return done();
});
```

<a name="userplugin-documentrequestresetpasswordcallback"></a>
## document.requestResetPassword(callback)
set required fields for forgot password process.

```js
return user.requestResetPassword(function(err, modifedUser) {
  should.not.exist(err);
  should.exist(modifedUser.regeneratePasswordKey);
  should.exist(modifedUser.regeneratePasswordDate);
  return done();
});
```

<a name="userplugin-documentfindorcreatefacebookuserprofile-done"></a>
## document.findOrCreateFaceBookUser(profile, done)
create facebook user when user doesn't exists.

```js
return User.findOrCreateFaceBookUser(profile, function(err, user) {
  should.not.exist(err);
  return User.find({}, function(err, users) {
    users.length.should.equal(1);
    users[0].email.should.equal(email);
    users[0].validated.should.equal(true);
    return done();
  });
});
```

retrieve facebook user when user exists.

```js
return User.findOrCreateFaceBookUser(profile, function(err, user) {
  var userId;
  should.not.exist(err);
  userId = user._id;
  return User.findOrCreateFaceBookUser(profile, function(err, user) {
    should.not.exist(err);
    assert.deepEqual(userId, user._id);
    return User.find({}, function(err, users) {
      users.length.should.equal(1);
      users[0].email.should.equal(email);
      return done();
    });
  });
});
```
