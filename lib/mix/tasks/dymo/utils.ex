defmodule Mix.Tasks.Dymo.Utils do
  @moduledoc false

  @spec timestamp() :: String.t()
  def timestamp() do
    %{year: year, month: month, day: day, hour: hour, minute: minute, second: second} =
      DateTime.utc_now()

    [year, month, day, hour, minute, second]
    |> Enum.map(&String.pad_leading(to_string(&1), 2, "0"))
    |> Enum.join()
  end
end
