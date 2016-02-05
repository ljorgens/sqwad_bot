# Description:
#   Example scripts for you to examine and try out.
#
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#
#   These are from the scripting documentation: https://github.com/github/hubot/blob/master/docs/scripting.md
_ = require("lodash")
filesize = require('filesize')
firebase = require('./firebase')
CronJob = require('cron').CronJob
moment = require('moment')

module.exports = (robot) ->
  robot.respond /(.*)information?/i, (msg) ->
    msg.send "Firebase backup service!"

  robot.respond /how big is firebase?/i, (msg) ->
    firebase.size (err, bytes) ->
      if err
        msg.send "An error occured"
      else
        size = filesize(bytes)
        msg.send "#{size}"

  robot.respond /backup firebase/i, (msg) ->
    firebase.backup (err, result) ->
      if err
        msg.send "Something went wrong! #{err.message}"
      else
        today = moment(new Date()).format('YYYY-MM-DD')
        size = filesize(result)
        msg.send "#{today}: #{size} of data successfully backed up!"
    return

  # Weekly schedule (10am every day)
  new CronJob('0 0 10 * * *', (->
    firebase.backup (err, result) ->
      if err
        robot.messageRoom "release", "Something went wrong! #{err.message}"
      else
        today = moment(new Date()).format('YYYY-MM-DD')
        size = filesize(result)
        robot.messageRoom "release", "#{today}: #{size} of data successfully backed up!"
    return
  ), null, true, 'America/Los_Angeles')
