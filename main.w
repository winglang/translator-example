bring cloud;
bring expect;
bring openai;
bring ui;
bring util;
bring "./src" as src;

let model = new src.Model();
let namer = new src.Namer(model: model.openai);
let input = new cloud.Bucket() as "Input Bucket";

let manager = new src.Manager(
  model: model,
  sourceLanguage: "English",
  targetLanguages: [
    "French",
    "Hebrew",
    "Klingon"
  ],
);

input.onCreate(inflight (name) => {
  let data = input.get(name);
  manager.addDocument(name, data);
});

let api = new src.Api(
  manager: manager,
  namer: namer,
  inputBucket: input,
);

new src.Frontend(
  backend: api
);

new src.Tools(
  inputBucket: input,
  manager: manager,
  namer: namer,  
);


nodeof(model).hidden = true;