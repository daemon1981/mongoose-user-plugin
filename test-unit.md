Cannot write runtime.json file Error: ENOENT, no such file or directory '/var/local/webroot/git-clones/mongoose-user-plugin/config/runtime.json'
# TOC
   - [User](#user)
     - [When signing up 'signup()'](#user-when-signing-up-signup)
     - [When validating an account 'accountValidator()'](#user-when-validating-an-account-accountvalidator)
     - [When checking user password is valid 'isValidUserPassword()'](#user-when-checking-user-password-is-valid-isvaliduserpassword)
       - [User not validated](#user-when-checking-user-password-is-valid-isvaliduserpassword-user-not-validated)
         - [Password is correct](#user-when-checking-user-password-is-valid-isvaliduserpassword-user-not-validated-password-is-correct)
       - [User validated](#user-when-checking-user-password-is-valid-isvaliduserpassword-user-validated)
         - [Password is correct](#user-when-checking-user-password-is-valid-isvaliduserpassword-user-validated-password-is-correct)
         - [Password is not correct](#user-when-checking-user-password-is-valid-isvaliduserpassword-user-validated-password-is-not-correct)
     - [When requesting for password reset 'requestResetPassword()'](#user-when-requesting-for-password-reset-requestresetpassword)
     - [When finding facebook user 'findOrCreateFaceBookUser()'](#user-when-finding-facebook-user-findorcreatefacebookuser)
       - [When user doesn't exists](#user-when-finding-facebook-user-findorcreatefacebookuser-when-user-doesnt-exists)
       - [When user exists](#user-when-finding-facebook-user-findorcreatefacebookuser-when-user-exists)
<a name=""></a>

<a name="user"></a>
# User
<a name="user-when-signing-up-signup"></a>
## When signing up 'signup()'
should create a user and set validated to false.

```js
var email;
email = 'toto@toto.com';
return User.signup(email, 'passwd', 'fr', function(err) {
  should.not.exist(err);
  return User.find({}, function(err, users) {
    users.length.should.equal(1);
    users[0].email.should.equal(email);
    should.exist(users[0].salt);
    should.exist(users[0].passwordHash);
    users[0].validated.should.equal(false);
    should.exist(users[0].validationKey);
    return done();
  });
});
```

should not be possible to create a user with the same email.

```js
var email;
email = 'toto@toto.com';
return User.signup(email, 'passwd', 'fr', function(err) {
  return User.signup(email, 'other-passwd', 'fr', function(err) {
    should.exist(err);
    return done();
  });
});
```

<a name="user-when-validating-an-account-accountvalidator"></a>
## When validating an account 'accountValidator()'
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

should fails if validationKey doesn't exist.

```js
return User.accountValidator('key-not-exists', function(err, user) {
  should.exist(err);
  return done();
});
```

<a name="user-when-checking-user-password-is-valid-isvaliduserpassword"></a>
## When checking user password is valid 'isValidUserPassword()'
<a name="user-when-checking-user-password-is-valid-isvaliduserpassword-user-not-validated"></a>
### User not validated
<a name="user-when-checking-user-password-is-valid-isvaliduserpassword-user-not-validated-password-is-correct"></a>
#### Password is correct
should not valid user password.

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

<a name="user-when-checking-user-password-is-valid-isvaliduserpassword-user-validated"></a>
### User validated
<a name="user-when-checking-user-password-is-valid-isvaliduserpassword-user-validated-password-is-correct"></a>
#### Password is correct
should valid user password.

```js
return User.isValidUserPassword(email, passwd, function(err, data, msg) {
  should.not.exist(err);
  should.not.exist(msg);
  assert.equal(user.email, data.email);
  return done();
});
```

<a name="user-when-checking-user-password-is-valid-isvaliduserpassword-user-validated-password-is-not-correct"></a>
#### Password is not correct
should not valid user password.

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

<a name="user-when-requesting-for-password-reset-requestresetpassword"></a>
## When requesting for password reset 'requestResetPassword()'
should set required fields for forgot password process.

```js
return user.requestResetPassword(function(err, modifedUser) {
  should.not.exist(err);
  should.exist(modifedUser.regeneratePasswordKey);
  should.exist(modifedUser.regeneratePasswordDate);
  return done();
});
```

<a name="user-when-finding-facebook-user-findorcreatefacebookuser"></a>
## When finding facebook user 'findOrCreateFaceBookUser()'
<a name="user-when-finding-facebook-user-findorcreatefacebookuser-when-user-doesnt-exists"></a>
### When user doesn't exists
should create facebook user.

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

<a name="user-when-finding-facebook-user-findorcreatefacebookuser-when-user-exists"></a>
### When user exists
should retrieve facebook user.

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
