# Contributing to Horror Simulator
Thanks for contributing to Horror Simulator! This guide has a few tips and guidelines to make contributing to the project as easy as possible.

## Bug Reports
Any bugs (or things that look like bugs) can be reported on the [GitHub issue tracker](https://github.com/pluviolithic/horror-simulator/issues)

Make sure you check to see if someone has already reported your bug first!

## Working on Horror Simulator
To get started working on Horror Simulator, you'll need:
* Git
* [Wally](https://github.com/UpliftGames/wally)
* [StyLua](https://github.com/JohnnyMorganz/StyLua)
* [Selene](https://github.com/Kampfkarren/selene)

The `setup` make target will automatically install and configure all of them via aftman.
```sh
git clone https://github.com/pluviolithic/horror-simulator/
cd horror-simulator
make setup
```

### Pull Requests
Before starting a pull request, open an issue about the feature or bug. This helps us prevent duplicated and wasted effort. These issues are a great place to ask for help if you run into problems!

Before you submit a new pull request, check:
* Code Quality: Run [Selene](https://github.com/Kampfkarren/selene) on your code, no warnings allowed!
* Code Style: Run [StyLua](https://github.com/JohnnyMorganz/StyLua) on your code so it's formatted to follow the Roblox Lua Style Guide

### Code Style
Try to match the existing code style! In short:

* Tabs for indentation
* Double quotes
* One statement per line

Use StyLua to automatically format your code to comply with the Roblox Lua Style Guide.
You can run this tool manually from the commandline (`stylua -c src/`), or use one of StyLua's editor integrations.
