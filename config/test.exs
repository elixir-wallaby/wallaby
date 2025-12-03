import Config

# Prevents timeouts in ExUnit
config :wallaby,
  hackney_options: [timeout: 10, recv_timeout: 10],
  tmp_dir_prefix: "wallaby_test",
  chromedriver: [
    headless: false,
    capabilities: %{
      javascriptEnabled: false,
      loadImages: false,
      version: "",
      rotatable: false,
      takesScreenshot: true,
      cssSelectorsEnabled: true,
      nativeEvents: false,
      platform: "ANY",
      unhandledPromptBehavior: "accept",
      loggingPrefs: %{
        browser: "DEBUG"
      },
      chromeOptions: %{
        args: [
          "--no-sandbox",
          "--enable-gpu",
          "window-size=1280,800",
          "--fullscreen",
          "--user-agent=Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"
        ]
      }
    }
  ]
