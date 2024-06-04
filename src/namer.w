bring openai;

pub struct NamerProps {
  model: openai.OpenAI;
}

/// Creates names with AI.
pub class Namer {
  props: NamerProps;

  new(props: NamerProps) {
    this.props = props;
  }

  /// Generate a file name from the provided content
  pub inflight makeFileName(content: str): str {
    let prompt = {
      make_filename: {
        content: content,
        all_lowercase: true,
        word_delimiter: "-",
        ext: ".txt",
        output_min_length: 5,
        output_max_length: 20,
        output_allowed_chars: "a-z0-9\-"
      },
      output_instructions: "output only the file name itself with the .txt extension without any surrounding quotes or other characters",
    };

    return this.props.model.createCompletion(Json.stringify(prompt), model: "gpt-4o");
  }
}
