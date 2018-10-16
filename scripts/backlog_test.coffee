# Description:
#   backlog テスト用
#

async = require "async"
cron = require("cron").CronJob

common_function = require "./common_function"
cmn_fn = new common_function()

Backlog = require "./backlog"
backlog = new Backlog()

users_list = require('../config/users.json')

module.exports = (robot) ->

  robot.respond /(.+)の課題$/, (msg) ->
    name = msg.match[1]

    for user_info in users_list
      user_id = user_info.backlog_id if user_info.name == name

    param =
      statusId:  ["1", "2", "3"]
      assigneeId:["#{user_id}"]

    backlog.getIssues(param)
    .then (messages) ->
      msg.send messages.join("\n")

  # スター集計
  robot.respond /star$/, (msg) ->
    today = new Date()
    date_span = -1
    date_span_text = "昨日"
    if today.getDay() is 1
      date_span = -7
      date_span_text = "先週"

    cmn_fn.date_add new Date(), date_span, 'DD', (since_date) ->
      cmn_fn.date_format since_date,'YYYY-MM-DD',(since_str) ->
        cmn_fn.date_format new Date(),'YYYY-MM-DD',(until_str) ->
          stars_list = []
          async.map users_list
          , (user,callback) ->
            backlog.get_stars user.backlog_id, since_str, until_str, (err,res,stars) ->
              stars_list.push(
                name: "#{user.name}"
                stars: stars
              )
              result =
                name: "#{user.name}"
                stars: stars

              callback(null,result)
          , (err,result) ->

            compare_stars = (a, b) ->
              b.stars - a.stars

            stars_list.sort compare_stars
            messages = []

            for star in stars_list
              mark = ""
              if parseInt(star.stars,10) > 0
                for i in [0...parseInt(star.stars,10)]
                  mark += ":star:"

              messages.push ("#{star.name}　　　　　　　　").slice(0,7) + "さん " + ("   #{star.stars}").slice(-3) + "スター #{mark}"

            # メッセージ整形
            data =
              attachments: [
                color: "#ffcc66"
                title: ":star2: #{date_span_text}のスター獲得ランキング :star2:"
                title_link: "https://backlog.com/ja/help/usersguide/star/userguide456/"
                fields: [
                  {
                    title: "今日も一日がんばりましょう！"
                    value: messages.join("\n")
                    short: false
                  }
                ]
              ]

            msg.send data

  cronjob = new cron(
    cronTime: "0 55 8 * * *"      # 実行時間：秒・分・時間・日・月・曜日
    start:    true                # すぐにcronのjobを実行するか
    timeZone: "Asia/Tokyo"        # タイムゾーン指定
    onTick: ->                    # 時間が来た時に実行する処理
      today = new Date()
      date_span = -1
      date_span_text = "昨日"
      if today.getDay() is 1
        date_span = -7
        date_span_text = "先週"

      cmn_fn.date_add new Date(), date_span, 'DD', (since_date) ->
        cmn_fn.date_format since_date,'YYYY-MM-DD',(since_str) ->
          cmn_fn.date_format new Date(),'YYYY-MM-DD',(until_str) ->
            stars_list = []
            async.map users_list
            , (user,callback) ->
              backlog.get_stars user.backlog_id, since_str, until_str, (err,res,stars) ->
                stars_list.push(
                  name: "#{user.name}"
                  stars: stars
                )
                result =
                  name: "#{user.name}"
                  stars: stars

                callback(null,result)
            , (err,result) ->

              compare_stars = (a, b) ->
                b.stars - a.stars

              stars_list.sort compare_stars
              messages = []

              for star in stars_list
                mark = ""
                if parseInt(star.stars,10) > 0
                  for i in [0...parseInt(star.stars,10)]
                    mark += ":star:"

                messages.push ("#{star.name}　　　　　　　　").slice(0,7) + "さん " + ("   #{star.stars}").slice(-3) + "スター #{mark}"

              # メッセージ整形
              data =
                attachments: [
                  color: "#ffcc66"
                  title: ":star2: #{date_span_text}のスター獲得ランキング :star2:"
                  title_link: "https://backlog.com/ja/help/usersguide/star/userguide456/"
                  fields: [
                    {
                      title: "今日も一日がんばりましょう！"
                      value: messages.join("\n")
                      short: false
                    }
                  ]
                ]

              robot.messageRoom "talk", data

  )
