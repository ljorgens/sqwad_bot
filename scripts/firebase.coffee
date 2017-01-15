async = require('async')
AWS = require('aws-sdk')
Firebase = require('firebase')
FirebaseTokenGenerator = require('firebase-token-generator')
moment = require('moment')

authenticateStormFirebase = (cb) ->
  rootRef = new Firebase('https://stormdbversion2.firebaseio.com')
  tokenGenerator = new FirebaseTokenGenerator('x94fOsJfrQ0LCr8XUAgfWHSx80vjjcYeYGCLjMqV')
  token = tokenGenerator.createToken(
    uid: '57fcc978-6ca9-49ac-a4cb-860ad625dd56'
    name: 'sqwad-droid')
    
  rootRef.authWithCustomToken token, (error, authData) ->
    if error
      cb error
    else
      cb null, rootRef
    return
  return

authenticateFirebase = (cb) ->
  rootRef = new Firebase('https://whawksv2.firebaseio.com/')
  tokenGenerator = new FirebaseTokenGenerator('K9tFR6FnYlO39oWl3tYKnWd90LuMrYD66vW7o1gk')
  token = tokenGenerator.createToken(
    uid: '57fcc978-6ca9-49ac-a4cb-860ad625dd56'
    name: 'sqwad-droid')

  rootRef.authWithCustomToken token, (error, authData) ->
    if error
      cb error
    else
      cb null, rootRef
    return
  return
  
  
authenticateCheckersFirebase = (cb) ->
  rootRef = new Firebase('https://checkersdbtest.firebaseio.com/')
  tokenGenerator = new FirebaseTokenGenerator('4QWMk6pn3FfsVvbckCoXtTDhVVzCc0JdbHtdwzDk')
  token = tokenGenerator.createToken(
    uid: '57fcc978-6ca9-49ac-a4cb-860ad625dd56'
    name: 'sqwad-droid')

  rootRef.authWithCustomToken token, (error, authData) ->
    if error
      cb error
    else
      cb null, rootRef
    return
  return

exportFirebaseData = (rootRef, cb) ->
  rootRef.once 'value', ((snap) ->
    rootRef = rootRef
    # make data multiple things so can later use as reference to whichever DB I am saving
    data = [snap.exportVal(), rootRef]
    cb null, data
    return
  ), (error) ->
    cb error
    return
  return

uploadtoS3 = (data, cb) ->
  name = data[1].root().toString()
  data = data[0]
  date = new Date
  today = moment(date).format('YYYY-MM-DD')
  payload = JSON.stringify(data)
  AWS.config.region = 'us-west-2'
  s3 = new (AWS.S3)
  #check to see if it is the Storm db or not
  if name is 'https://stormdbversion2.firebaseio.com'
    s3.createBucket { Bucket: 'storm-firebase-backups' }, ->
      params =
        Bucket: 'storm-firebase-backups'
        Key: today
        Body: payload
      s3.upload params, (err, data) ->
        bytes = Buffer.byteLength(payload, 'utf8')
        cb err, bytes
        return
      return
    return
  else if name is 'https://checkersdbtest.firebaseio.com'
    s3.createBucket { Bucket: 'checkers-firebase-backups' }, ->
      params =
        Bucket: 'checkers-firebase-backups'
        Key: today
        Body: payload
      s3.upload params, (err, data) ->
        bytes = Buffer.byteLength(payload, 'utf8')
        cb err, bytes
        return
      return
    return
  else
    s3.createBucket { Bucket: 'pick6-firebase-backups' }, ->
      params =
        Bucket: 'pick6-firebase-backups'
        Key: today
        Body: payload
      s3.upload params, (err, data) ->
        bytes = Buffer.byteLength(payload, 'utf8')
        cb err, bytes
        return
      return
    return

module.exports = 
  backup: (cb) ->
    async.waterfall [
      authenticateFirebase
      exportFirebaseData
      uploadtoS3
    ], (err, result) ->
      if err
        cb(err)
      else
        cb(null, result)
  backupStorm: (cb) ->
    async.waterfall [
      authenticateStormFirebase
      exportFirebaseData
      uploadtoS3
    ], (err, result) ->
      if err
        cb(err)
      else
        cb(null, result)
  backupCheckers: (cb) ->
    async.waterfall [
      authenticateCheckersFirebase
      exportFirebaseData
      uploadtoS3
    ], (err, result) ->
      if err
        cb(err)
      else
        cb(null, result)
  size: (cb) ->
    authenticateFirebase (err, rootRef) ->
      if err
        cb(err)
      rootRef.once 'value', (snap) ->
        data = JSON.stringify(snap.val());
        bytes = Buffer.byteLength(data, 'utf8')
        cb(null, bytes)
      