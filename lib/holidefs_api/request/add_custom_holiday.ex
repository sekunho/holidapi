defmodule HolidefsApi.Request.AddCustomHoliday do
  @moduledoc """
  For when the user wants to add a custom holiday.

  It isn't that important to make a distinction between an informal and formal
  holiday, at least enough to use tagged tuples. That information can just exist
  in the struct's field instead.
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
    field :month, month(), enforced: true
    field :day, day(), enforced: true
    field :country, String.t(), enforced: true
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
          month: 1,
          day: 12,
          country: :ph,
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
          month: 1,
          day: 12,
          country: :nz,
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
          month: 1,
          day: 12,
          country: :us,
          year_selector: {:limited, [2022, 2010, 1990]}
        }
      }


  ## Errors

    * `{:error, :invalid_year}` - If the year is invalid
    * `{:error, :year_selector}` - If the year selector is not supported.
  """
  @spec from_map(%{
    name: String.t(),
    month: month(),
    day: day(),
    regions: [Holidefs.locale_code()],
    year_selector: %{String.t() => String.t()} | nil
  }) :: {:ok, t} | {:error, error()}
  def from_map(holidata = %{
    "name" => name,
    "month" => month,
    "day" => day,
    "country" => country
  }) do
    year_selector =
      holidata
      |> Map.get("year_selector")
      |> parse_year_selector()

    # I could parse the day and month here
    holiday = %__MODULE__{
      name: name,
      month: month,
      day: day,
      country: country,
      year_selector: :no_selector
    }

    case year_selector do
      {:ok, sel = {:after, _}} ->
        {:ok, %{holiday | year_selector: sel}}

      {:ok, sel = {:before, _year}} ->
        {:ok, %{holiday | year_selector: sel}}

      {:ok, sel = {:limited, _}} ->
        {:ok, %{holiday | year_selector: sel}}

      {:ok, :no_selector} ->
        {:ok, %{holiday | year_selector: :no_selector}}

      _ -> {:error, :invalid_year_selector}
    end
  end


  @spec get_year_selector(t) :: :after | :before | :limited | :no_selector
  def get_year_selector(%{year_selector: selector}) do
    case selector do
      {sel, _} -> sel
      :no_selector -> :no_selector
    end
  end

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


  @spec parse_year_selector(map) :: {:ok, year_selector} | {:error, error}
  defp parse_year_selector(year_selector) do
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
