defmodule Wallaby.Phantom.Server.ServerState do
  @moduledoc false

  alias Wallaby.Driver.ExternalCommand
  alias Wallaby.Driver.TemporaryPath
  alias Wallaby.Driver.Utils

  @type port_number :: 0..65_535

  @type t :: %__MODULE__{
    port_number: port_number,
    local_storage_path: String.t,
    running: boolean,
    phantom_path: String.t,
    phantom_args: [String.t],
    awaiting_url: [pid],
    phantom_port: port | nil,
  }

  defstruct [
    :port_number,
    :local_storage_path,
    :phantom_port,
    :phantom_path,
    :phantom_args,
    running: false,
    awaiting_url: []]

  @type new_opt ::
    {:port_number, port_number} |
    {:local_storage_path, String.t} |
    {:phantom_path, String.t} |
    {:phantom_args, [String.t] | String.t}

  @spec new([new_opt]) :: t
  def new(params \\ []) do
    %__MODULE__{
      port_number: Keyword.get_lazy(params, :port_number,
                                    &Utils.find_available_port/0),
      local_storage_path: Keyword.get_lazy(params, :local_storage_path,
                                    &TemporaryPath.generate/0),
      phantom_path: Keyword.get_lazy(params, :phantom_path,
                                    &Wallaby.phantomjs_path/0),
      phantom_args: params
                    |> Keyword.get_lazy(:phantom_args, &phantom_args_from_env/0)
                    |> normalize_phantomjs_args,
    }
  end

  @spec fetch_base_url(t) :: {:ok, String.t} | {:error, :not_running}
  def fetch_base_url(%__MODULE__{running: false}), do: {:error, :not_running}
  def fetch_base_url(%__MODULE__{port_number: port_number}) do
    {:ok, "http://localhost:#{port_number}/"}
  end

  @spec external_command(t) :: ExternalCommand.t
  def external_command(%__MODULE__{} = state) do
    %ExternalCommand{
      executable: state.phantom_path,
      args: [
        "--webdriver=#{state.port_number}",
        "--local-storage-path=#{state.local_storage_path}",
      ] ++ state.phantom_args
    }
  end

  @spec phantom_args_from_env :: [String.t] | String.t
  defp phantom_args_from_env do
    Application.get_env(:wallaby, :phantomjs_args, "")
  end

  @spec normalize_phantomjs_args(String.t | [String.t]) :: [String.t]
  defp normalize_phantomjs_args(args) when is_binary(args) do
    String.split(args)
  end
  defp normalize_phantomjs_args(args) when is_list(args), do: args
end
