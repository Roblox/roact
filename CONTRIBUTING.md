# Contributing to Roact
Thanks for considering contributing to Roact! This guide has a few tips and guidelines to make contributing to the project as easy as possible.

## Bug Reports
Any bugs (or things that look like bugs) can be reported on the [GitHub issue tracker](https://github.com/Roblox/Roact/issues).

Make sure you check to see if someone has already reported your bug first! Don't fret about it; if we notice a duplicate we'll send you a link to the right issue!

## Feature Requests
If there are any features you think are missing from Roact, you can post a request in the [GitHub issue tracker](https://github.com/Roblox/Roact/issues).

Just like bug reports, take a peak at the issue tracker for duplicates before opening a new feature request.

## Documentation
[Roact's documentation](https://roblox.github.io/roact) is built using [MkDocs](http://www.mkdocs.org/), a fairly simple documentation generator.

All of the dependencies that we use to generate the documentation website are located in [docs/requirements.txt](docs/requirements.txt); once they're set up, use `mkdocs serve` to test the documentation locally.

## Working on Roact
To get started working on Roact, you'll need:
* Git
* Lua 5.1
* Lemur's dependencies:
	* [LuaFileSystem](https://keplerproject.github.io/luafilesystem/) (`luarocks install luafilesystem`)
* [LuaCov](https://keplerproject.github.io/luacov) (`luarocks install luacov`)

Foreman is an un-package manager that retrieves code directly from GitHub repositories. We'll use this to get a lua code analysis tool and other utilities. The Foreman packages are listed in `foreman.toml`.

You can install `foreman` from its [releases page](https://github.com/rojo-rbx/foreman/releases). If you have the Rust tool `cargo` installed, you can also do `cargo install foreman`. Either way, be sure the foreman binary location is in your `PATH` environment variable.

```
foreman github-auth <[your GitHub API token](https://github.com/settings/tokens)>
foreman install
export PATH=$PATH:~/.foreman/bin/ # you might want to add this to your .bash_profile (or similarly appropriate shell configuration) file as well
```

After running `foreman install`, you should be able to run `stylua src` and `selene src` commands -- just like this repository's continuous integration steps do! This helps ensure that our code and your contributions are consistently formatted and are free of trivial bugs.

Make sure you have all of the Git submodules for Roact downloaded, which include a couple extra dependencies used for testing.

Finally, you can run all of Roact's tests with:

```sh
lua bin/spec.lua
```

Or, to also generate a LuaCov coverage report:

```sh
lua -lluacov bin/spec.lua
luacov
```

## Pull Requests
Before starting a pull request, open an issue about the feature or bug. This helps us prevent duplicated and wasted effort. These issues are a great place to ask for help if you run into problems!

Before you submit a new pull request, check:
* Code Style: Run [StyLua](https://github.com/JohnnyMorganz/StyLua) to ensure your code changes follow the [official Roblox Lua style guide](https://roblox.github.io/lua-style-guide) and the local code style
* selene: Run [Selene](https://github.com/kampfkarren/selene) on your code, no warnings allowed!
* Tests: They all need to pass!
* Changelog: Add an entry to [CHANGELOG.md](CHANGELOG.md)

### Code Style
Roblox has an [official Lua style guide](https://roblox.github.io/lua-style-guide) which should be the general guidelines for all new code. When modifying code, follow the existing style!

In short:

* Tabs for indentation
* Double quotes
* One statement per line

Use `StyLua` (instructions below) to automatically format the code to follow the coding style

### Changelog
Adding an entry to [CHANGELOG.md](CHANGELOG.md) alongside your commit makes it easier for everyone to keep track of what's been changed.

Add a line under the "Current master" heading. When we make a new release, all of those bullet points will be attached to a new version and the "Current master" section will become empty again.

Add a link to your pull request in the entry. We don't need to link to the related GitHub issue, since pull requests will also link to them.

### Selene and StyLua
We use [Selene](https://github.com/kampfkarren/selene) and [StyLua](https://github.com/JohnnyMorganz/StyLua) for static analysis of Lua on all of our projects.

From the command line, just run `selene src` and `stylua -c src` to check the Roact source. You'll need to install `foreman` and run `foreman install` first, which will make both the `selene` and `stylua` tools available.

You should get it working on your system, and then get a plugin for the editor you use. There are plugins available for most popular editors!

### Tests
When submitting a bug fix, create a test that verifies the broken behavior and that the bug fix works. This helps us avoid regressions!

When submitting a new feature, add tests for all functionality.

We use [LuaCov](https://keplerproject.github.io/luacov) for keeping track of code coverage. We'd like it to be as close to 100% as possible, but it's not always possible. Adding tests just for the purpose of getting coverage isn't useful; we should strive to make only useful tests!

## Release Checklist
When releasing a new version of Roact, do these things:

1. Bump the version in `rotriever.toml`.
2. Move the unreleased changes in `CHANGELOG.md` to a new heading.
	- This heading should have a GitHub release link and release date!
3. Update `docs/api-reference.md` to flag any unreleased APIs with the new version.
5. Commit with Git:
	- Commit: `git commit -m "Release v2.3.7"`
	- Tag the commit: `git tag v2.3.7`
	- Push commits: `git push`
	- Push the tag: `git push origin v2.3.7`
6. Build a binary with Rojo: `rojo build -o Roact.rbxm`
7. Write a release on GitHub:
	- Use the same format as the previous release
	- Copy the release notes from `CHANGELOG.md`
	- Attach the `Roact.rbxm` built with Rojo
