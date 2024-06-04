bring cloud;
bring "./namer.w" as n;
bring "./manager.w" as m;

pub struct ToolsProps {
  inputBucket: cloud.Bucket;
  namer: n.Namer;
  manager: m.Manager;
}

/// A bunch of backoffice tools
pub class Tools {
  new(props: ToolsProps) {
    let namer = props.namer;
    let input = props.inputBucket;
    let manager = props.manager;

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
        manager.addDocument(key, data);  
      }
    }) as "Redrive";   
    
    new cloud.Function(inflight () => {
      for k in input.list() {
        input.delete(k);
      }
    }) as "Reset";
  }
}