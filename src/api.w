bring cloud;
bring "./manager.w" as m;
bring "./namer.w" as n;

pub struct ApiProps {
  inputBucket: cloud.Bucket;
  manager: m.Manager;
  namer: n.Namer;
}

pub class Api {
  pub url: str;

  new(props: ApiProps) {
    let api = new cloud.Api(cors: true);
    let manager = props.manager;
    let input = props.inputBucket;

    this.url = api.url;

    api.get("/languages", inflight () => {
      return {
        body: Json.stringify(manager.targetLanguages)
      };
    });
    
    api.get("/docs", inflight () => {
      return {
        body: Json.stringify(input.list()),
        headers: { "content-type": "application/json" },
      };
    });
    
    api.get("/docs/:key", inflight (req) => {
      let lang = req.query.tryGet("language") ?? manager.sourceLanguage;
      let key = req.vars.get("key");
      try {
        let body = manager.readDocument(key, lang);
        return {
          body: body,
          headers: {
            "content-type": "text/plain"
          }
        };
      } catch e {
        return {
          body: "No translation of '{key}' to {lang}",
          status: 404
        };
      }   
    });
    
    api.post("/docs", inflight (req) => {
      if let body = req.body {
        let filename = props.namer.makeFileName(body);
        input.put(filename, body);
        return {
          body: "Document saved as: {filename}",
        };
      } else {
        return {
          status: 400,
          body: "No content provided"
        };
      }
    });
  }
}