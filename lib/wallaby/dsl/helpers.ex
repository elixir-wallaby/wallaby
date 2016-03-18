defmodule Wallaby.DSL.Helpers do
  alias Wallaby.Session

  def take_screenshot(session) do
    image_data =
      Session.request(:get, "#{session.base_url}session/#{session.id}/screenshot")
      |> Map.get("value")
      |> :base64.decode

    path = path_for_screenshot
    File.write! path, image_data
    path
  end

  defp path_for_screenshot do
    {hour, minutes, seconds} = :erlang.time()
    {year, month, day} = :erlang.date()

    screenshot_dir = "#{File.cwd!()}/screenshots"
    File.mkdir_p!(screenshot_dir)
    "#{screenshot_dir}/#{year}-#{month}-#{day}-#{hour}-#{minutes}-#{seconds}.png"
  end
end
