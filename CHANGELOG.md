## 0.23.0 (pending)

## 0.22.0 (2019-02-26)

## Improvements

* Add `Query.data` to find by data attributes
* Add selected conditions to query
* Add functions for query options
* Add `visible: any` option to query
* Handle Safari and Edge stale reference errors

## Bugfixes

* allow newlines in chrome logs
* Allow other versions of chromedriver
* Increase the session store genserver timeout

## 0.21.0 (2018-11-19)

### Breaking changes

* Removed `accept_dialogs` and `dismiss_dialogs`.

### Improvements

* Improved readability of `file_test` failures
* Allow users to specify the path to the chrome binary
* Add Query.value and Query.attribute
* Adds jitter to all http calls
* Returns better error messages from obscured element responses
* Option to configure default window size
* Pretty printing element html

## Bugfixes

* Chrome takes screenshots correctly if elements are passed to `take_screenshot`.
* Chrome no longer spits out errors constantly.
* Find elements that contain single quotes

## 0.20.0 (2018-04-11)

### Breaking changes

* Normalized all exception names
* Removed `set_window_size/3`

### Bugfixes

* Fixed issues with zombie phantom processes (#338)

## 0.19.2 (2017-10-28)

### Features
* Capture JavaScript logs in chrome
* Queries now take an optional `at:` argument with which you can specify which one of multiple matches you want returned

### Bugfixes

* relax httpoison dependency for easier upgrading and not locking you down
* Prevent failing if phantom jsn't installed globally
* Fix issue with zombie phantomjs processes (#224)
* Fix issue where temporary folders for phantomjs processes aren't deleted

## 0.19.1 (2017-08-13)

### Bugfixes

* Publish new release with an updated version of hex to fix file permissions.

## 0.19.0 (2017-08-08)

### Features

* Handle alerts in chromedriver - thanks @florinpatrascu

### Bugfixes

* Return the correct error message for text queries.

## 0.18.1 (2017-07-19)

### Bugfixes

* Pass correct BEAM Metadata to chromedriver to support db_connection
* Close all sessions when their parent process dies.

## 0.18.0 (2017-07-17)

### Features

* Support for chromedriver

### Bugfixes

* Capture invalid state errors

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
