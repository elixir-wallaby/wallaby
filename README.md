# ![Wallaby](https://i.imgur.com/eQ1tlI3.png)

[![Actions Status](https://github.com/elixir-wallaby/wallaby/workflows/CI/badge.svg)](https://github.com/elixir-wallaby/wallaby/actions)
[![Module Version](https://img.shields.io/hexpm/v/wallaby.svg)](https://hex.pm/packages/wallaby)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/wallaby/)
[![License](https://img.shields.io/hexpm/l/wallaby.svg)](https://github.com/elixir-wallaby/wallaby/blob/master/LICENSE)

Wallaby helps you test your web applications by simulating realistic user interactions.
By default it runs each test case concurrently and manages browsers for you.
Here's an example test for a simple Todo application:

```elixir
defmodule MyApp.Features.TodoTest do
  use ExUnit.Case, async: true
  use Wallaby.Feature

  import Wallaby.Query, only: [css: 2, text_field: 1, button: 1]

  feature "users can create todos", %{session: session} do
    session
    |> visit("/todos")
    |> fill_in(text_field("New Todo"), with: "Write my first Wallaby test")
    |> click(button("Save"))
    |> assert_has(css(".alert", text: "You created a todo"))
    |> assert_has(css(".todo-list > .todo", text: "Write my first Wallaby test"))
  end
end
```

Because Wallaby manages multiple browsers for you, its possible to test several users interacting with a page simultaneously.

```elixir
defmodule MyApp.Features.MultipleUsersTest do
  use ExUnit.Case, async: true
  use Wallaby.Feature

  import Wallaby.Query, only: [text_field: 1, button: 1, css: 2]

  @page message_path(Endpoint, :index)
  @message_field text_field("Share Message")
  @share_button button("Share")

  def message(msg), do: css(".messages > .message", text: msg)

  @sessions 2
  feature "That users can send messages to each other", %{sessions: [user1, user2]} do
    user1
    |> visit(@page)
    |> fill_in(@message_field, with: "Hello there!")
    |> click(@share_button)

    user2
    |> visit(@page)
    |> fill_in(@message_field, with: "Hello yourself")
    |> click(@share_button)

    user1
    |> assert_has(message("Hello yourself"))

    user2
    |> assert_has(message("Hello there!"))
  end
end
```

Read on to see what else Wallaby can do or check out the [Official Documentation](https://hexdocs.pm/wallaby).

## Sponsors

_Your company's name and logo could be here!_

## Setup

### Requirements

Wallaby requires Elixir 1.12+ and OTP 22+.

Wallaby also requires `bash` to be installed. Generally `bash` is widely available, but it does not come pre-installed on Alpine Linux.

### Installation

Add Wallaby to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:wallaby, "~> 0.30", runtime: false, only: :test}
  ]
end
```

Configure the driver.

```elixir
# Chrome
config :wallaby, driver: Wallaby.Chrome # default

# Selenium
config :wallaby, driver: Wallaby.Selenium
```

You'll need to install the actual drivers as well.

- Chrome
  - [`chromedriver`](https://chromedriver.chromium.org/downloads)

- Selenium
  - [`selenium`](https://www.selenium.dev/downloads/)
  - [`geckodriver`](https://github.com/mozilla/geckodriver) (for Firefox) or [`chromedriver`](https://chromedriver.chromium.org/downloads) (for Chrome)

Ensure that Wallaby is started in your `test_helper.exs`:

```elixir
{:ok, _} = Application.ensure_all_started(:wallaby)
```

When calling `use Wallaby.Feature` and using Ecto, please configure your `otp_app`.

```elixir
config :wallaby, otp_app: :your_app
```

### Phoenix

Enable Phoenix to serve endpoints in tests:

```elixir
# config/test.exs

config :your_app, YourAppWeb.Endpoint,
  server: true
```

In your `test_helper.exs` you can provide some configuration to Wallaby.
At a minimum, you need to specify a `:base_url`, so Wallaby knows how to resolve relative paths.

```elixir
# test/test_helper.exs

Application.put_env(:wallaby, :base_url, YourAppWeb.Endpoint.url)
```

#### Ecto

If you're testing a Phoenix application with Ecto and a database that [supports sandbox mode](https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html), you can enable concurrent testing by adding the `Phoenix.Ecto.SQL.Sandbox` plug to your `Endpoint`.
It's important that this is at the top of `endpoint.ex` before any other plugs.

```elixir
# lib/your_app_web/endpoint.ex

defmodule YourAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :your_app

  if sandbox = Application.compile_env(:your_app, :sandbox, false) do
    plug Phoenix.Ecto.SQL.Sandbox, sandbox: sandbox
  end

  # ...

  socket("/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [:user_agent, session: @session_options]]
  )
```

It's also important to make sure the `user_agent` is passed in the `connect_info` in order to allow the database and browser session to be wired up correctly.

Then make sure sandbox is enabled:

```elixir
# config/test.exs

config :your_app, :sandbox, Ecto.Adapters.SQL.Sandbox
```

This enables the database connection to be owned by the process that is running your test, but the connection is shared to the process receiving the HTTP requests from the browser, so that the same data is visible in both processes.

If you have other resources that should be shared by both processes (e.g. expectations or stubs if using [Mox](https://hexdocs.pm/mox/Mox.html)), then you can define a custom sandbox module:

```elixir
# test/support/sandbox.ex

defmodule YourApp.Sandbox do
  def allow(repo, owner_pid, child_pid) do
    # Delegate to the Ecto sandbox
    Ecto.Adapters.SQL.Sandbox.allow(repo, owner_pid, child_pid)

    # Add custom process-sharing configuration
    Mox.allow(MyMock, owner_pid, child_pid)
  end
end
```

And update the test config to use your custom sandbox:

```elixir
# config/test.exs

config :your_app, :sandbox, YourApp.Sandbox
```

#### Assets

Assets are not re-compiled when you run `mix test`.
This can lead to confusion if you've made changes in JavaScript or CSS but tests are still failing.
There are two common ways to avoid this confusion.

##### esbuild

If you're using [`esbuild`](https://hex.pm/packages/esbuild) you can add `esbuild default` to the `test` alias in the mix config file.

```elixir
  defp aliases do
    [
      "test": [
        "esbuild default",
        "ecto.create --quiet",
        "ecto.migrate",
        "test",
      ]
    ]
  end
```

##### Webpack

The first solution is to run `webpack --mode development --watch` from the assets directory.
This will ensure that assets get recompiled after any changes.

The second solution is to add a new alias to your mix config that recompiles assets for you:

```elixir
  def project do
    [
      app: :my_app,
      version: "1.0.0",
      aliases: aliases()
    ]
  end

  defp aliases, do: [
    "test": [
      "assets.compile --quiet",
      "ecto.create --quiet",
      "ecto.migrate",
      "test",
    ],
    "assets.compile": &compile_assets/1
  ]

  defp compile_assets(_) do
    Mix.shell().cmd("cd assets && ./node_modules/.bin/webpack --mode development",
      quiet: true
    )
  end
```

This method is less error prone but it will cause a delay when starting your test suite.

#### LiveView

In order to test Phoenix LiveView (as of [version 0.17.7](https://github.com/phoenixframework/phoenix_live_view/releases/tag/v0.17.7)) with Wallaby you'll also need to add a function to each `mount/3` function in your LiveViews, or use the `on_mount` `live_session` lifecycle hook in the router:

```elixir
defmodule MyApp.Hooks.AllowEctoSandbox do
  import Phoenix.LiveView
  import Phoenix.Component

  def on_mount(:default, _params, _session, socket) do
    allow_ecto_sandbox(socket)
    {:cont, socket}
  end

  defp allow_ecto_sandbox(socket) do
    %{assigns: %{phoenix_ecto_sandbox: metadata}} =
      assign_new(socket, :phoenix_ecto_sandbox, fn ->
        if connected?(socket), do: get_connect_info(socket, :user_agent)
      end)

    Phoenix.Ecto.SQL.Sandbox.allow(metadata, Application.get_env(:your_app, :sandbox))
  end
end
```

and then including the function usage in the router:

```elixir
live_session :default, on_mount: MyApp.Hooks.AllowEctoSandbox do
  # ...
end
```

#### Umbrella Apps

If you're testing an umbrella application containing a Phoenix application for the web interface (`MyWebApp`) and a separate persistence application (`MyPersistenceApp`) using Ecto 2 or 3 with a database that supports sandbox mode, then you can use the same setup as above, with a few tweaks.

```elixir
# my_web_app/lib/endpoint.ex

defmodule MyWebApp.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_web_app

  if Application.get_env(:my_persistence_app, :sql_sandbox) do
    plug Phoenix.Ecto.SQL.Sandbox
  end
```

Make sure `MyWebApp` is set up to serve endpoints in tests and that the SQL sandbox is enabled:

```elixir
# my_web_app/config/test.exs

config :my_web_app, MyWebApp.Endpoint,
  server: true

config :my_persistence_app, :sql_sandbox, true
```

Then in `MyWebApp`'s `test_helper.exs` you can provide some configuration to Wallaby.
At minimum, you need to specify a `:base_url`, so Wallaby knows how to resolve relative paths.

```elixir
# my_web_app/test/test_helper.exs

Application.put_env(:wallaby, :base_url, MyWebApp.Endpoint.url)
```

You will also want to add `phoenix_ecto` as a dependency to `MyWebApp`:

```elixir
# my_web_app/mix.exs

def deps do
  [
    {:phoenix_ecto, "~> 3.0", only: :test}
  ]
end
```

### Writing tests

It's easiest to add Wallaby to your test suite by using the `Wallaby.Feature` module.

```elixir
defmodule YourApp.UserListTest do
  use ExUnit.Case, async: true
  use Wallaby.Feature

  feature "users have names", %{session: session} do
    session
    |> visit("/users")
    |> find(Query.css(".user", count: 3))
    |> List.first()
    |> assert_has(Query.css(".user-name", text: "Chris"))
  end
end
```

## API

The full documentation for the DSL is in the [official documentation](https://hexdocs.pm/wallaby).

### Queries and Actions

Wallaby's API is broken into 2 concepts: Queries and Actions.

Queries allow us to declaratively describe the elements that we would like to interact with and Actions allow us to use those queries to interact with the DOM.

Lets say that our html looks like this:

```html
<ul class="users">
  <li class="user">
    <span class="user-name">Ada</span>
  </li>
  <li class="user">
    <span class="user-name">Grace</span>
  </li>
  <li class="user">
    <span class="user-name">Alan</span>
  </li>
</ul>
```

If we wanted to interact with all of the users then we could write a query like so `css(".user", count: 3)`.

If we only wanted to interact with a specific user then we could write a query like this `css(".user-name", count: 1, text: "Ada")`. Now we can use those queries with some actions:

```elixir
session
|> find(css(".user", count: 3))
|> List.first
|> assert_has(css(".user-name", count: 1, text: "Ada"))
```

There are several queries for common html elements defined in the [Query module](https://hexdocs.pm/wallaby/Wallaby.Query.html#content).
All actions accept a query.
This makes it easy to use queries we've already defined.
Actions will block until the query is either satisfied or the action times out.
Blocking reduces race conditions when elements are added or removed dynamically.

### Navigation

We can navigate directly to pages with `visit`:

```elixir
visit(session, "/page.html")
visit(session, user_path(Endpoint, :index, 17))
```

It's also possible to click links directly:

```elixir
click(session, link("Page 1"))
```

### Finding

We can find a specific element or list of elements with `find`:

```elixir
@user_form   css(".user-form")
@name_field  text_field("Name")
@email_field text_field("Email")
@save_button button("Save")

find(page, @user_form, fn(form) ->
  form
  |> fill_in(@name_field, with: "Chris")
  |> fill_in(@email_field, with: "c@keathley.io")
  |> click(@save_button)
end)
```

Passing a callback to `find` will return the parent which makes it easy to chain `find` with other actions:

```elixir
page
|> find(css(".users"), & assert has?(&1, css(".user", count: 3)))
|> click(link("Next Page"))
```

Without the callback `find` returns the element.
This provides a way to scope all future actions within an element.

```elixir
page
|> find(css(".user-form"))
|> fill_in(text_field("Name"), with: "Chris")
|> fill_in(text_field("Email"), with: "c@keathley.io")
|> click(button("Save"))
```

### Interacting with forms

There are a few ways to interact with form elements on a page:

```elixir
fill_in(session, text_field("First Name"), with: "Chris")
clear(session, text_field("last_name"))
click(session, option("Some option"))
click(session, radio_button("My Fancy Radio Button"))
click(session, button("Some Button"))
```

If you need to send specific keys to an element, you can do that with `send_keys`:

```elixir
send_keys(session, ["Example", "Text", :enter])
```

### Assertions

Wallaby provides custom assertions to make writing tests easier:

```elixir
assert_has(session, css(".signup-form"))
refute_has(session, css(".alert"))
has?(session, css(".user-edit-modal", visible: false))
```

`assert_has` and `refute_has` both take a parent element as their first argument.
They return that parent, making it easy to chain them together with other actions.

```elixir
session
|> assert_has(css(".signup-form"))
|> fill_in(text_field("Email", with: "c@keathley.io"))
|> click(button("Sign up"))
|> refute_has(css(".error"))
|> assert_has(css(".alert", text: "Welcome!"))
```

### Window Size

You can set the default window size by passing in the `window_size` option into `Wallaby.start_session\1`.

```elixir
Wallaby.start_session(window_size: [width: 1280, height: 720])
```

You can also resize the window and get the current window size during the test.

```elixir
resize_window(session, 100, 100)
window_size(session)
```

### Screenshots

It's possible take screenshots:

```elixir
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

You can automatically take screenshots on an error when using the `Wallaby.Feature.feature/3` macro.

```elixir
# config/test.exs
config :wallaby, screenshot_on_failure: true

# test_helper.exs
Application.put_env(:wallaby, :screenshot_on_failure, true)
```

## JavaScript

### Asynchronous code

Testing asynchronous JavaScript code can expose timing issues and race conditions.
We might try to interact with an element that hasn't yet appeared on the page.
Elements can become stale while we're trying to interact with them.

Wallaby helps solve this by blocking.
Instead of manually setting timeouts we can use `assert_has` and some declarative queries to block until the DOM is in a good state.

```elixir
session
|> click(button("Some Async Button"))
|> assert_has(css(".async-result"))
|> click(button("Next Action"))
```

### Interacting with dialogs

Wallaby provides several ways to interact with JavaScript dialogs such as `window.alert`, `window.confirm` and `window.prompt`.

You can use one of the following functions:

- For `window.alert` use `accept_alert/2`
- For `window.confirm` use `accept_confirm/2` or `dismiss_confirm/2`
- For `window.prompt` use `accept_prompt/2-3` or `dismiss_prompt/2`

All of these take a function as last parameter, which must include the necessary interactions to trigger the dialog. For example:

```elixir
alert_message = accept_alert session, fn(session) ->
  click(session, link("Trigger alert"))
end
```

To emulate user input for a prompt, `accept_prompt` takes an optional parameter:

```elixir
prompt_message = accept_prompt session, [with: "User input"], fn(session) ->
  click(session, link("Trigger prompt"))
end
```

### JavaScript logging and errors

Wallaby captures both JavaScript logs and errors.
Any uncaught exceptions in JavaScript will be re-thrown in Elixir.
This can be disabled by specifying `js_errors: false` in your Wallaby config.

JavaScript logs are written to :stdio by default.
This can be changed to any IO device by setting the `:js_logger` option in your Wallaby config.
For instance if you want to write all JavaScript console logs to a file you could do something like this:

```elixir
{:ok, file} = File.open("browser_logs.log", [:write])
Application.put_env(:wallaby, :js_logger, file)
```

Logging can be disabled by setting `:js_logger` to `nil`.

## Configuration

### Adjusting timeouts

Wallaby uses [hackney](https://github.com/benoitc/hackney) under the hood, so we offer a hook that allows you to control any hackney options you'd like to have sent along on every request.
This can be controlled with the `:hackney_options` setting in `config.exs`.

```elixir
config :wallaby,
  hackney_options: [timeout: :infinity, recv_timeout: :infinity]

# Overriding a value
config :wallaby,
  hackney_options: [timeout: 5_000]
```

## Contributing

Wallaby is a community project. Pull Requests (PRs) and reporting issues are greatly welcome.

To get started and setup the project, make sure you've got Elixir 1.7+ installed and then:

### Development Dependencies

Wallaby requires the following tools.

- ChromeDriver
- Google Chrome
- GeckoDriver
- Mozilla Firefox
- selenium-server-standalone

```shell
# Unit tests
$ mix test

# Integration tests for all drivers
$ mix test.drivers

# Integration tests for a specific driver
$ WALLABY_DRIVER=chrome mix test
$ WALLABY_DRIVER=selenium mix test

# All tests
$ mix test.all
```
