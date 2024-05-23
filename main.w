bring cloud;
bring expect;
bring openai;
bring ui;
bring util;
bring "./namer.w" as n;
bring "./translator.w" as t;

let sourceLanguage = "English";

let languages = [
  "French"
];

let modelId = "gpt-4o";
let oaik = new cloud.Secret(name: "OPENAI_KEY") as "OpenAI API Key";
let model = new openai.OpenAI(apiKeySecret: oaik) as "AI Model";

nodeof(model).hidden = true;
nodeof(oaik).hidden = true;

let input = new cloud.Bucket() as "Input Bucket";

/// Manages multiple translators
class Translators {
  translators: MutMap<inflight (str, str): void>;
  readers: MutMap<inflight (str): str>;

  new() {
    this.translators = {};
    this.readers = {};
    
    this.readers.set(sourceLanguage, inflight (k) => {
      return input.get(k);
    });
    
    for language in languages {
      let translator = new t.Translator(fromLanguage: sourceLanguage, toLanguage: language, model: model) as "{language} Translator";
      this.translators.set(language, inflight (k, v) => {
        log("Translating {k} to {language}...");
        translator.translate(k, v);
      });
    
      this.readers.set(language, inflight (k) => {
        return translator.output.get(k);
      });
    }
  }

  /// Translate a document to all supported languages
  pub inflight translateAll(key: str, data: str) {
    for t in this.translators.values() {
      t(key, data);
    }
  }

  /// Read the translation of a document in a given language
  pub inflight read(key: str, lang: str): str {
    if let reader = this.readers.tryGet(lang) {
      return reader(key);
    } else {
      throw "{lang} is not supported";
    }
  }
}

let translators = new Translators();

input.onCreate(inflight (key) => {
  let data = input.get(key);
  translators.translateAll(key, data);
});

class Api {
  pub url: str;

  new() {
    let api = new cloud.Api(cors: true);
    this.url = api.url;

    let result = MutArray<str>[sourceLanguage];
    for l in languages {
      result.push(l);
    }

    api.get("/languages", inflight () => {
      return {
        body: Json.stringify(result)
      };
    });
    
    api.get("/docs", inflight () => {
      return {
        body: Json.stringify(input.list()),
        headers: { "content-type": "application/json" },
      };
    });
    
    api.get("/docs/:key", inflight (req) => {
      let lang = req.query.tryGet("language") ?? sourceLanguage;
      let key = req.vars.get("key");
      try {
        let body = translators.read(key, lang);
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
  }
}

/// A bunch of backoffice tools
class Tools {
  new() {
    let namer = new n.Namer(model: model);

    new cloud.Function(inflight (content) => {
      let c = content ?? "";
      if c.length == 0 {
        throw "empty request";
      }

      log("Generating file name from the content");
      let fileName = namer.makeFileName(c);

      log("filename: {fileName}");

      input.put("{fileName}", c);
    }) as "Translate This";
    
    new cloud.Function(inflight () => {
      for key in input.list() {
        let data = input.get(key);
        translators.translateAll(key, data);  
      }
    }) as "Redrive";   
    
    new cloud.Function(inflight () => {
      for k in input.list() {
        input.delete(k);
      }

    }) as "Reset";
  }
}

struct FrontendProps {
  backend: Api;
}

class Frontend {
  new(props: FrontendProps) {
    let website = new cloud.Website(path: "./public");
    website.addJson("config.json", {
      backend: props.backend.url
    });

    nodeof(website).addConnection(source: website, target: props.backend, name: "backend");
  }
}

let api = new Api();
new Tools();
new Frontend(backend: api);