defmodule Wallaby.Experimental.SeleniumTest do
  use ExUnit.Case, async: true

  alias Wallaby.Experimental.Selenium

  describe "start_session/1" do
    test "starts a selenium session with the default url" do
      session_id = "abc123"
      test_pid = self()

      create_session_fn = fn base_url, capabilities ->
        send(test_pid, {:fn_called, [base_url, capabilities]})

        {:ok, %{"sessionId" => session_id}}
      end

      {:ok, session} = Selenium.start_session(create_session_fn: create_session_fn)

      assert session == %Wallaby.Session{
               session_url: "http://localhost:4444/wd/hub/session/#{session_id}",
               url: "http://localhost:4444/wd/hub/session/#{session_id}",
               id: session_id,
               server: :none,
               driver: Wallaby.Experimental.Selenium
             }

      assert_received {:fn_called, ["http://localhost:4444/wd/hub/", %{javascriptEnabled: true}]}
    end

    # This is only here until we build a real error api for the user
    test "returns an error response as is" do
      create_session_fn = fn _, _ ->
        {:error, %HTTPoison.Error{reason: :nxdomain}}
      end

      assert {:error, %HTTPoison.Error{reason: :nxdomain}} =
               Selenium.start_session(create_session_fn: create_session_fn)
    end
  end

  describe "end_session/1" do
    test "sends the end session" do
      session = build_session()
      test_pid = self()

      end_session_fn = fn session ->
        send(test_pid, {:fn_called, session})
        :ok
      end

      assert :ok = Selenium.end_session(session, end_session_fn: end_session_fn)

      assert_received {:fn_called, ^session}
    end
  end

  defp build_session do
    session_id = random_string(24)

    %Wallaby.Session{
      session_url: "http://localhost:4444/wd/hub/session/#{session_id}",
      url: "http://localhost:4444/wd/hub/session/#{session_id}",
      id: session_id,
      driver: Wallaby.Experimental.Selenium
    }
  end

  defp random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end
end
