defmodule HolidefsApi.Request.AddCustomHoliday.Month do
  @moduledoc """
  Represents a `month` holiday. e.g 1st of January of every year is New Year's
  Day.
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
  @type year_selector :: :between | :limited | :from | :until
    # :: {:between, {non_neg_integer(), non_neg_integer()}}
    #  | {:from, non_neg_integer()}
    #  | {:until, non_neg_integer()}
    #  | {:limited, [non_neg_integer()]}
    #  | :no_selector

  @typedoc "Expected reasons for why the parsing would fail."
  @type error :: :invalid_year | :invalid_year_range | :invalid_year_selector

  typedstruct do
    @typedoc """
    Has the basic information of a month day based holiday.

    You should not use this on its own. You should use `holiday_month()` instead
    since it's tagged with more information.
    """
    field :name, String.t(), enforced: true
    field :month, month(), enforced: true
    field :day, day(), enforced: true
    field :regions, [Holidefs.locale_code()], enforced: true
  end

  @doc """
  Parses the inputs into a month day based holiday.

  ## Examples

      iex> from("FooBar Day", 1, 12, [:ph], :no_selector)
      {:ok, {:no_selector, %Month{name: "FooBar Day", month: 1, day: 12, regions: [:ph]}}}

      iex> from("FooBar Day", 1, 12, [:ph], {:between, {2020, 2022}})
      {:ok, {:between, %Month{name: "FooBar Day", month: 1, day: 12, regions: [:ph]}, {2020, 2022}}}

      iex> from("FooBar Day", 1, 12, [:ph], {:foobar, {2020, 2022}})
      {:error, :invalid_year_selector}

  ## Errors

    * `{:error, :invalid_year}` - If the year is negative.
    * `{:error, :invalid_year_range}` - If the year range `{from, to}` is `from > to`.
    * `{:error, :invalid_holiday_entry}` - If the year selector is not supported.
  """
  @spec from_map(%{
    name: String.t(),
    month: month(),
    day: day(),
    regions: [Holidefs.locale_code()],
    year_selector: %{String.t() => String.t()} | nil
  }) :: {:ok, holiday_month()} | {:error, error()}
  def from_map(%{name: name,
    month: month,
    day: day,
    regions: regions,
    year_selector: year_selector = %{"type" => selector_type}
  }) do
    # TODO: Validate day of month
    holiday = %__MODULE__{
      name: name,
      month: month,
      day: day,
      regions: regions
    }

    case year_selector do
      %{"type" => "between", "range" => %{"start" => from, "end" => to}} ->
        {:ok, nil}

      # {:between, range = {from, to}} when from < to and from >= 0 ->
      #   {:ok, {:between, holiday, range}}

      # {:between, {from, to}} when from > to ->
      #   {:error, :invalid_year_range}

      # {:between, _} -> {:error, :invalid_year}

      # {:from, year} when year >= 0 ->
      #   {:ok, {:from, holiday, year}}

      # {:from, _} -> {:error, :invalid_year}

      # {:until, year} when year >= 0 ->
      #   {:ok, {:until, holiday, year}}

      # {:until, _} -> {:error, :invalid_year}

      # {:limited, years} ->
      #   if Enum.all?(years, &Kernel.>=(&1, 0)) do
      #     {:ok, {:limited, holiday, years}}
      #   else
      #     {:error, :invalid_year}
      #   end

      # :no_selector ->
      #   {:ok, {:no_selector, holiday}}

      _ -> {:error, :invalid_year_selector}
    end
  end
end
