defmodule Wallaby.Chrome.Chromedriver do
  @moduledoc false

  alias Wallaby.Chrome
  alias Wallaby.Chrome.Chromedriver.Server

  def child_spec(_arg) do
    {:ok, chromedriver_path} = Chrome.find_chromedriver_executable()
    Server.child_spec([chromedriver_path, []])
  end

  @spec wait_until_ready(timeout()) :: :ok | {:error, :timeout}
  def wait_until_ready(timeout) do
    process_name = {:via, PartitionSupervisor, {Wallaby.Chromedrivers, self()}}
    Server.wait_until_ready(process_name, timeout)
  end

  @spec base_url :: String.t()
  def base_url do
    process_name = {:via, PartitionSupervisor, {Wallaby.Chromedrivers, self()}}
    Server.get_base_url(process_name)
  end
end
