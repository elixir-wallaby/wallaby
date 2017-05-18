## 0.17.0 (2017-05-17)

This release removes all methods declared as _deprecated_ in the 0.16 release, experimental Selenium support and much more! If you are looking to upgrade from an earlier release, it is recommended to first go to 0.16.x.
Other goodies include improved test helpers, a cookies API and handling for JS-dialogues.


### Breaking Changes

* Removed deprecated version of `fill_in`
* Removed deprecated `check`
* Removed deprecated `set_window_size`
* Removed deprecated `send_text`
* Removed deprecated versions of `click`
* Removed deprecated `checked?`
* Removed deprecated `get_current_url`
* Removed deprecated versions of `visible?`
* Removed deprecated versions of `all`
* Removed deprecated versions of `attach_file`
* Removed deprecated versions of `clear`
* Removed deprecated `attr`
* Removed deprecated versions of `find`
* Removed deprecated versions of `text`
* Removed deprecated `click_link`
* Removed deprecated `click_button`
* Removed depreacted `choose`

### Features

* New cookie API with `cookies/1` and `set_cookie/3`
* New assert macros `assert_has/2` and `refute_has/2`
* execute_script now returns the session again and is pipable, there is an optional callback if you need access to the return value - thanks @krankin
* Phantom server is now compatible with escripts - thanks @aaronrenner
* Ability to handle JavaScript dialogs via `accept_dialogs/1`, `dismiss_dialogs/1`, plus methods for alerts, confirms and prompts - thanks @padde
* Ability to pass options for driver interaction down to the underlying hackney library through `config :wallaby, hackney_options: [your: "option"]` - thanks @aaronrenner
* Added `check_log` option to `execute_script` - thanks @aaronrenner
* Experimental support for selnium 2 and selenium 3 web drivers has been added, use at your own risk ;)
* Updated hackney and httpoison dependencies - thanks @aaronrenner
* Removed documentation for modules that aren't intended for external use - thanks @aaronrenner
* set_value now works with text fields, checkboxes, radio buttons, and
  options. - thanks @graeme-defty

### Bugfixes

* Fix spawning of phantomjs when project path contains spaces - thanks @schnittchen
* Fixed a couple of dialyzer warnings - thanks @aaronrenner
* Fixed incorrect malformed label warning when it was really a mismatch between expected elements found

## <= 0.16.1

Changelogs for these versions can be found under [releases](https://github.com/keathley/wallaby/releases)
