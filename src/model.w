bring openai;
bring cloud;

pub class Model {
  pub openai: openai.OpenAI;

  new() {
    let oaik = new cloud.Secret(name: "OPENAI_KEY") as "API Key";
    let model = new openai.OpenAI(apiKeySecret: oaik) as "OpenAI Model";
    nodeof(model).hidden = true;
    nodeof(oaik).hidden = true;

    this.openai = model;
  }
}