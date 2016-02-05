async = require('async')
AWS = require('aws-sdk')
Firebase = require('firebase')
FirebaseTokenGenerator = require('firebase-token-generator')
moment = require('moment')

authenticateFirebase = (cb) ->
  rootRef = new Firebase('https://whawksv2.firebaseio.com')
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

exportFirebaseData = (rootRef, cb) ->
  rootRef.once 'value', ((snap) ->
    data = snap.exportVal()
    cb null, data
    return
  ), (error) ->
    cb error
    return
  return

uploadtoS3 = (data, cb) ->
  date = new Date
  today = moment(date).format('YYYY-MM-DD')
  payload = JSON.stringify(data)
  AWS.config.region = 'us-west-2'
  s3 = new (AWS.S3)
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
  size: (cb) ->
    authenticateFirebase (err, rootRef) ->
      if err
        cb(err)
      rootRef.once 'value', (snap) ->
        data = JSON.stringify(snap.val());
        bytes = Buffer.byteLength(data, 'utf8')
        cb(null, bytes)