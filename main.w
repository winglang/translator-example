bring cloud;
bring expect;
bring openai;
bring ui;
bring util;
bring "./namer.w" as n;

let sourceLanguage = "English";

let languages = [
  "Hebrew",
  "Italian",
  "Chinese",
  "Klingon",
];

let modelId = "gpt-4o";
let oaik = new cloud.Secret(name: "OPENAI_KEY") as "openai_key";
let model = new openai.OpenAI(apiKeySecret: oaik) as "gpt_4o";


struct Job {
  key: str;
  data: str;
}

struct TranslatorProps {
  fromLanguage: str;
  toLanguage: str;
  model: openai.OpenAI;
}

class Translator {
  opts: TranslatorProps;
  model: openai.OpenAI;
  queue: cloud.Queue;
  pub output: cloud.Bucket;

  new(opts: TranslatorProps) {
    this.opts = opts;
    this.model = opts.model;
    this.output = new cloud.Bucket();
    this.queue = new cloud.Queue();
    this.queue.setConsumer(inflight (message) => {
      let job = Job.parseJson(message);

      let prompt = {
        translation_request: {
          from_language: opts.fromLanguage,
          to_language: opts.toLanguage,
          content_to_translate: job.data,
        },
      };

      let result = this.model.createCompletion(Json.stringify(prompt), model: modelId);
      this.output.put(job.key, result);
      log("translated {job.key} to {this.opts.toLanguage}");
    });

    nodeof(this).title = "{opts.fromLanguage} => {opts.toLanguage} Translator";
  }

  pub inflight translate(key: str, data: str) {
    let job = Job { data: data, key: key };
    this.queue.push(Json.stringify(job));
  }
}

let input = new cloud.Bucket() as "input_bucket";

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
    
      let t = new Translator(fromLanguage: sourceLanguage, toLanguage: language, model: model) as "translator_{language}";
      this.translators.set(language, inflight (k, v) => {
        log("translating {k} to {language}...");
        t.translate(k, v);
      });
    
      this.readers.set(language, inflight (k) => {
        return t.output.get(k);
      });
    }
  }

  pub inflight translateAll(key: str, data: str) {
    for t in this.translators.values() {
      t(key, data);
    }
  }

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
    }) as "translate this";
    
    new cloud.Function(inflight () => {
      for key in input.list() {
        let data = input.get(key);
        translators.translateAll(key, data);  
      }
    }) as "redrive";    
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