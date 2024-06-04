bring cloud;
bring "./api.w" as a;

struct FrontendProps {
  backend: a.Api;
}

pub class Frontend {
  new(props: FrontendProps) {
    let website = new cloud.Website(path: "{@dirname}/public");
    website.addJson("config.json", {
      backend: props.backend.url
    });

    // nodeof(website).addConnection(source: website, target: props.backend, name: "backend");
  }
}