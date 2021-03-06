"use strict"

mongoose = require "mongoose"
Schema = mongoose.Schema
crypto = require "crypto"

UserSchema = new Schema
	name: String
	email:
		type: String
		lowercase: true
	hashedPassword: String
	role:
		type: String
		default: "user"
	salt: String

# Virtuals

UserSchema
	.virtual "password"
	.set (password) ->
		this._password = password
		this.salt = this.makeSalt()
		this.hashedPassword = this.encryptPassword password
	.get ->
		this._password

# Public profile information
UserSchema
	.virtual "profile"
	.get ->
		"id": this._id
		"name": this.name
		"role": this.role
		"email": this.email

# Non-sensitive info we"ll be putting in the token
UserSchema
	.virtual "token"
	.get ->
		"_id": this._id
		"role": this.role

# Validations

# Validate empty email
UserSchema
	.path "email"
	.validate (email) ->
		# if you are authenticating by any of the oauth strategies, don"t validate
		email.length
	, "Email cannot be blank"

# Validate empty password
UserSchema
	.path "hashedPassword"
	.validate (hashedPassword) ->
		hashedPassword.length
	, "Password cannot be blank"

# Validate email is not taken
UserSchema
	.path "email"
	.validate (value, respond) ->
		self = this
		this.constructor.findOne
			email: value
			, (err, user) ->
				if err then throw err
				if user
					if self.id is user.id then return respond true
					return respond false
				respond true
, "The specified email address is already in use."

validatePresenceOf = (value) ->
	value and value.length

# Pre-save hook

UserSchema
	.pre "save", (next) ->
		if !this.isNew then return next()

		if !validatePresenceOf this.hashedPassword
			next new Error "Invalid password"
		else
			next()

# Methods

UserSchema.methods =
	
	# Authenticate - check if the passwords are the same
	
	# @param {String} plainText
	# @return {Boolean}
	# @api public
	
	authenticate: (plainText) ->
		this.encryptPassword(plainText) == this.hashedPassword
	,

	
	# Make salt
	
	# @return {String}
	# @api public
	
	makeSalt: ->
		crypto.randomBytes(16).toString "base64"
	,

	
	# Encrypt password
	
	# @param {String} password
	# @return {String}
	# @api public
	
	encryptPassword: (password) ->
		if !password || !this.salt then return ""
		salt = new Buffer this.salt, "base64"
		crypto.pbkdf2Sync(password, salt, 10000, 64).toString "base64"

module.exports = mongoose.model "User", UserSchema