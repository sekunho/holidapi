defmodule HolidefsApi.Request.AddCustomHoliday do
  @moduledoc """
  For when the user wants to add a custom holiday.

  The way this is used in the server is as follows:

      POST /api/holidays/:country_code
        -> HolidayController.create
        -> AddCustomHoliday.from_map
        -> Db.save_rule

  This module has the things necessary to parse the request parameters into
  something more structured, which can then be used for things further in the
  application. In this case, persisting the rule in the DB.
  """

  use TypedStruct

  @typedoc """
  Represents a month number. 1 - January up to 12 - December.
  """
  @type month :: 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12

  @typedoc """
  Represents a day number of a month. You probably can't rely on this entirely,
  and this requires some further checking if the day is actually a valid one in
  the month.
  """
  @type day  :: 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15
    | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 | 27 | 28 | 29 | 30
    | 31

  @typedoc """
  Tags a month holiday with more information. `mday`-based holidays can have
  different year "ranges" or selectors:

    1. `{:between, t(), {integer(), integer()}}` where the former `integer()`
    precedes the latter.
    2. `{:from, t(), integer()}` where `integer()` represents the starting year
    of when that holiday was introduced, until perpetuity.
    3. `{:until, t(), integer()}` where `integer()` represents the ending year for
    that holiday.
    4. `{:limited, t(), [integer()]}` where `[integer()]` is a list of years that
    this holiday is a thing.

  You can read more about it here:
  https://github.com/holidays/definitions/blob/master/doc/SYNTAX.md#year-ranges
  """
  @type holiday_month
    :: {:between, t(), {non_neg_integer(), non_neg_integer()}}
     | {:from, t(), non_neg_integer()}
     | {:until, t(), non_neg_integer()}
     | {:limited, t(), [non_neg_integer()]}
     | {:no_selector, t()}

   @typedoc """
   Defines a year selector that can be used to further define a holiday. This
   is based on the holidays/definitions document.
   https://github.com/holidays/definitions/blob/master/doc/SYNTAX.md#year-ranges
   """
  @type year_selector
    :: {:after, non_neg_integer()}
     | {:before, non_neg_integer()}
     | {:limited, [non_neg_integer()]}
     | :no_selector
     # Not supported by `holidefs`
     # | {:between, {non_neg_integer(), non_neg_integer()}}

  @typedoc "Expected reasons for why the parsing would fail."
  @type error :: :invalid_year | :invalid_year_selector

  typedstruct do
    @typedoc """
    Has the basic information of a month day based holiday.

    You should not use this on its own. You should use `holiday_month()` instead
    since it's tagged with more information.
    """
    field :name, String.t(), enforced: true
    field :country, String.t(), enforced: true

    field :observed, atom()
    field :informal?, boolean(), enforced: true

    field :month, month()
    field :day, day()

    field :week, non_neg_integer()
    field :weekday, non_neg_integer()

    field :function, atom()
    field :function_modifier, integer()

    field :year_selector, year_selector, enforced: true

  end

  @doc """
  Parses the inputs into a month day based holiday. It only supports the
  selectors `limited`, `after`, and `before`. It doesn't seem like `holidefs`
  supports `between`.

  ## Examples

  Holiday that takes place every year after 1990 (inclusive).

      iex> from_map(%{
      ...>  "country" => "ph",
      ...>  "day" => 12,
      ...>  "month" => 1,
      ...>  "name" => "FooBar Day",
      ...>  "year_selector" => %{"type" => "after", "year" => 1990}
      ...> })
      {
        :ok,
        %AddCustomHoliday{
          name: "FooBar Day",
          informal?: false,
          month: 1,
          day: 12,
          country: "ph",
          year_selector: {:after, 1990}
        }
      }


  Holiday that takes place every year before 2022 (inclusive).

      iex> from_map(%{
      ...>  "country" => "nz",
      ...>  "day" => 12,
      ...>  "month" => 1,
      ...>  "name" => "FooBar Day",
      ...>  "year_selector" => %{"type" => "before", "year" => 2022}
      ...> })
      {
        :ok,
        %AddCustomHoliday{
          name: "FooBar Day",
          informal?: false,
          month: 1,
          day: 12,
          country: "nz",
          year_selector: {:before, 2022}
        }
      }


  Holiday that occurs in limited years.

      iex> from_map(%{
      ...>  "country" => "us",
      ...>  "day" => 12,
      ...>  "month" => 1,
      ...>  "name" => "FooBar Day",
      ...>  "year_selector" => %{"type" => "limited", "years" => [1990, 2010, 2022]}
      ...> })
      {
        :ok,
        %AddCustomHoliday{
          name: "FooBar Day",
          informal?: false,
          month: 1,
          day: 12,
          country: "us",
          year_selector: {:limited, [2022, 2010, 1990]}
        }
      }


  You can specify a function & a function modifier (to offset the result
  of said function). The following occurs on years 1990, 2010, and 2022 four
  days before Easter Day.

      iex> from_map(%{
      ...>   "country" => "us",
      ...>   "month" => nil,
      ...>   "name" => "FooBar Day",
      ...>   "year_selector" => %{"type" => "limited", "years" => [1990, 2010, 2022]},
      ...>   "function" => "easter",
      ...>   "function_modifier" => -4
      ...> })
      {
        :ok,
        %AddCustomHoliday{
          name: "FooBar Day",
          country: "us",
          observed: nil,
          informal?: false,
          month: nil,
          day: nil,
          week: nil,
          weekday: nil,
          function: :easter,
          function_modifier: -4,
          year_selector: {:limited, [2022, 2010, 1990]}
        }
      }


  You can also specify a function for the holiday's observed date.

      iex> from_map(%{
      ...>   "country" => "us",
      ...>   "month" => 1,
      ...>   "day" => 12,
      ...>   "name" => "FooBar Day",
      ...>   "observed" => "closest_monday"
      ...> })
      {
        :ok,
        %AddCustomHoliday{
          name: "FooBar Day",
          country: "us",
          observed: :closest_monday,
          informal?: false,
          month: 1,
          day: 12,
          week: nil,
          weekday: nil,
          function: nil,
          function_modifier: nil,
          year_selector: :no_selector
        }
      }

  ## Errors

    * `{:error, :invalid_year}` - If the year is invalid
    * `{:error, :invalid_year_selector}` - If the year selector is not supported.
    * `{:error, :invalid_observed_function}` - If the observed function does not exist.
    * `{:error, :function_modifier_should_be_nil}` - If `function` is nil but `function_modifier` isn't.
    * `{:error, :invalid_function}` - If the function is not valid (doesn't exist).
    * `{:error, :invalid_function_modifier}` - If the modifier is not an integer.
    * `{:error, :invalid_function_and_modifier}` - If both are wrong.
  """
  @spec from_map(map) :: {:ok, t} | {:error, error()}
  def from_map(holidata = %{
    "name" => name,
    "country" => country
  }) do
    with {:ok, {month, month_day}} <- parse_month(holidata),
         {:ok, informal?} <- parse_formality(holidata),
         {:ok, {week, weekday}} <- parse_week(holidata),
         {:ok, {function, function_modifier}} <- parse_function(holidata),
         {:ok, observed} <- parse_observed(holidata),
         {:ok, year_selector} <- parse_year_selector(holidata) do
      holiday = %__MODULE__{
        name: name,
        country: country,
        observed: observed,
        informal?: informal?,
        month: month,
        day: month_day,
        week: week,
        weekday: weekday,
        function: function,
        function_modifier: function_modifier,
        year_selector: year_selector
      }

      {:ok, holiday}
    else
      e -> e
    end
  end

  @doc """
  A convenience function that gets the year selector of an `%AddCustomHoliday{}`.

  ## Examples

      iex> %{
      ...>   "name" => "Foo",
      ...>   "country" => "nz",
      ...>   "month" => 1,
      ...>   "day" => 12,
      ...>   "year_selector" => %{"type" => "after", "year" => 2020}
      ...> }
      ...> |> from_map()
      ...> |> elem(1)
      ...> |> get_year_selector()
      :after

      iex> %{
      ...>   "name" => "Foo",
      ...>   "country" => "nz",
      ...>   "month" => 1,
      ...>   "day" => 12,
      ...>   "year_selector" => %{"type" => "before", "year" => 2020}
      ...> }
      ...> |> from_map()
      ...> |> elem(1)
      ...> |> get_year_selector()
      :before

      iex> %{
      ...>   "name" => "Foo",
      ...>   "country" => "nz",
      ...>   "month" => 1,
      ...>   "day" => 12,
      ...>   "year_selector" => %{"type" => "limited", "years" => [2020, 2021]}
      ...> }
      ...> |> from_map()
      ...> |> elem(1)
      ...> |> get_year_selector()
      :limited

      iex> %{
      ...>   "name" => "Foo",
      ...>   "country" => "nz",
      ...>   "month" => 1,
      ...>   "day" => 12,
      ...> }
      ...> |> from_map()
      ...> |> IO.inspect()
      ...> |> elem(1)
      ...> |> get_year_selector()
      :no_selector
  """
  @spec get_year_selector(t) :: :after | :before | :limited | :no_selector
  def get_year_selector(%{year_selector: selector}) do
    case selector do
      {sel, _} -> sel
      :no_selector -> :no_selector
    end
  end

  @doc """
  A convenience function that gets the year selector's value of an
  `%AddCustomHoliday{}`. If the selector doesn't exist, it returns `nil`.

  ## Examples

  After

      iex> %{
      ...>   "name" => "Foo",
      ...>   "country" => "nz",
      ...>   "month" => 1,
      ...>   "day" => 12,
      ...>   "year_selector" => %{"type" => "after", "year" => 2020}
      ...> }
      ...> |> from_map()
      ...> |> elem(1)
      ...> |> get_year_selector_value(:after)
      2020


  Before

      iex> %{
      ...>   "name" => "Foo",
      ...>   "country" => "nz",
      ...>   "month" => 1,
      ...>   "day" => 12,
      ...>   "year_selector" => %{"type" => "before", "year" => 2020}
      ...> }
      ...> |> from_map()
      ...> |> elem(1)
      ...> |> get_year_selector_value(:before)
      2020


  Non-existent selector

      iex> %{
      ...>   "name" => "Foo",
      ...>   "country" => "nz",
      ...>   "month" => 1,
      ...>   "day" => 12,
      ...>   "year_selector" => %{"type" => "before", "year" => 2020}
      ...> }
      ...> |> from_map()
      ...> |> elem(1)
      ...> |> get_year_selector_value(:after)
      nil
  """
  @spec get_year_selector_value(t, :after | :before | :limited | :no_selector)
    :: [non_neg_integer()] | non_neg_integer() | nil
  def get_year_selector_value(%{year_selector: year_range}, selector) do
    case year_range do
      {year_selector, year} ->
        if year_selector == selector do
          year
        else
          nil
        end

      :no_selector -> nil
    end
  end


  # HELPER FUNCTIONS FOR PARSING PARAMS INTO `AddCustomHoliday`

  @spec parse_formality(map) :: {:ok, boolean()} | {:error, :not_a_boolean}
  defp parse_formality(holidata) do
    informal? = Map.get(holidata, "informal", false)

    case informal? do
      true -> {:ok, true}
      false -> {:ok, false}
      _ -> {:error, :not_a_boolean}
    end
  end

  @spec parse_month(map) :: {:ok, {month(), day()}} | {:error, atom()}
  defp parse_month(holidata) do
    month = Map.get(holidata, "month")
    day = Map.get(holidata, "day")

    cond do
      month > 0 && month <= 12 && day >= 1 && day <= 31 ->
        {:ok, {month, day}}

      month > 0 && month <= 12 && day == nil ->
        {:ok, {month, day}}

      month == nil && day == nil ->
        {:ok, {month, day}}

      month == nil && day != nil ->
        {:error, :day_should_be_nil}

      month <= 0 || month > 12 ->
        {:error, :invalid_month}

      day <= 0 || day > 31 ->
        {:error, :invalid_day}
    end
  end

  @observed ["closest_monday", "next_week", "previous_friday",
    "to_following_monday_if_not_monday", "to_monday_if_sunday",
    "to_monday_if_weekend", "to_tuesday_if_sunday_or_monday_if_saturday",
    "to_weekday_if_boxing_weekend", "to_weekday_if_weekend"]
  defp parse_observed(holidata) do
    observed = Map.get(holidata, "observed")

    cond do
      observed == nil -> {:ok, nil}
      observed in @observed -> {:ok, String.to_atom(observed)}
      true -> {:error, :invalid_observed_function}
    end
  end

  @functions ["to_monday_if_weekend", "fi_pyhainpaiva", "se_alla_helgons_dag",
     "qld_labour_day_may", "pl_trzech_kroli_informal", "christmas_eve_holiday",
     "ch_ge_jeune_genevois", "ph_heroes_day", "easter", "election_day",
     "to_weekday_if_boxing_weekend_from_year", "se_midsommardagen", "rosh_hashanah",
     "yom_kippur", "afl_grand_final", "ch_vd_lundi_du_jeune_federal",
     "orthodox_easter", "may_pub_hol_sa", "georgia_state_holiday",
     "pl_trzech_kroli", "day_after_thanksgiving", "de_buss_und_bettag",
     "fi_juhannusaatto", "qld_labour_day_october", "hobart_show_day",
     "march_pub_hol_sa", "lee_jackson_day", "ch_gl_naefelser_fahrt",
     "fi_juhannuspaiva", "qld_queens_bday_october",
     "to_weekday_if_boxing_weekend_from_year_or_to_tuesday_if_monday",
     "qld_queens_birthday_june", "ca_victoria_day", "us_inauguration_day",
     "to_weekday_if_weekend", "g20_day_2014_only"]

  defp parse_function(holidata) do
    function = Map.get(holidata, "function")
    function_modifier = Map.get(holidata, "function_modifier")

    cond do
      function == nil && function_modifier == nil ->
        {:ok, {nil, nil}}

      function == nil && function_modifier != nil ->
        {:error, :function_modifier_should_be_nil}

      function in @functions && is_integer(function_modifier) ->
        {:ok, {String.to_atom(function), function_modifier}}

      function not in @functions && is_integer(function_modifier) ->
        {:error, :invalid_function}

      function in @functions && not is_integer(function_modifier) ->
        {:error, :invalid_function_modifier}

      true ->
        {:error, :invalid_function_and_modifier}
    end
  end

  defp parse_week(holidata) do
    week = Map.get(holidata, "week")
    weekday = Map.get(holidata, "weekday")

    {:ok, {week, weekday}}
  end

  @spec parse_year_selector(t()) :: {:ok, year_selector} | {:error, error}
  defp parse_year_selector(holidata) do
    year_selector = Map.get(holidata, "year_selector")

    case year_selector do
      %{"years" => years, "type" => "limited"} when is_list(years) ->
        years =
          years
          |> Enum.map(&parse_year/1)
          |> seq()

        case years do
          {:ok, years} -> {:ok, {:limited, years}}
          e = {:error, _} -> e
        end

      %{"year" => year, "type" => type} when type in ["after", "before"] ->
        case parse_year(year) do
          {:ok, year} -> {:ok, {String.to_atom(type), year}}
          e = {:error, _} -> e
        end

      nil -> {:ok, :no_selector}
      _ -> {:error, :invalid_year_selector}
    end
  end

  @spec seq([{:ok, any} | {:error, atom}]) :: {:ok, [any]} | {:error, atom}
  defp seq(list) do
    Enum.reduce_while(list, {:ok, []}, fn el, {:ok, acc_list} ->
      case el do
        {:ok, el} -> {:cont, {:ok, [el | acc_list]}}
        {:error, _} -> {:halt, el}
      end
    end)
  end

  defp parse_year(year) do
    case Date.from_iso8601("#{year}-01-01") do
      {:ok, date} -> {:ok, date.year}
      {:error, _} -> {:error, :invalid_year}
    end
  end
end
