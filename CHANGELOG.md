## 0.17.0 (unreleased)

### Features

* New cookie API with `cookies/1` and `set_cookie/3`
* New assert macros `assert_has/2` and `refute_has/2`
* execute_script now returns the session again and is pipable, there is an optional callback if you need access to the return value - thanks @krankin
* Removed deprecated version of fill_in
* Phantom server is now compatible with escripts - thanks @aaronrenner
* Ability to handle JavaScript dialogs via `accept_dialogs/1`, `dismiss_dialogs/1`, plus methods for alerts, confirms and prompts - thanks @padde
* Ability to pass options for driver interaction down to the underlying hackney library through `config :wallaby, hackney_options: [your: "option"]` - thanks @aaronrenner
* Added `check_log` option to `execute_script` - thanks @aaronrenner
* Removed `check`

### Bugfixes

* Fix spawning of phantomjs when project path contains spaces - thanks @schnittchen
* Fixed a couple of dialyzer warnings - thanks @aaronrenner

### Chores

* Updated hackney and httpoison dependencies - thanks @aaronrenner
* Removed documentation for modules that aren't intended for external use - thanks @aaronrenner
* Fixed leaking sessions in wallaby's test suite - thanks @aaronrenner
* 

## <= 0.16.1

Changelogs for these versions can be found under [releases](https://github.com/keathley/wallaby/releases)
