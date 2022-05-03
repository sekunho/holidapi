defmodule Mix.Tasks.BetweenBench do
  use Mix.Task

  alias HolidefsApi.Request.RetrieveHolidays
  alias HolidefsApi.Holidefs

  def run(_) do
    {:ok, params_1_country } = %{
      "countries" => "ph",
      "holiday_type" =>
      "include_informal",
      "start" => "2022-01-01",
      "end" => "2023-01-01"
    } |> RetrieveHolidays.from_map()

    {:ok, params_2_country} = %{
      "countries" => "ph,au",
      "holiday_type" => "include_informal",
      "start" => "2022-01-01",
      "end" => "2023-01-01"
    } |> RetrieveHolidays.from_map()

    {:ok, params_5_country} = %{
      "countries" => "ph,au,us,ca,hu",
      "holiday_type" => "include_informal",
      "start" => "2022-01-01",
      "end" => "2023-01-01"
    } |> RetrieveHolidays.from_map()

    {:ok, params_10_country} = %{
      "countries" => "br,us,hr,at,au,be,ca,ch,co,cz",
      "holiday_type" => "include_informal",
      "start" => "2022-01-01",
      "end" => "2023-01-01"
    } |> RetrieveHolidays.from_map()

    fun = fn retrieve_request ->
      {:ok, _countries_holidays} = Holidefs.between(retrieve_request)
    end

    Benchee.run(
      %{
        "naive_1" => fn -> fun.(params_1_country) end,
        "naive_2" => fn -> fun.(params_2_country) end,
        "naive_5" => fn -> fun.(params_5_country) end,
        "naive_10" => fn -> fun.(params_10_country) end,
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
