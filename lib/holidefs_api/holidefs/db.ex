defmodule HolidefsApi.Holidefs.Db do
  import Ecto.Adapters.SQL #, only: [query: 3, query!:]
  alias HolidefsApi.Request.AddCustomHoliday

  def save_rule(request = %AddCustomHoliday{}) do
    selector_type = AddCustomHoliday.get_year_selector(request)

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
      )

    case result do
      {:ok, _} -> result
      {:error, %{postgres: %{message: "E001" <> _}}} ->
        {:error, :invalid_country_code}

      {:error, e} -> {:internal_server_error, e}
    end
  end

  @spec get_definition!(Holidefs.locale_code()) :: Holidefs.Definition.t()
  def get_definition!(locale) do
    {:ok, %{rows: [[definition]]}} =
      query(HolidefsApi.Repo, "SELECT * FROM app.get_definitions($1)", [Atom.to_string(locale)])


    to_definition(definition)
  end

  @spec to_definition(map()) :: Holidefs.Definition.t()
  defp to_definition(def_map) do
    %Holidefs.Definition{
      code: String.to_atom(def_map["code"]),
      name: def_map["name"],
      rules: Stream.map(def_map["rules"], &to_rule/1) |> Enum.to_list()
    }
  end

  defp to_rule(rule_map) do
    fname =
      if rule_map["function"] do
        String.to_atom(rule_map["function"])
      else
        nil
      end

    observed =
      if rule_map["observed"] do
        String.to_atom(rule_map["observed"])
      else
        nil
      end

    %Holidefs.Definition.Rule{
      name: rule_map["name"],
      month: rule_map["month"],
      day: rule_map["day"],
      week: rule_map["week"],
      weekday: rule_map["weekday"],
      informal?: rule_map["informal"],
      function: fname,
      function_modifier: rule_map["function_modifier"],
      regions: rule_map["regions"],
      year_ranges: rule_map["year_ranges"],
      observed: observed
    }
  end

  @doc """
  For seeding the initial definitions list. This should probably not be used, if
  not to seed the database.

  DO NOT USE IT ELSEWHERE. IT HAS NO ERROR HANDLING.
  """
  @spec seed([Holidefs.Definitions.t()]) :: nil
  def seed(definitions) do
    for definition <- definitions do
      # Insert definition
      {:ok, %{rows: [[def_id]]}} = query(
        HolidefsApi.Repo,
        """
        INSERT INTO app.definitions(code, name)
          VALUES ($1, $2)
          RETURNING definition_id
        """,
        [Atom.to_string(definition.code), definition.name]
      )
      |> IO.inspect(charlists: :as_charlists)

      # Insert all the rules under the definition
      for rule <- definition.rules do
        IO.inspect(rule)

        {selector_type, limited_val, after_val, before_val} =
          if rule.year_ranges do
            [selector] = rule.year_ranges
            [key] = Map.keys(selector)
            [val] = Map.values(selector)

            case key do
              "limited" -> {key, val, nil, nil}
              "after" -> {key, nil, val, nil}
              "before" -> {key, nil, nil, val}
              _ -> {nil, nil, nil, nil}
            end

          else
            {nil, nil, nil, nil}
          end

        {:ok, _} = query(
            HolidefsApi.Repo,
            """
            SELECT * FROM app.insert_rule(
              $1 :: BIGINT,
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
            [
              def_id,
              rule.informal?,
              rule.name,
              if rule.observed do
                Atom.to_string(rule.observed)
              else
                nil
              end,
              if rule.month == 0 do
                nil
              else
                rule.month
              end,
              rule.day,
              rule.week,
              rule.weekday,
              if rule.function do
                Atom.to_string(rule.function)
              else
                nil
              end,
              rule.function_modifier,
              selector_type,
              limited_val,
              after_val,
              before_val
            ]
          )
      end
    end

    nil
  end
end
