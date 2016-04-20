# Wallaby

[![Build Status](https://travis-ci.org/keathley/wallaby.svg?branch=master)](https://travis-ci.org/keathley/wallaby)

Wallaby helps you test your web applications by simulating user interactions. By default it runs each TestCase concurrently and manages browsers for you.

[Official Documentation](https://hexdocs.pm/wallaby)

## Features

* Intuitive DSL for interacting with pages.
* Manages multiple browser processes.
* Works with Ecto's test Sandbox.

## Setup

Add wallaby to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:wallaby, "~> 0.4.0"}]
end
```

Then ensure that Wallaby is started in your `test_helper.exs`:

```elixir
{:ok, _} = Application.ensure_all_started(:wallaby)
```

### Phoenix

If you're testing a Phoenix application with Ecto then you can enable concurrent testing by adding the `Phoenix.Ecto.SQL.Sandbox` to your `Endpoint`

**Note:** This requires Ecto v2.0.0-rc.0 or newer.

```elixir
# lib/endpoint.ex

if Application.get_env(:your_app, :sql_sandbox) do
  plug Phoenix.Ecto.SQL.Sandbox
end

# Make sure Phoenix is setup to serve endpoints
config :your_app, YourApplicaiton.Endpoint,
  server: true
```

Then in your `test_helper.exs` you can provide some configuration to Wallaby.

```elixir
# test/test_helper.exs

Application.put_env(:your_app, :sql_sandbox, true)
Application.put_env(:wallaby, :base_url, YourApplication.Endpoint.url)
```

### PhantomJS

Wallaby requires PhantomJS to work. You can install PhantomJS through NPM or your package manager of choice:

```
$ npm install -g phantomjs
```

### Writing tests

Its easiest to add Wallaby to your test suite by creating a new Case Template:

```elixir
defmodule YourApp.AcceptanceCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.DSL

      import Ecto.Model
      import Ecto.Query, only: [from: 2]
      import YourApp.Router.Helpers
    end
  end

  setup _tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(YourApp.Repo)
    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(YourApp.Repo, self())
    {:ok, session} = Wallaby.start_session(metadata: metadata)
    {:ok, session: session}
  end
end
```

Then you can write tests like so:

```elixir
defmodule YourApp.UserListTest do
  use YourApp.AcceptanceCase, async: true

  test "users have names", %{session: session} do
    first_employee =
      session
      |> visit("/users")
      |> find(".dashboard")
      |> all(".user")
      |> List.first
      |> find(".user-name")
      |> text

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

Its also possible to click links directly:

```elixir
click_link(session, "Page 1")
```

### Interacting with forms

There are many ways to interact with form elements on a page:

```elixir
fill_in(session, "First Name", with: "Chris")
fill_in(session, "#last_name_field", with: "Keathley")
choose(session, "Radio Button 1")
check(session, "Checkbox")
uncheck(session, "Checkbox")
select(session, "My Awesome Select", option: "Option 1")
click(session, "Some Button")
```

### Querying & Finding

Querying and finding is done with css selectors:

```elixir
find(session, "#some_id")
find(session, ".user", count: :any)
find(".single-item", count: 1)
all(session, ".user")
```

By default Wallaby will block until it can `find` the matching element. This can be used to keep asynchronous tests in sync (as discussed below).

### Scoping

Finders can be scoped to a specific node by chaining finds together:

```elixir
session
|> find(".user-form")
|> fill_in("User Name", with: "Chris")
```

### Windows and Screenshots

Its possible to interact with the window and take screenshots:

```elixir
set_window_size(session, 100, 100)
get_window_size(session)
take_screenshot(session)
```

All screenshots are saved to a `screenshots` directory in the directory that the tests were run in.

## Javascript applications and asynchronous code.

It can be difficult to test asynchronous javascript code. You may try to interact with an element that isn't visible on the page. Wallaby's finders try to help mitigate this problem by blocking until the element becomes visible. You can use this strategy by writing tests in this way:

```elixir
session
|> click("Some Async Button")
|> find(".async-result")
```

## Future Work

* Support other drivers (such as Selenium)
* Implement the rest of the webdriver spec.

## Contributing

Wallaby is a community project. PRs and Issues are greatly welcome.
