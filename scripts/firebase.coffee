async = require('async')
AWS = require('aws-sdk')
Firebase = require('firebase')
FirebaseTokenGenerator = require('firebase-token-generator')
moment = require('moment')

authenticateStormFirebase = (cb) ->
  rootRef = new Firebase(ENV['STORM_URL'])
  tokenGenerator = new FirebaseTokenGenerator(ENV['STORM_KEY'])
  token = tokenGenerator.createToken(
    uid: 'SOME_UID'
    name: 'sqwad-droid')
    
  rootRef.authWithCustomToken token, (error, authData) ->
    if error
      cb error
    else
      cb null, rootRef
    return
  return

authenticateFirebase = (cb) ->
  rootRef = new Firebase(ENV['FIREBASE_URL'])
  tokenGenerator = new FirebaseTokenGenerator(ENV['FIREBASE_TOKEN'])
  token = tokenGenerator.createToken(
    uid: 'SOME_UID'
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
  if name is 'STORM_URL'
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
  size: (cb) ->
    authenticateFirebase (err, rootRef) ->
      if err
        cb(err)
      rootRef.once 'value', (snap) ->
        data = JSON.stringify(snap.val());
        bytes = Buffer.byteLength(data, 'utf8')
        cb(null, bytes)
      