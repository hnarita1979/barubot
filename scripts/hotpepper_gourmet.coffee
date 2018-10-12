# Description:
#   Searches restaurants from Hotpepper.
#
# Commands:
#   hubot ご飯 <query> - ご飯検索
#   hubot ランチ <query> - ランチ検索
#   hubot 酒 <query> - 日本酒が充実なお店検索
#   hubot 焼酎 <query> - 焼酎が充実なお店検索
#   hubot ワイン <query> - ワインが充実してるお店検索
#   hubot カラオケ <query> - カラオケができるお店検索
#   hubot 夜食 <query> - 23 時以降に食事ができるお店検索
#   hubot 飲み放題 <query> - 飲み放題のお店検索
#   hubot 食べ放題 <query> - 食べ放題のお店検索
#
# Author:
#   hnarita

RWS_API_KEY = process.env.HUBOT_RWS_API_KEY

cron = require("cron").CronJob
request = require("request")

module.exports = (robot) ->

  robot.respond /(hotpepper|gourmet|ご飯)( me)? (.*)/i, (msg) ->
    search_hpr msg.match[3], {},(err,res,msg_data) ->
      msg.send msg_data

  robot.respond /(lunch|ランチ)( me)? (.*)/i, (msg) ->
    search_hpr msg.match[3], { lunch: 1 },(err,res,msg_data) ->
      msg.send msg_data

  robot.respond /(sake|酒|日本酒)( me)? (.*)/i, (msg) ->
    search_hpr msg.match[3], { sake: 1 },(err,res,msg_data) ->
      msg.send msg_data

  robot.respond /(shochu|焼酎)( me)? (.*)/i, (msg) ->
    search_hpr msg.match[3], { shochu: 1 },(err,res,msg_data) ->
      msg.send msg_data

  robot.respond /(wine|ワイン)( me)? (.*)/i, (msg) ->
    search_hpr msg.match[3], { wine: 1 },(err,res,msg_data) ->
      msg.send msg_data

  robot.respond /(karaoke|カラオケ)( me)? (.*)/i, (msg) ->
    search_hpr msg.match[3], { karaoke: 1 },(err,res,msg_data) ->
      msg.send msg_data

  robot.respond /(midnight\s*meal|夜食)( me)? (.*)/i, (msg) ->
    search_hpr msg.match[3], { midnight_meal: 1 },(err,res,msg_data) ->
      msg.send msg_data

  robot.respond /(free\s*drink|飲み放題)( me)? (.*)/i, (msg) ->
    search_hpr msg.match[3], { free_drink: 1 },(err,res,msg_data) ->
      msg.send msg_data

  robot.respond /(free\s*food|食べ放題)( me)? (.*)/i, (msg) ->
    search_hpr msg.match[3], { free_food: 1 },(err,res,msg_data) ->
      msg.send msg_data

  robot.respond /hpr$/, (msg) ->
    search_hpr "日暮里駅", { lunch: 1 },(err,res,msg_data) ->

      # Slack に投稿
      msg.send msg_data

  cronjob = new cron(
    cronTime: "0 30 11 * * 1-5"    # 実行時間：秒・分・時間・日・月・曜日
    start:    true                # すぐにcronのjobを実行するか
    timeZone: "Asia/Tokyo"        # タイムゾーン指定
    onTick: ->                    # 時間が来た時に実行する処理
      search_hpr "日暮里駅", { lunch: 1 },(err,res,msg_data) ->
        robot.messageRoom "talk", msg_data

  )

# リクルートWEB サービス：グルメサーチAPI から情報を取得
search_hpr = (keyword, conditions,callback)->
  apiUrl="http://webservice.recruit.co.jp/hotpepper/gourmet/v1/"
  qs = conditions
  qs.key = RWS_API_KEY
  qs.keyword = keyword
  qs.count = 50
  qs.format = 'json'

  options =
    url: apiUrl
    qs: qs

  request.get options, (err,res,body) ->
    if err? or res.statusCode isnt 200
      console.log err
      return
    else
      shops = JSON.parse(body).results.shop
      shuffle shops


      attachments = []
      for shop in shops[0..5]
        attachments.push(
          pretext: "#{shop.genre.catch}"
          color: "#ff420b"
          title: "#{shop.name}"
          title_link: "#{shop.urls.pc}"
          text: "#{shop.catch}"
          footer: ":metro:#{shop.access}\n:yen:#{shop.budget.average}\n:clock3:#{shop.open}"
          image_url: "#{shop.photo.pc.m}#.png"
        )

      msg_data =
        text: "昼だよ！！今日のランチはどこにする？"
        attachments: attachments

      callback(err,res,msg_data)

# arrayをシャッフルする関数
shuffle = (array) ->
  i = array.length
  if i is 0 then return false
  while --i
    j = Math.floor Math.random() * (i + 1)
    tmpi = array[i]
    tmpj = array[j]
    array[i] = tmpj
    array[j] = tmpi
  return
