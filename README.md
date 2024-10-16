# Appydave Tools

> AppyDave YouTube Automation Tools

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'appydave-tools'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install appydave-tools
```

## Stories

### Main Story

As a Content Creator, I want accellerate my video creation, so that I can improve speed and quality of my content

See all [stories](./STORIES.md)


## Usage

- [GPT Context Gatherer](./docs/usage/gpt-context.md)


## Development

Checkout the repo

```bash
git clone https://github.com/klueless-io/appydave-tools
```

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. 

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

```bash
bin/console

Aaa::Bbb::Program.execute()
# => ""
```

`appydave-tools` is setup with Guard, run `guard`, this will watch development file changes and run tests automatically, if successful, it will then run rubocop for style quality.

To release a new version, update the version number in `version.rb`, build the gem and push the `.gem` file to [rubygems.org](https://rubygems.org).

```bash
rake publish
rake clean
```

## Git helpers used by this project

Add the follow helpers to your `alias` file

```bash
function kcommit()
{
  echo 'git add .'
  git add .
  echo "git commit -m "$1""
  git commit -m "$1"
  echo 'git pull'
  git pull
  echo 'git push'
  git push
  sleep 3
  run_id="$(gh run list --limit 1 | grep -Eo "[0-9]{9,11}")"
  gh run watch $run_id --exit-status && echo "run completed and successful" && git pull && git tag | sort -V | tail -1
}
function kchore     () { kcommit "chore: $1" }
function kdocs      () { kcommit "docs: $1" }
function kfix       () { kcommit "fix: $1" }
function kfeat      () { kcommit "feat: $1" }
function ktest      () { kcommit "test: $1" }
function krefactor  () { kcommit "refactor: $1" }
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/klueless-io/appydave-tools. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Appydave Tools project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/klueless-io/appydave-tools/blob/master/CODE_OF_CONDUCT.md).

## Copyright

Copyright (c) David Cruwys. See [MIT License](LICENSE.txt) for further details.
