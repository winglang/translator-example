bring "./namer.w" as n;
bring cloud;
bring openai;

let oaik = new cloud.Secret(name: "OPENAI_KEY") as "openai_key";
let model = new openai.OpenAI(apiKeySecret: oaik) as "gpt_4o";

let namer = new n.Namer(model: model);

let examples = [
  "this is the content i want to use to create a file name",
  "this is another content i want to use to create a file name",
  "this is a third content i want to use to create a file name",
  "a poem about the ocean",
  "a poem about the sky",
  "some big string: 1234567890!@#$%^&*()_+",
];

new cloud.Function(inflight () => {
  for e in examples {
    let name = namer.makeFileName(e);
    log(name);
  }
}) as "test some examples";


bring expect;
test "create a file name" {
  let response = namer.makeFileName("this is the content i want to use to create a file name");

  expect.equal(Json.parse(response), {
    "mock":{
      "max_tokens":2048,
      "model":"gpt-4o",
      "messages":[
        {
          "role":"user",
          "content":#"{\"make_filename\":{\"content\":\"this is the content i want to use to create a file name\",\"all_lowercase\":true,\"word_delimiter\":\"-\",\"ext\":\".txt\",\"output_min_length\":5,\"output_max_length\":20,\"output_allowed_chars\":\"a-z0-9-\"},\"output_instructions\":\"output only the file name itself with the .txt extension without any surrounding quotes or other characters\"}"
        }
      ]
    }
  });
}