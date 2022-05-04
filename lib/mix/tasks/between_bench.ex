defmodule Mix.Tasks.BetweenBench do
  use Mix.Task

  alias HolidefsApi.Request.RetrieveHolidays
  alias HolidefsApi.Holidefs

  def run(_) do
    {:ok, params_1} = %{
      "country" => "ph",
      "holiday_type" => "include_informal",
      "start" => "2022-01-01",
      "end" => "2022-02-01"
    } |> RetrieveHolidays.from_map()

    {:ok, params_12} = %{
      "country" => "ph",
      "holiday_type" => "include_informal",
      "start" => "2022-01-01",
      "end" => "2023-01-01"
    } |> RetrieveHolidays.from_map()

    {:ok, params_24} = %{
      "country" => "ph",
      "holiday_type" => "include_informal",
      "start" => "2021-01-01",
      "end" => "2023-01-01"
    } |> RetrieveHolidays.from_map()

    fun = fn retrieve_request ->
      {:ok, _countries_holidays} = Holidefs.between(retrieve_request)
    end

    Benchee.run(
      %{
        "holidefs_default_1" => fn -> fun.(params_1) end,
        "db_1" => fn -> fun.(params_1) end,
        "holidefs_default_12" => fn -> fun.(params_12) end,
        "db_12" => fn -> fun.(params_12) end,
        "holidefs_default_24" => fn -> fun.(params_24) end,
        "db_24" => fn -> fun.(params_24) end,
      },
      formatters: [
        Benchee.Formatters.Console,
        {Benchee.Formatters.Markdown,
          file: "benchmark/between.md",
          description: """
          """
        }
      ]
    )
  end
end
