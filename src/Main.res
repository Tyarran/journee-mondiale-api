@bs.val @bs.scope("JSON") external jsonParse: string => Js.Dict.t<list<Scrapper.result>> = "parse"

let data = Node.readFileSync("./data.json", "utf-8") |> jsonParse

switch Js.Dict.get(data, "12-15") {
| Some(value) => List.iter((result: Scrapper.result) => {
    Js.log(result.url)
  }, value)
| None => Js.log("None")
}
