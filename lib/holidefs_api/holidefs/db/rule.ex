defmodule HolidefsApi.Holidefs.Db.Rule do
  alias HolidefsApi.Request.AddCustomHoliday
  import Ecto.Adapters.SQL

  @doc """
  Saves a custom holiday rule to the DB.

  ## Errors

    * `{:error, _}` - For anything considered a client error
    * `[:internal_server_error, _}` - For anything my fault lol
  """
  @spec save(AddCustomHoliday.t())
    :: {:ok, any}
     | {:error, atom}
     | {:internal_server_error, struct}
  def save(request = %AddCustomHoliday{}) do

    result =
      query(
        HolidefsApi.Repo,
        """
        SELECT * FROM app.find_def_and_insert_rule(
          $1 :: TEXT,
          $2 :: BOOLEAN,
          $3 :: TEXT,
          $4 :: app.FUN_OBSERVED,
          $5 :: SMALLINT,
          $6 :: SMALLINT,
          $7 :: SMALLINT,
          $8 :: SMALLINT,
          $9 :: app.FUN,
          $10 :: INT,
          $11 :: app.YEAR_SELECTOR,
          $12 :: SMALLINT[],
          $13 :: SMALLINT,
          $14 :: SMALLINT
        )
        """,
        from_request(request)
      )

    case result do
      {:ok, _} -> result
      {:error, %{postgres: %{message: "E001" <> _}}} ->
        {:error, :invalid_country_code}

      {:error, e} -> {:internal_server_error, e}
    end
  end

  @spec from_request(any) :: [any]
  defp from_request(request) do
    selector_type = AddCustomHoliday.get_year_selector(request)

    [
      # country code
      request.country,

      # is informal
      request.informal?,

      # holiday name
      request.name,
      if request.observed do
        Atom.to_string(request.observed)
      else
        nil
      end,

      request.month,
      request.day,

      # Week
      request.week,
      request.weekday,

      # Function
      if request.function do
        Atom.to_string(request.function)
      else
        nil
      end,
      request.function_modifier,

      if selector_type == :no_selector do
        nil
      else
        Atom.to_string(selector_type)
      end,
      AddCustomHoliday.get_year_selector_value(request, :limited),
      AddCustomHoliday.get_year_selector_value(request, :after),
      AddCustomHoliday.get_year_selector_value(request, :before)
    ]
  end
end
