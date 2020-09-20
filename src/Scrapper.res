open Bindings

let listPageUrl = "https://www.journee-mondiale.com/les-journees-mondiales.htm"
let destPath = "./data.json"

let getDescriptionUrls = response => {
  let dom = JSDOMBinding.make(response["data"])
  let elements = JSDOMBinding.querySelectorAll(dom.window.document, "article li a")
  Array.map((item: JSDOMBinding.Node.t) => item.href, elements)
}

let extractDayOfYear = (dom: JSDOMBinding.t) => {
  let day = JSDOMBinding.querySelector(dom.window.document, "#date>time")
  switch day {
  | Some(node) =>
    switch JSDOMBinding.getAttribute(node, "datetime") {
    | Some(attribute) =>
      Some(Js.String.split("-", attribute) |> (splitted => splitted[1] ++ "-" ++ splitted[2]))
    | None => None
    }
  | None => None
  }
}

let extractImageUrl = (dom: JSDOMBinding.t) => {
  switch JSDOMBinding.querySelector(dom.window.document, "#journeesDuJour img") {
  | Some(node) => Some(node.src)
  | None => None
  }
}

let extractContent = (dom: JSDOMBinding.t) => {
  switch JSDOMBinding.querySelector(
    dom.window.document,
    "#journeesDuJour section[itemprop=description]",
  ) {
  | Some(node) => Some(node.innerHTML)
  | None => None
  }
}

let extractTitle = (dom: JSDOMBinding.t) => {
  switch JSDOMBinding.querySelector(dom.window.document, "#journeesDuJour>header>h1") {
  | Some(node) => node.textContent
  | None => ""
  }
}

let addResultToMap = (map, dayOfYear, result) => {
  switch dayOfYear {
  | Some(dayOfYear) =>
    switch Js.Dict.get(map, dayOfYear) {
    | Some(resultList) => Js.Dict.set(map, dayOfYear, list{result, ...resultList})
    | None => Js.Dict.set(map, dayOfYear, list{result})
    }
  | None => ()
  }
}

let prepareDataToStore = data => {
  let formatedResult = Js.Dict.map(
    (. value) => Belt.List.toArray(value) |> Belt.Array.reverse,
    data,
  )
  switch Js.Json.stringifyAny(formatedResult) {
  | Some(value) => Ok(value)
  | None => Error("Unable to stringify")
  }
}

Axios.get(listPageUrl) |> Js.Promise.then_(response => {
  let descriptionUrls = getDescriptionUrls(response)
  let resultMap = Js.Dict.fromList(list{})
  let addResult = addResultToMap(resultMap)
  let _ =
    Axios.all(Array.map(url => Axios.get(url), descriptionUrls)) |> Js.Promise.then_(responses => {
      Belt.Array.forEach(responses, response => {
        let dom = JSDOMBinding.make(response["data"])
        let result: Types.internationalDay = {
          content: extractContent(dom),
          imageUrl: extractImageUrl(dom),
          title: extractTitle(dom),
          url: AxiosBinding.getConfigUrl(response["config"]),
        }
        addResult(extractDayOfYear(dom), result)
      })
      Js.Promise.resolve(resultMap)
    }) |> Js.Promise.then_(result => {
      switch prepareDataToStore(result) {
      | Ok(value) => {
          NodeBinding.writeFileSync(destPath, value)
          Js.log(`Scrapping done. All data are stored in "${destPath}"`)
        }
      | Error(message) => Js.log(`Scrapping error: ${message}`)
      }
      Js.Promise.resolve(result)
    })

  Js.Promise.resolve(resultMap)
})
