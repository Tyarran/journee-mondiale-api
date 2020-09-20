open Bindings

@bs.val @bs.scope("JSON")
external jsonParse: string => Js.Dict.t<array<Types.internationalDay>> = "parse"

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

App.get(app, ~path="/journee-mondiale/", Middleware.from((_, req, res) => {
    let response = Response.setHeader("Content-type", "application/json", res)
    let data =
      Js.Dict.values(data) |> Array.map((day: array<Types.internationalDay>) =>
        Array.map((event: Types.internationalDay) => event.title, day)
      )
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

App.listen(app, ~port=5000, ())
