module NodeBinding = {
  @bs.val @bs.module("fs") external writeFileSync: (string, string) => unit = "writeFileSync"
  @bs.val @bs.module("fs") external readFileSync: (string, string) => string = "readFileSync"
}

module JSDOMBinding = {
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

module AxiosBinding = {
  @bs.get external getConfigUrl: Axios_types.config => string = "url"
}
