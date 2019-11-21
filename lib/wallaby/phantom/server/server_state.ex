defmodule Wallaby.Phantom.Server.ServerState do
  @moduledoc false

  alias Wallaby.Driver.ExternalCommand
  alias Wallaby.Driver.Utils

  @type port_number :: 0..65_535

  @type os_pid :: non_neg_integer

  @type t :: %__MODULE__{
          workspace_path: String.t(),
          port_number: port_number,
          phantom_path: String.t(),
          phantom_args: [String.t()],
          wrapper_script_port: port | nil,
          wrapper_script_os_pid: os_pid | nil,
          phantom_os_pid: os_pid | nil
        }

  defstruct [
    :workspace_path,
    :port_number,
    :phantom_path,
    :phantom_args,
    :wrapper_script_port,
    :wrapper_script_os_pid,
    :phantom_os_pid
  ]

  @type workspace_path :: String.t()

  @type new_opt ::
          {:port_number, port_number}
          | {:phantom_path, String.t()}
          | {:phantom_args, [String.t()] | String.t()}

  @spec new(workspace_path, [new_opt]) :: t
  def new(workspace_path, params \\ []) do
    %__MODULE__{
      workspace_path: workspace_path,
      port_number: Keyword.get_lazy(params, :port_number, &Utils.find_available_port/0),
      phantom_path: Keyword.get_lazy(params, :phantom_path, &Wallaby.phantomjs_path/0),
      phantom_args:
        params
        |> Keyword.get_lazy(:phantom_args, &phantom_args_from_env/0)
        |> normalize_phantomjs_args
    }
  end

  @spec base_url(t) :: String.t()
  def base_url(%__MODULE__{port_number: port_number}) do
    "http://localhost:#{port_number}/"
  end

  @spec external_command(t) :: ExternalCommand.t()
  def external_command(%__MODULE__{} = state) do
    %ExternalCommand{
      executable: state.phantom_path,
      args:
        [
          "--webdriver=#{state.port_number}",
          "--local-storage-path=#{local_storage_path(state)}"
        ] ++ state.phantom_args
    }
  end

  @spec local_storage_path(t) :: String.t()
  def local_storage_path(%__MODULE__{workspace_path: workspace_path}) do
    Path.join(workspace_path, "local_storage")
  end

  @spec wrapper_script_path(t) :: charlist
  def wrapper_script_path(%__MODULE__{workspace_path: workspace_path}) do
    workspace_path |> Path.join("wrapper") |> to_charlist
  end

  @spec phantom_args_from_env :: [String.t()] | String.t()
  defp phantom_args_from_env do
    Application.get_env(:wallaby, :phantomjs_args, "")
  end

  @spec normalize_phantomjs_args(String.t() | [String.t()]) :: [String.t()]
  defp normalize_phantomjs_args(args) when is_binary(args) do
    String.split(args)
  end

  defp normalize_phantomjs_args(args) when is_list(args), do: args
end
