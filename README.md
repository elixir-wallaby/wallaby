# Wallaby

[![Build Status](https://travis-ci.org/keathley/wallaby.svg?branch=master)](https://travis-ci.org/keathley/wallaby)
[![Hex pm](https://img.shields.io/hexpm/v/wallaby.svg?style=flat)](https://hex.pm/packages/wallaby)
[![Coverage Status](https://coveralls.io/repos/github/keathley/wallaby/badge.svg?branch=master)](https://coveralls.io/github/keathley/wallaby?branch=master)

Wallaby helps you test your web applications by simulating realistic user
interactions. By default it runs each test case concurrently and manages
browsers for you. Here's an example test for a simple Todo application:

```elixir
defmodule MyApp.Features.TodoTest do
  use MyApp.FeatureCase, async: true

  import Wallaby.Query, only: [css: 2, text_field: 1, button: 1]

  def alert(text), do: css(".alert", text: text)
  def todo(text), do: css(".todo-list > .todo", text: text)

  test "users can create todos", %{session: session} do
    session
    |> visit("/todos")
    |> fill_in(text_field("New Todo"), with: "Write my first Wallaby test")
    |> click(button("Save"))
    |> assert_has(css(".alert", text: "You created a todo"))
    |> assert_has(css(".todo-list > .todo, text: "Write my first Wallaby test"))
  end
end
```

Because Wallaby manages multiple browsers for you, its possible to test several
users interacting with a page simultaneously.

```elixir
defmodule MyApp.Features.MultipleUsersTest do
  use MyApp.FeatureCase, async: true

  import Wallaby.Query, only: [text_field: 1, button: 1, css: 2]

  @page message_path(Endpoint, :index)
  @message_field text_field("Share Message")
  @share_button button("Share")

  def message(msg), do: css(".messages > .message", text: msg)

  test "That users can send messages to each other" do
    {:ok, user1} = Wallaby.start_session
    user1
    |> visit(@page)
    |> fill_in(@message_field, with: "Hello there!")
    |> click(@share_button)

    {:ok, user2} = Wallaby.start_session
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

If you're testing a Phoenix application with Ecto 2.0 and a database that
supports sandbox mode then you can enable concurrent testing by adding the
`Phoenix.Ecto.SQL.Sandbox` plug to your `Endpoint`. It's important that
this is at the top of `endpoint.ex` before any other plugs.

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

  import Wallaby.Query, only: [css: 2]

  test "users have names", %{session: session} do
    session
    |> visit("/users")
    |> find(css(".user", count: 3))
    |> List.first()
    |> assert_has(css(".user-name", text: "Chris"))
  end
end
```

## API

The full documentation for the DSL is in the [official documentation](https://hexdocs.pm/wallaby).

### Queries and Actions

Wallaby's API is broken into 2 concepts: Queries and Actions.

Queries allow us to declaritively describe the elements that we would like to
interact with and Actions allow us to use those queries to interact with the
DOM.

Lets say that our html looks like this:

```html
<ul class=".users">
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

If we wanted to interact with all of the users then we could write a query like so
`css(".user", count: 3)`.
If we only wanted to interact with a specific user then we could write a query like this `css(".user-name",
count: 1, text: "Ada")`. Now we can use those queries with some actions:

```elixir
session
|> find(css(".user", count: 3))
|> List.first
|> assert_has(css(".user-name", count: 1, text: "Ada"))
```

There are several queries for common html elements defined in
the [Query module](https://hexdocs.pm/wallaby/Wallaby.Query.html#content). All
actions accept a query. This makes it easy to use queries we've already
defined. Actions will block until the query is either satisfied or the action times
out. Blocking reduces race conditions when elements are added or removed
dynamically.

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

Passing a callback to `find` will return the parent which makes it easy to chain
`find` with other actions:

```elixir
page
|> find(css(".users"), & assert has?(&1, css(".user", count: 3)))
|> click(link("Next Page"))
```

Without the callback `find` returns the element. This provides a way to scope
all future actions within an element.

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

If you need to send specific keys to an element, you can do that with
`send_keys`:

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

`assert_has` and `refute_has` both take a parent element as their first
argument. They return that parent, making it easy to chain them together with
other actions.

```elixir
session
|> assert_has(css(".signup-form"))
|> fill_in(text_field("Email", with: "c@keathley.io"))
|> click(button("Sign up"))
|> refute_has(css(".error"))
|> assert_has(css(".alert", text: "Welcome!"))
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

Testing asynchronous JavaScript code can expose timing issues and race
conditions. We might try to interact with an element that hasn't yet appeared on
the page. Elements can become stale while we're trying to interact with them.

Wallaby helps solve this by blocking. Instead of manually setting timeouts we
can use `assert_has` and some declarative queries to block until the DOM is in a
good state.

```elixir
session
|> click(button("Some Async Button"))
|> assert_has(css(".async-result"))
|> click(button("Next Action"))
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
