# Changelog

## Main

## v0.30.7

- refactor to map_intersperse by @bradhanks in https://github.com/elixir-wallaby/wallaby/pull/758
- Fix Wallaby.Element.size/1 spec by @NikitaNaumenko in https://github.com/elixir-wallaby/wallaby/pull/759
- Update README to Avoid Elixir Warning by @stratigos in https://github.com/elixir-wallaby/wallaby/pull/762
- Update README: Local Sandbox File Location by @stratigos in https://github.com/elixir-wallaby/wallaby/pull/766
- Update chrome.ex by @RicoTrevisan in https://github.com/elixir-wallaby/wallaby/pull/768
- Make Query.text/2 docs also point to assert_text/{2,3} by @s3cur3 in https://github.com/elixir-wallaby/wallaby/pull/770
- Update README: Separate Phoenix setup from Ecto by @Corkle in https://github.com/elixir-wallaby/wallaby/pull/772
- Address deprecation; prefer ExUnit.Case.register_test/6 by @vanderhoop in https://github.com/elixir-wallaby/wallaby/pull/776
- Fix newer invalid selector error from chromedriver by @mhanberg in 4f82ca82a6c417d298663ac4a996d49e1150d6f2

## v0.30.6

- fix: concurrent tests when using custom capabilities (#744)

## v0.30.5

- Workaround for chromedriver 115 regression (#740)

## v0.30.4

- Set headless and binary chromedriver opts from the `@sessions` attribute in feature tests (#736)

## v0.30.3

- Better support Chromedriver tests on machines with tons of cores

## v0.30.2

- Surface 'text' condition in css query error message (#714)
- Allow 2.0 in httpoison in version constraint (#725)
- Allow setting of optional cookie attributes (#711)

## v0.30.1 (2022-07-16)

### Fixes

- fix(chromedriver): Account for Chromium when doing the version matching (#698)

## v0.30.0 (2022-07-14)

### Breaking

- Now only supports Elixir v1.12 and higher. Please open an issue if this is too restrictive. This was done to allow us to vendor `PartitionSupervisor`, which uses functions that were introduced in v1.12, so vendoring only gets us that far.

### Fixes

- Handle errors related to Wallaby.Element more consistently #632
- Fix `refute_has` when passed a query with an invalid selector #639
- Fix ambiguity between imported Browser.tap/2 and Kernel.tap/2 #686
- Fix `remote_url` config option for selenium driver #582
- Specifying `at` now removes the default `count` of 1 #641
- Various documentation fixes/improvements
- Start a ChromeDriver for every scheduler #692
  - This may fix a long standing issue #365

## v0.29.1 (2021-09-22)

- Docs improvements #629

## v0.29.0 (2021-09-14)

- `has_css?/3` returns a boolean instead of raising. (#624)
- Updates `web_driver_client` to v0.2.0 (#625)

## v0.28.1 (2021-07-31)

- Fix async tests when using selenium and the default capabilities.
- Fixes the DependencyError message in chrome.ex (#581)

## v0.28.0 (2020-12-8)

### Breaking

- `Browser.assert_text/2` and `Browser.assert_text/3` now return the parent instead of `true` when the text was found.

### Fixes

- File uploads when using local and remote selenium servers.

### Improvements

- Added support for touch events
 - `Wallaby.Browser.touch_down/3`
 - `Wallaby.Browser.touch_down/4`
 - `Wallaby.Browser.touch_up/1`
 - `Wallaby.Browser.tap/2`
 - `Wallaby.Browser.touch_move/3`
 - `Wallaby.Browser.touch_scroll/4`
 - `Wallaby.Element.touch_down/3`
 - `Wallaby.Element.touch_scroll/3`

- Added support for getting Element size and location
  - `Wallaby.Element.size/1`
  - `Wallaby.Element.location/1`

## 0.27.0 (2020-12-4)

### Breaking

- Increases minimum Elixir version to 1.8

### Fixes

- Correctly remove stopped sessions from the internal store. [#558](https://github.com/elixir-wallaby/wallaby/pull/558)
- Ensures all sessions are closed after the test suite is over.
- Tests won't crash when side effects fail when calling the inspect protocol on an Element

## 0.26.2 (2020-06-19)

### Fixes

- Improve `Query.t()` specification to fix dialyzer warnings. Fixes [#542](https://github.com/elixir-wallaby/wallaby/issues/542)

## 0.26.1 (2020-06-17)

### Fixes

- Change Wallaby.Browser.sync_result from `@opaque` to `@type` Fixes [#540](https://github.com/elixir-wallaby/wallaby/issues/540)

## 0.26.0 (2020-06-15)

### Remove `Wallaby.Phantom`

The PhantomJS driver was deprecated in v0.25.0 because it is no longer maintained and does not implement many modern browser features.

Users are encouraged to switch to the `Wallaby.Chrome` driver, which is now the default. `Wallaby.Chrome` requires installing `chromedriver` as well as Google Chrome, both of which now come pre-installed on many CI platforms.

## 0.25.1 (2020-06-09)

### Fixes

- Add `ecto_sql` and `phoenix_ecto`

## 0.25.0 (2020-05-27)

### Deprecations

- Deprecated `Wallaby.Phantom`, please switch to `Wallaby.Chrome` or `Wallaby.Selenium`

### Breaking

- `Wallaby.Experimental.Chrome` renamed to `Wallaby.Chrome`.
- `Wallaby.Experimental.Selenium` renamed to `Wallaby.Selenium`.
- `Wallaby.Chrome` is now the default driver.

## 0.24.1 (2020-05-21)

- Compatibility fix for ChromeDriver version >= 83. Fixes [#533](https://github.com/elixir-wallaby/wallaby/issues/533)

## 0.24.0 (2020-04-15)

### Improvements

- Enables the ability to set capabilities by passing them as an option and using application configuration.
- Implements default capabilities for Selenium.
- Implements the `Wallaby.Feature` module.

#### Breaking

- Moves configuration options for using chrome headlessly, the chrome binary, and the chromedriver binary to the `:chromedriver` key in the `:wallaby` application config.
- Automatic screenshots will now only occur inside the `feature` macro.
- Removed `:create_session_fn` option from `Wallaby.Experimental.Selenium`
- Removed `:end_session_fn` option from `Wallaby.Experimental.Selenium`
- Increases the minimum Elixir version to v1.7.
- Increases the minimum Erlang version to v21.

## 0.23.0 (2019-08-14)

### Improvements

- Add ability to configure the path to the ChromeDriver executable
- Enable screenshot support for Selenium driver
- Enable `accept_alert/2`, `dismiss_alert/2`, `accept_confirm/2`, `dismiss_confirm/2`, `accept_prompt/2`, `dismiss_prompt/2` for Selenium driver
- Add `:log` option to `take_screenshot`, this is set to `true` when taking screenshots on failure
- Introduce window/tab switching support: `Browser.window_handle/1`, `Browser.window_handles/1`, `Browser.focus_window/2` and `Browser.close_window/1`
- Introduce window placement support: `Browser.window_position/1`, `Browser.move_window/3` and `Browser.maximize_window/1`
- Introduce frame switching support: `Browser.focus_frame/2`, `Browser.focus_parent_frame/1`, `Browser.focus_default_frame/1`
- Introduce async script support: `Browser.execute_script_async/2`, `Browser.execute_script_async/3`, and `Browser.execute_script_async/4`
- Introduce mouse events support: `Browser.hover/2`, `Browser.move_mouse_by/3`, `Browser.double_click/1`, `Browser.button_down/2`, `Browser.button_up/2`, and a version of `Browser.click/2` that clicks in current mouse position.

### Bugfixes

- LogStore now wraps logs in a list before attempting to pass them to List functions. This was causing Wallaby to crash and would mask actual test errors.

## 0.22.0 (2019-02-26)

### Improvements

- Add `Query.data` to find by data attributes
- Add selected conditions to query
- Add functions for query options
- Add `visible: any` option to query
- Handle Safari and Edge stale reference errors

### Bugfixes

- allow newlines in chrome logs
- Allow other versions of chromedriver
- Increase the session store genserver timeout

## 0.21.0 (2018-11-19)

### Breaking changes

- Removed `accept_dialogs` and `dismiss_dialogs`.

### Improvements

- Improved readability of `file_test` failures
- Allow users to specify the path to the chrome binary
- Add Query.value and Query.attribute
- Adds jitter to all http calls
- Returns better error messages from obscured element responses
- Option to configure default window size
- Pretty printing element html

### Bugfixes

- Chrome takes screenshots correctly if elements are passed to `take_screenshot`.
- Chrome no longer spits out errors constantly.
- Find elements that contain single quotes

## 0.20.0 (2018-04-11)

### Breaking changes

- Normalized all exception names
- Removed `set_window_size/3`

### Bugfixes

- Fixed issues with zombie phantom processes (#338)

## 0.19.2 (2017-10-28)

### Features

- Capture JavaScript logs in chrome
- Queries now take an optional `at:` argument with which you can specify which one of multiple matches you want returned

### Bugfixes

- relax httpoison dependency for easier upgrading and not locking you down
- Prevent failing if phantom jsn't installed globally
- Fix issue with zombie phantomjs processes (#224)
- Fix issue where temporary folders for phantomjs processes aren't deleted

## 0.19.1 (2017-08-13)

### Bugfixes

- Publish new release with an updated version of hex to fix file permissions.

## 0.19.0 (2017-08-08)

### Features

- Handle alerts in chromedriver - thanks @florinpatrascu

### Bugfixes

- Return the correct error message for text queries.

## 0.18.1 (2017-07-19)

### Bugfixes

- Pass correct BEAM Metadata to chromedriver to support db_connection
- Close all sessions when their parent process dies.

## 0.18.0 (2017-07-17)

### Features

- Support for chromedriver

### Bugfixes

- Capture invalid state errors

## 0.17.0 (2017-05-17)

This release removes all methods declared as _deprecated_ in the 0.16 release, experimental Selenium support and much more! If you are looking to upgrade from an earlier release, it is recommended to first go to 0.16.x.
Other goodies include improved test helpers, a cookies API and handling for JS-dialogues.

### Breaking Changes

- Removed deprecated version of `fill_in`
- Removed deprecated `check`
- Removed deprecated `set_window_size`
- Removed deprecated `send_text`
- Removed deprecated versions of `click`
- Removed deprecated `checked?`
- Removed deprecated `get_current_url`
- Removed deprecated versions of `visible?`
- Removed deprecated versions of `all`
- Removed deprecated versions of `attach_file`
- Removed deprecated versions of `clear`
- Removed deprecated `attr`
- Removed deprecated versions of `find`
- Removed deprecated versions of `text`
- Removed deprecated `click_link`
- Removed deprecated `click_button`
- Removed deprecated `choose`

### Features

- New cookie API with `cookies/1` and `set_cookie/3`
- New assert macros `assert_has/2` and `refute_has/2`
- execute_script now returns the session again and is pipable, there is an optional callback if you need access to the return value - thanks @krankin
- Phantom server is now compatible with escripts - thanks @aaronrenner
- Ability to handle JavaScript dialogs via `accept_dialogs/1`, `dismiss_dialogs/1`, plus methods for alerts, confirms and prompts - thanks @padde
- Ability to pass options for driver interaction down to the underlying hackney library through `config :wallaby, hackney_options: [your: "option"]` - thanks @aaronrenner
- Added `check_log` option to `execute_script` - thanks @aaronrenner
- Experimental support for selnium 2 and selenium 3 web drivers has been added, use at your own risk ;)
- Updated hackney and httpoison dependencies - thanks @aaronrenner
- Removed documentation for modules that aren't intended for external use - thanks @aaronrenner
- set_value now works with text fields, checkboxes, radio buttons, and
  options. - thanks @graeme-defty

### Bugfixes

- Fix spawning of phantomjs when project path contains spaces - thanks @schnittchen
- Fixed a couple of dialyzer warnings - thanks @aaronrenner
- Fixed incorrect malformed label warning when it was really a mismatch between expected elements found

## <= 0.16.1

Changelogs for these versions can be found under [releases](https://github.com/keathley/wallaby/releases)
