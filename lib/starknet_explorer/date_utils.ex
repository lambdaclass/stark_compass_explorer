defmodule StarknetExplorer.DateUtils do
  def calculate_time_difference(timestamp) do
    current_timestamp = DateTime.utc_now() |> DateTime.to_unix()
    difference = current_timestamp - timestamp

    minutes = div(difference, 60)
    hours = div(minutes, 60)
    days = div(hours, 24)

    %{minutes: rem(minutes, 60), hours: rem(hours, 24), days: days}
  end
end
