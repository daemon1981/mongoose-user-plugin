# mongoose-user-plugin [![Build Status](https://secure.travis-ci.org/daemon1981/mongoose-user-plugin.png)](https://travis-ci.org/daemon1981/mongoose-user-plugin)

## Description

Add common user fonctionnality to document

## Installation

```
$ npm install mongoose-user-plugin
```

## Overview

### Add plugin to a schema

```
var mongoose           = require('mongoose');
var MongooseUserPlugin = require('mongoose-user-plugin');

var UserSchema = new mongoose.Schema();

UserSchema.plugin(MongooseUserPlugin);

UserSchema.add({
  'myPersonalField': String
});

var User = mongoose.model("User", UserSchema);

module.exports = User;
```

### Specifications

Please see the [specifications here](https://github.com/daemon1981/mongoose-user-plugin/blob/master/test-unit.md)

### Projects using mongoose-user-plugin

 - [Workbook](https://github.com/eleven-labs/Workbook)
