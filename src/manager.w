bring cloud;
bring "./translator.w" as t;
bring "./model.w" as m;

pub struct ManagerProps {
  sourceLanguage: str;
  targetLanguages: Array<str>;
  model: m.Model;
}

/// Manages multiple translators
pub class Manager {
  pub targetLanguages: Array<str>;
  pub sourceLanguage: str;

  translators: MutMap<inflight (str, str): void>;
  readers: MutMap<inflight (str): str>;

  new(props: ManagerProps) {
    this.translators = {};
    this.readers = {};
    this.targetLanguages = props.targetLanguages;
    this.sourceLanguage = props.sourceLanguage;

    let x = this.targetLanguages.copyMut();
    x.push(props.sourceLanguage);
        
    for language in props.targetLanguages {
      let translator = new t.Translator(fromLanguage: props.sourceLanguage, toLanguage: language, model: props.model) as "{language} Translator";
      this.translators.set(language, inflight (k, v) => {
        log("Translating {k} to {language}...");
        translator.translate(k, v);
      });
    
      this.readers.set(language, inflight (k) => {
        return translator.output.get(k);
      });
    }
  }

  /// Translates a document to all supported languages (asynchronsou)
  /// and stores the translations in the translators' output bucket.
  /// 
  /// Note that it might take a while for the translations to be ready 
  /// in the output bucket.
  pub inflight addDocument(name: str, content: str) {
    for translate in this.translators.values() {
      translate(name, content);
    }
  }

  /// Read the translation of a document by a certain name to a given language
  pub inflight readDocument(name: str, language: str): str {
    if let reader = this.readers.tryGet(language) {
      return reader(name);
    } else {
      throw "{language} is not supported";
    }
  }
}