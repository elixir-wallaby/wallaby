# Wallaby

[![Build Status](https://travis-ci.org/keathley/wallaby.svg?branch=master)](https://travis-ci.org/keathley/wallaby)
[![Hex pm](https://img.shields.io/hexpm/v/wallaby.svg?style=flat)](https://hex.pm/packages/wallaby)
[![Coverage Status](https://coveralls.io/repos/github/keathley/wallaby/badge.svg?branch=master)](https://coveralls.io/github/keathley/wallaby?branch=master)

Wallaby helps you test your web applications by simulating user interactions. By default it runs each test case concurrently and manages browsers for you.

[Official Documentation](https://hexdocs.pm/wallaby)

## Features

* Intuitive DSL for interacting with pages.
* Manages multiple browser processes.
* Works with Ecto's test Sandbox.

## Setup

Add Wallaby to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:wallaby, "~> 0.16.1"}]
end
```

Then ensure that Wallaby is started in your `test_helper.exs`:

```elixir
{:ok, _} = Application.ensure_all_started(:wallaby)
```

### Phoenix

If you're testing a Phoenix application with Ecto then you can enable concurrent testing by adding the `Phoenix.Ecto.SQL.Sandbox` to your `Endpoint`.

**Note:** This requires Ecto v2.0.0-rc.0 or newer.

**Note 2:** It's important that this is at the top of `endpoint.ex`, before any other plugs.

```elixir
# lib/endpoint.ex

defmodule YourApp.Endpoint do
  use Phoenix.Endpoint, otp_app: :your_app

  if Application.get_env(:your_app, :sql_sandbox) do
    plug Phoenix.Ecto.SQL.Sandbox
  end
```

Make sure Phoenix is set up to serve endpoints and that the SQL sandbox is enabled:

```elixir
# config/test.exs

config :your_app, YourApplication.Endpoint,
  server: true

config :your_app, :sql_sandbox, true
```

Then in your `test_helper.exs` you can provide some configuration to Wallaby. At minimum, you need to specify a `:base_url`, so Wallaby knows how to resolve relative paths.

```elixir
# test/test_helper.exs

Application.put_env(:wallaby, :base_url, YourApplication.Endpoint.url)
```

### PhantomJS

Wallaby requires PhantomJS. You can install PhantomJS through NPM or your package manager of choice:

```
$ npm install -g phantomjs-prebuilt
```

Wallaby will use whatever PhantomJS you have installed in your path. If you need to specify a specific PhantomJS you can pass the path in the configuration:

```elixir
config :wallaby, phantomjs: "some/path/to/phantomjs"
```

You can also pass arguments to PhantomJS through the `phantomjs_args` config setting, e.g.:

```elixir
config :wallaby, phantomjs_args: "--webdriver-logfile=phantomjs.log"
```

### Writing tests

It's easiest to add Wallaby to your test suite by creating a new case template:

```elixir
defmodule YourApp.FeatureCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.DSL

      alias YourApp.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      import YourApp.Router.Helpers
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(YourApp.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(YourApp.Repo, {:shared, self()})
    end

    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(YourApp.Repo, self())
    {:ok, session} = Wallaby.start_session(metadata: metadata)
    {:ok, session: session}
  end
end
```

Then you can write tests like so:

```elixir
defmodule YourApp.UserListTest do
  use YourApp.FeatureCase, async: true

  test "users have names", %{session: session} do
    first_employee =
      session
      |> visit("/users")
      |> find(Query.css(".dashboard"))
      |> all(Query.css(".user"))
      |> List.first
      |> find(Query.css(".user-name"))
      |> Element.text

    assert first_employee == "Chris"
  end
end
```

## DSL

The full documentation for the DSL is in the [official documentation](https://hexdocs.pm/wallaby).

### Navigation

You can navigate directly to pages with `visit`:

```elixir
visit(session, "/page.html")
visit(session, user_path(Endpoint, :index, 17))
```

It's also possible to click links directly:

```elixir
click(session, Query.link("Page 1"))
```

### Querying & Finding

Queries are used to find and interact with elements through a browser (see `Wallaby.Browser`). You can create queries like so:

```elixir
Query.css(".some-css")
Query.xpath(".//input")
Query.button("Some Button")
```

These queries can then be used to find or interact with an element

```elixir
@user_form   Query.css(".user-form")
@name_field  Query.text_field("Name")
@email_field Query.text_field("Email")
@save_button Query.button("Save")

find(page, @user_form, fn(form) ->
  form
  |> fill_in(@name_field, with: "Chris")
  |> fill_in(@email_field, with: "c@keathley.io")
  |> click(@save_button)
end)
```

If a callback is passed to `find` then the `find` will return the parent and the callback can be used to interact with the element.

By default, Wallaby will block until it can find the matching element. This is used to keep asynchronous tests in sync (as discussed below).

Nodes can also be found by their inner text:

```elixir
# <div class="user">
#   <span class="name">
#     Chris K
#   </span>
# </div>

find(page, Query.css(".user", text: "Chris K"))
```

### Interacting with forms

There are a few ways to interact with form elements on a page:

```elixir
fill_in(session, Query.text_field("First Name"), with: "Chris")
clear(session, Query.text_field("last_name"))
click(session, Query.option("Some option"))
click(session, Query.button("Some Button"))
```

### Windows and Screenshots

It's possible to interact with the window and take screenshots:

```elixir
resize_window(session, 100, 100)
window_size(session)
take_screenshot(session)
```

All screenshots are saved to a `screenshots` directory in the directory that the tests were run in.

If you want to customize the screenshot directory you can pass it as a config value:

```elixir
# config/test.exs
config :wallaby, screenshot_dir: "/file/path"

# test_helper.exs
Application.put_env(:wallaby, :screenshot_dir, "/file/path")
```

### Automatic screenshots

You can automatically take screenshots on an error:

```elixir
# config/test.exs
config :wallaby, screenshot_on_failure: true

# test_helper.exs
Application.put_env(:wallaby, :screenshot_on_failure, true)
```

## JavaScript

### Asynchronous code

It can be difficult to test asynchronous JavaScript code. You may try to interact with an element that isn't visible on the page. Wallaby's finders try to help mitigate this problem by blocking until the element becomes visible. You can use this strategy by writing tests in this way:

```elixir
session
|> click(Query.button("Some Async Button"))
|> find(Query.css(".async-result"))
```

### Interacting with dialogs

Wallaby provides several ways to interact with JavaScript dialogs such as `window.alert`, `window.confirm` and `window.prompt`. To accept/dismiss all dialogs in the current session you can use `accept_dialogs` and `dismiss_dialogs`. The default behavior is equivalent to using `dismiss_dialogs`.

For more fine-grained control over individual dialogs, you can use one of the following functions:

* For `window.alert` use `accept_alert/2`
* For `window.confirm` use `accept_confirm/2` or `dismiss_confirm/2`
* For `window.prompt` use `accept_prompt/2-3` or `dismiss_prompt/2`

All of these take a function as last parameter, which must include the necessary interactions to trigger the dialog. For example:

```elixir
alert_message = accept_alert session, fn(session) ->
  click(session, Query.link("Trigger alert"))
end
```

To emulate user input for a prompt, `accept_prompt` takes an optional parameter:

```elixir
prompt_message = accept_prompt session, [with: "User input"], fn(session) ->
  click(session, Query.link("Trigger prompt"))
end
```

### JavaScript logging and errors

Wallaby captures both JavaScript logs and errors. Any uncaught exceptions in JavaScript will be re-thrown in Elixir. This can be disabled by specifying `js_errors: false` in your Wallaby config.

JavaScript logs are written to :stdio by default. This can be changed to any IO device by setting the `:js_logger` option in your Wallaby config. For instance if you want to write all JavaScript console logs to a file you could do something like this:

```elixir
{:ok, file} = File.open("browser_logs.log", [:write])
Application.put_env(:wallaby, :js_logger, file)
```

Logging can be disabled by setting `:js_logger` to `nil`.

## Config

### Adjusting timeouts

Wallaby uses [hackney](https://github.com/benoitc/hackney) under the hood, so we
offer a hook that allows you to control any hackney options you'd like to have
sent along on every request. This can be controlled with the `:hackney_options`
setting in `config.exs`.

```elixir
# default values
config :wallaby,
  hackney_options: [timeout: :infinity, recv_timeout: :infinity]

# Overriding a value
config :wallaby,
  hackney_options: [timeout: 5_000]
```

## Contributing

Wallaby is a community project. PRs and Issues are greatly welcome.

To get started and setup the project, make sure you've got Elixir 1.3+ installed and then:

```
$ mix deps.get
$ npm install -g phantomjs-prebuilt # unless you've already got PhantomJS installed
$ mix test # Make sure the tests pass!
```

Besides running the unit tests above, it is recommended to run the driver
integration tests too:

```
# Run only phantomjs integration tests
$ WALLABY_DRIVER=phantom mix test

# Run all tests (unit and all drivers)
$ mix test.all
```
