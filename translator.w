bring openai;
bring cloud;

struct Job {
  key: str;
  data: str;
}

pub struct TranslatorProps {
  fromLanguage: str;
  toLanguage: str;
  model: openai.OpenAI;
}

pub class Translator {
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

      let result = this.model.createCompletion(Json.stringify(prompt), model: "gpt-4o");
      this.output.put(job.key, result);
      log("Translated {job.key} to {this.opts.toLanguage}");
    });

    nodeof(this).title = "{opts.fromLanguage} => {opts.toLanguage} Translator";
  }

  pub inflight translate(key: str, data: str) {
    let job = Job { data: data, key: key };
    this.queue.push(Json.stringify(job));
  }
}
