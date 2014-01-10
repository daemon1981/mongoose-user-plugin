mongoose = require 'mongoose'

Schema   = mongoose.Schema

UserPlugin = require '../../src/index'

UserSchema = new Schema()
UserSchema.plugin UserPlugin

User = mongoose.model "User", UserSchema

module.exports = User
