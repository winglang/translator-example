bring "./translator.w" as t;
bring "./model.w" as m;
bring openai;
bring cloud;
bring util;
bring expect;

let model = new m.Model();

let translator = new t.Translator(fromLanguage: "english", toLanguage: "hebrew", model: model) as "translator";

let fixtures = [
  "this is the content i want to use to create a file name",
  "this is another content i want to use to create a file name",
  "this is a third content i want to use to create a file name",
  "a poem about the ocean",
  "a poem about the sky",
  "some big string: 1234567890!@#$%^&*()_+",
];

new cloud.Function(inflight () => {
  let var i = 0;
  for f in fixtures {
    translator.translate("fixture-{i}.txt", f);
    i += 1;
  }
}) as "translate fixtures";

test "translation ends up in the destination bucket" {
  translator.translate("test.txt", "this is a test");
  util.waitUntil(() => {
    return translator.output.list().length > 0;
  });

  expect.equal(Json.parse(translator.output.get("test.txt")), {
    "mock":{
      "max_tokens":2048,
      "model":"gpt-4o",
      "messages":[
        {
          "role":"user",
          "content":#"{\"translation_request\":{\"from_language\":\"english\",\"to_language\":\"spanish\",\"content_to_translate\":\"this is a test\"}}"
        }
      ]
    }
  });
}