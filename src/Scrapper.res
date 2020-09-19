let listPageUrl = "https://www.journee-mondiale.com/les-journees-mondiales.htm"

module JSDOM = {
  module Node = {
    type t = {
      textContent: string,
      innerHTML: string,
      src: string,
      href: string,
    }
  }
  type nodeList = array<Node.t>
  type document
  type window = {document: document}
  type t = {window: window}

  @bs.new @bs.module("jsdom") external make: string => t = "JSDOM"
  @bs.send external querySelectorAll: (document, string) => nodeList = "querySelectorAll"
  @bs.send @bs.return(nullable)
  external querySelector: (document, string) => option<Node.t> = "querySelector"
  @bs.send external getAttribute: (Node.t, string) => option<string> = "getAttribute"
}

@bs.get external getConfigUrl: Axios_types.config => string = "url"

let getWorldDayUrls = response => {
  let dom = JSDOM.make(response["data"])
  let elements = JSDOM.querySelectorAll(dom.window.document, "article li a")
  Array.map((item: JSDOM.Node.t) => item.href, elements)
}

type result = {
  content: option<string>,
  imageUrl: option<string>,
  title: string,
  url: string,
}

let extractDayOfYear = (dom: JSDOM.t) => {
  let day = JSDOM.querySelector(dom.window.document, "#date>time")
  switch day {
  | Some(node) =>
    switch JSDOM.getAttribute(node, "datetime") {
    | Some(attribute) =>
      Some(Js.String.split("-", attribute) |> (splitted => splitted[1] ++ "-" ++ splitted[2]))
    | None => None
    }
  | None => None
  }
}

let extractImageUrl = (dom: JSDOM.t) => {
  switch JSDOM.querySelector(dom.window.document, "#journeesDuJour img") {
  | Some(node) => Some(node.src)
  | None => None
  }
}

let extractContent = (dom: JSDOM.t) => {
  switch JSDOM.querySelector(dom.window.document, "#journeesDuJour") {
  | Some(node) => Some(node.innerHTML)
  | None => None
  }
}

let extractTitle = (dom: JSDOM.t) => {
  switch JSDOM.querySelector(dom.window.document, "#journeesDuJour>header>h1") {
  | Some(node) => node.textContent
  | None => ""
  }
}

Axios.get(listPageUrl) |> Js.Promise.then_(response => {
  let worldDayUrls = getWorldDayUrls(response)
  let resultMap = Js.Dict.fromList(list{})
  let _ =
    Axios.all(Array.map(url => Axios.get(url), worldDayUrls)) |> Js.Promise.then_(responses => {
      Belt.Array.forEach(responses, response => {
        let dom = JSDOM.make(response["data"])
        let result = {
          content: extractContent(dom),
          imageUrl: extractImageUrl(dom),
          title: extractTitle(dom),
          url: getConfigUrl(response["config"]),
        }
        switch extractDayOfYear(dom) {
        | Some(dayOfYear) =>
          switch Js.Dict.get(resultMap, dayOfYear) {
          | Some(resultList) => Js.Dict.set(resultMap, dayOfYear, list{result, ...resultList})
          | None => Js.Dict.set(resultMap, dayOfYear, list{result})
          }
        | None => ()
        }
      })
      Js.Promise.resolve(resultMap)
    }) |> Js.Promise.then_(result => {
      switch Js.Json.stringifyAny(result) {
      | Some(value) => Node.writeFileSync("./data.json", value)
      | None => ()
      }
      Js.Promise.resolve(result)
    })

  Js.Promise.resolve(resultMap)
})
