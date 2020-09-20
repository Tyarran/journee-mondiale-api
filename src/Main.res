open Bindings

@bs.val @bs.scope("JSON")
external jsonParse: string => Js.Dict.t<array<Types.internationalDay>> = "parse"

let port = 5000
let data = NodeBinding.readFileSync("./data.json", "utf-8") |> jsonParse

open Express
let app = App.make()

let getKey = date => {
  let formatStringValue = value =>
    switch Js.String.length(value) {
    | 1 => "0" ++ value
    | _ => value
    }
  let convertToIntString = floatValue =>
    floatValue |> Belt.Float.toInt |> string_of_int |> formatStringValue
  let month = Js.Date.getMonth(date) +. 1.0 |> convertToIntString
  let day = Js.Date.getDate(date) |> convertToIntString
  month ++ "-" ++ day
}

@bs.get_index external unsafeGet: (Express.Request.t, string) => string = ""
type headers
@bs.get external getHeaders: Express.Request.t => headers = "headers"
@bs.get external getHost: headers => string = "host"

let buildUri = (req, date) => {
  unsafeGet(req, "protocol") ++
  "://" ++
  (req |> getHeaders |> getHost) ++
  unsafeGet(req, "originalUrl") ++
  date
}

let buildSummaries = days => {
  Array.map((internationalDay: Types.internationalDay) => {
    let result: Types.internationalDaySummary = {
      title: internationalDay.title,
      url: internationalDay.url,
    }
    result
  }, days)
}

let buildDaySummaries = (req, data) => {
  let keys = Js.Dict.keys(data)
  Array.map(key => {
    switch Js.Dict.get(data, key) {
    | Some(value) => {
        let daySummary: Types.daySummary = {
          date: key,
          uri: buildUri(req, key),
          internationalDays: buildSummaries(value),
        }
        daySummary
      }
    | None => {
        let daySummary: Types.daySummary = {
          date: key,
          uri: "",
          internationalDays: [],
        }
        daySummary
      }
    }
  }, keys)
}

App.get(app, ~path="/journee-mondiale/", Middleware.from((_, req, res) => {
    let response = Response.setHeader("Content-type", "application/json", res)
    let data = buildDaySummaries(req, data)
    switch Js.Json.stringifyAny(data) {
    | Some(json) => Response.sendString(json, response)
    | None => Response.sendStatus(Response.StatusCode.NotFound, response)
    }
  }))

App.get(app, ~path="/journee-mondiale/:dateIso", Middleware.from((_, req, res) => {
    let response = Response.setHeader("Content-type", "application/json", res)
    let key = switch Js.Dict.get(Request.params(req), "dateIso") {
    | Some(value) =>
      switch Js.String.make(value) {
      | "today" | "aujourdhui" => Js.Date.make()
      | value => Js.Date.fromString(Js.String.make(value))
      }
    | None => Js.Date.make()
    } |> getKey
    switch Js.Dict.get(data, key) {
    | Some(value) =>
      switch Js.Json.stringifyAny(value) {
      | Some(json) => Response.sendString(json, response)
      | None => Response.sendStatus(Response.StatusCode.NotFound, response)
      }
    | None => Response.sendStatus(Response.StatusCode.NotFound, response)
    }
  }))

App.listen(app, ~port, ())
