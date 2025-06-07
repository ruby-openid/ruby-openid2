# Ruby OpenID

[![Version](https://img.shields.io/gem/v/ruby-openid2.svg)](https://rubygems.org/gems/ruby-openid2)
[![Downloads Today](https://img.shields.io/gem/rd/ruby-openid2.svg)](https://github.com/oauth-xx/ruby-openid2)
[![CI Supported Build][🚎s-wfi]][🚎s-wf]
[![CI Unsupported Build][🚎us-wfi]][🚎us-wf]
[![CI Style Build][🚎st-wfi]][🚎st-wf]
[![CI Coverage Build][🚎cov-wfi]][🚎cov-wf]
[![CI Heads Build][🚎hd-wfi]][🚎hd-wf]

[🚎s-wf]: https://github.com/oauth-xx/ruby-openid2/actions/workflows/supported.yml
[🚎s-wfi]: https://github.com/oauth-xx/ruby-openid2/actions/workflows/supported.yml/badge.svg
[🚎us-wf]: https://github.com/oauth-xx/ruby-openid2/actions/workflows/unsupported.yml
[🚎us-wfi]: https://github.com/oauth-xx/ruby-openid2/actions/workflows/unsupported.yml/badge.svg
[🚎st-wf]: https://github.com/oauth-xx/ruby-openid2/actions/workflows/style.yml
[🚎st-wfi]: https://github.com/oauth-xx/ruby-openid2/actions/workflows/style.yml/badge.svg
[🚎cov-wf]: https://github.com/oauth-xx/ruby-openid2/actions/workflows/coverage.yml
[🚎cov-wfi]: https://github.com/oauth-xx/ruby-openid2/actions/workflows/coverage.yml/badge.svg
[🚎hd-wf]: https://github.com/oauth-xx/ruby-openid2/actions/workflows/heads.yml
[🚎hd-wfi]: https://github.com/oauth-xx/ruby-openid2/actions/workflows/heads.yml/badge.svg
-----

[![Liberapay Goal Progress][⛳liberapay-img]][⛳liberapay] [![Sponsor Me on Github][🖇sponsor-img]][🖇sponsor] [![Buy me a coffee][🖇buyme-small-img]][🖇buyme] [![Donate on Polar][🖇polar-img]][🖇polar] [![Donate to my FLOSS or refugee efforts at ko-fi.com][🖇kofi-img]][🖇kofi] [![Donate to my FLOSS or refugee efforts using Patreon][🖇patreon-img]][🖇patreon]

[⛳liberapay-img]: https://img.shields.io/liberapay/goal/pboling.svg?logo=liberapay
[⛳liberapay]: https://liberapay.com/pboling/donate
[🖇sponsor-img]: https://img.shields.io/badge/Sponsor_Me!-pboling.svg?style=social&logo=github
[🖇sponsor]: https://github.com/sponsors/pboling
[🖇polar-img]: https://img.shields.io/badge/polar-donate-yellow.svg
[🖇polar]: https://polar.sh/pboling
[🖇kofi-img]: https://img.shields.io/badge/a_more_different_coffee-✓-yellow.svg
[🖇kofi]: https://ko-fi.com/O5O86SNP4
[🖇patreon-img]: https://img.shields.io/badge/patreon-donate-yellow.svg
[🖇patreon]: https://patreon.com/galtzo
[🖇buyme-small-img]: https://img.shields.io/badge/buy_me_a_coffee-✓-yellow.svg?style=flat

A Ruby library for verifying and serving OpenID identities.

## Features

  * Easy to use API for verifying OpenID identites - OpenID::Consumer
  * Support for serving OpenID identites - OpenID::Server
  * Does not depend on underlying web framework
  * Supports multiple storage mechanisms (Filesystem, ActiveRecord, Memory)
  * Example code to help you get started, including:
    * Ruby on Rails based consumer and server
    * OpenIDLoginGenerator for quickly getting creating a rails app that uses
      OpenID for authentication
    * ActiveRecordOpenIDStore plugin
  * Comprehensive test suite
  * Supports both OpenID 1 and OpenID 2 transparently

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add ruby-openid2

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install ruby-openid2

### Note about the deprecation of stdlib gems `logger`, `rexml`, `net-http`, and `uri`

Versions 3.0.x were released with hard dependencies on the new stand alone gem replacements
for the old stdlib gems.

This made it impossible for downstream libraries to make the choice to stay on the old stdlib gems.

As a result, starting with version 3.1.0, they will not be direct dependencies.

See [this discussion](https://github.com/rubygems/rubygems/issues/7178#issuecomment-2372558363) for more information.

## Getting Started

The best way to start is to look at the rails_openid example.
You can run it with:

    cd examples/rails_openid
    script/server

If you are writing an OpenID Relying Party, a good place to start is:
`examples/rails_openid/app/controllers/consumer_controller.rb`

And if you are writing an OpenID provider:
`examples/rails_openid/app/controllers/server_controller.rb`

The library code is quite well documented, so don't be squeamish, and
look at the library itself if there's anything you don't understand in
the examples.

## General Info

| Primary Namespace | OpenID                                                                                                                                                                                                                                                                                                                                                                                                                                                |
|-------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| gem name          | [ruby-openid2](https://rubygems.org/gems/ruby-openid2)                                                                                                                                                                                                                                                                                                                                                                                                |
| code triage       | [![Open Source Helpers](https://www.codetriage.com/oauth-xx/ruby-openid2/badges/users.svg)](https://www.codetriage.com/oauth-xx/ruby-openid2)                                                                                                                                                                                                                                                                                                         |
| documentation     | [on Github.com][homepage],  [on rubydoc.info][documentation]                                                                                                                                                                                                                                                                                                                                                                                             |
| expert support    | [![Get help on Codementor](https://cdn.codementor.io/badges/get_help_github.svg)](https://www.codementor.io/peterboling?utm_source=github&utm_medium=button&utm_term=peterboling&utm_campaign=github)                                                                                                                                                                                                                                                 |
| `...` 💖          | [![Liberapay Patrons][⛳liberapay-img]][⛳liberapay] [![Sponsor Me][🖇sponsor-img]][🖇sponsor] [![Follow Me on LinkedIn][🖇linkedin-img]][🖇linkedin] [![Find Me on WellFound:][✌️wellfound-img]][✌️wellfound] [![Find Me on CrunchBase][💲crunchbase-img]][💲crunchbase] [![My LinkTree][🌳linktree-img]][🌳linktree] [![Follow Me on Ruby.Social][🐘ruby-mast-img]][🐘ruby-mast] [![Tweet @ Peter][🐦tweet-img]][🐦tweet] [💻][coderme] [🌏][aboutme] |

<!-- 7️⃣ spread 💖 -->
[🐦tweet-img]: https://img.shields.io/twitter/follow/galtzo.svg?style=social&label=Follow%20%40galtzo
[🐦tweet]: http://twitter.com/galtzo
[🚎blog]: http://www.railsbling.com/tags/ruby-openid2/
[🚎blog-img]: https://img.shields.io/badge/blog-railsbling-brightgreen.svg?style=flat
[🖇linkedin]: http://www.linkedin.com/in/peterboling
[🖇linkedin-img]: https://img.shields.io/badge/PeterBoling-blue?style=plastic&logo=linkedin
[✌️wellfound]: https://angel.co/u/peter-boling
[✌️wellfound-img]: https://img.shields.io/badge/peter--boling-orange?style=plastic&logo=wellfound
[💲crunchbase]: https://www.crunchbase.com/person/peter-boling
[💲crunchbase-img]: https://img.shields.io/badge/peter--boling-purple?style=plastic&logo=crunchbase
[🐘ruby-mast]: https://ruby.social/@galtzo
[🐘ruby-mast-img]: https://img.shields.io/mastodon/follow/109447111526622197?domain=https%3A%2F%2Fruby.social&style=plastic&logo=mastodon&label=Ruby%20%40galtzo
[🌳linktree]: https://linktr.ee/galtzo
[🌳linktree-img]: https://img.shields.io/badge/galtzo-purple?style=plastic&logo=linktree
[documentation]: https://rubydoc.info/github/oauth-xx/rack-openid2
[homepage]: https://github.com/oauth-xx/rack-openid2

<!-- Maintainer Contact Links -->
[aboutme]: https://about.me/peter.boling
[coderme]: https://coderwall.com/Peter%20Boling

## Community

Discussion regarding the Ruby OpenID library and other JanRain OpenID
libraries takes place on the [OpenID mailing list](http://openid.net/developers/dev-mailing-lists/).

Please join this list to discuss, ask implementation questions, report
bugs, etc. Also check out the openid channel on the freenode IRC
network.

## 🤝 Contributing

See [CONTRIBUTING.md][🤝contributing]

[🤝contributing]: CONTRIBUTING.md

## 🌈 Contributors

[![Contributors][🖐contributors-img]][🖐contributors]

Made with [contributors-img][🖐contrib-rocks].

[🖐contrib-rocks]: https://contrib.rocks
[🖐contributors]: https://github.com/oauth-xx/ruby-openid2/graphs/contributors
[🖐contributors-img]: https://contrib.rocks/image?repo=oauth-xx/ruby-openid2

## 🪇 Code of Conduct

Everyone interacting in this project's codebases, issue trackers,
chat rooms and mailing lists is expected to follow the [code of conduct][🪇conduct].

[🪇conduct]: CODE_OF_CONDUCT.md

## 📌 Versioning

This Library adheres to [Semantic Versioning 2.0.0][📌semver].
Violations of this scheme should be reported as bugs.
Specifically, if a minor or patch version is released that breaks backward compatibility,
a new version should be immediately released that restores compatibility.
Breaking changes to the public API will only be introduced with new major versions.

To get a better understanding of how SemVer is intended to work over a project's lifetime,
read this article from the creator of SemVer:

- ["Major Version Numbers are Not Sacred"][📌major-versions-not-sacred]

As a result of this policy, you can (and should) specify a dependency on these libraries using
the [Pessimistic Version Constraint][📌pvc] with two digits of precision.

For example:

```ruby
spec.add_dependency("ruby-openid2", "~> 3.0")
```

See [CHANGELOG.md][📌changelog] for list of releases.

[comment]: <> ( 📌 VERSIONING LINKS )

[📌pvc]: http://guides.rubygems.org/patterns/#pessimistic-version-constraint
[📌semver]: http://semver.org/
[📌major-versions-not-sacred]: https://tom.preston-werner.com/2022/05/23/major-version-numbers-are-not-sacred.html
[📌changelog]: CHANGELOG.md

### © Copyright

* Copyright (c) 2006-2012 JanRain, Inc.
* Copyright (c) 2024 [Peter H. Boling][peterboling] of [Rails Bling][railsbling]

[railsbling]: http://www.railsbling.com
[peterboling]: http://www.peterboling.com
[bundle-group-pattern]: https://gist.github.com/pboling/4564780

## 📄 License

Apache Software License.  For more information see the LICENSE file.

## 🤑 One more thing

You made it to the bottom of the page,
so perhaps you'll indulge me for another 20 seconds.
I maintain many dozens of gems, including this one,
because I want Ruby to be a great place for people to solve problems, big and small.
Please consider supporting my efforts via the giant yellow link below,
or one of the others at the head of this README.

[![Buy me a latte][🖇buyme-img]][🖇buyme]

[🖇buyme-img]: https://img.buymeacoffee.com/button-api/?text=Buy%20me%20a%20latte&emoji=&slug=pboling&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff
[🖇buyme]: https://www.buymeacoffee.com/pboling