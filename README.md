# Translator Service Example

This is an example of a Wing application that translates documents to multiple languages using
GPT-4o.

It can run locally in the Wing Simulator:

```sh
wing run
```

It can be deployed to AWS through Terraform:

```sh
wing compile -t tf-aws
terraform -chdir=target/main.tfaws init
terraform -chdir=target/main.tfaws apply
```

Or it can be deployed to AWS using the AWS CDK:

```sh
npx cdk deploy
```

## Roadmap

* GCP and Azure support requires `cloud.Secret` implementation for these
  platforms ([#2178](https://github.com/winglang/wing/issues/2178), [#2179](https://github.com/winglang/wing/issues/2179)).
* CloudFront issue when deploying using AWS CDK

## License

MIT.
