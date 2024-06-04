bring cloud;
bring expect;
bring util;
bring "./manager.w" as m;
bring "./model.w" as mm;

let input = new cloud.Bucket();
let model = new mm.Model();

let manager = new m.Manager(
  targetLanguages: ["Spanish", "French", "German"],
  sourceLanguage: "English",
  model: model,
);

expect.equal(manager.sourceLanguage, "English");
expect.equal(manager.targetLanguages, ["Spanish", "French", "German"]);

// test "translateAll" {
//   let name = "my-doc.txt";
  
//   manager.addDocument("my-doc.txt", "Hello, world!");

//   // check that we can read the source document.


//   util.waitUntil(() => {
//     for l in manager.targetLanguages {
//     }
//   });

  
// }