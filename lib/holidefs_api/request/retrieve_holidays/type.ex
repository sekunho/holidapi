defmodule HolidefsApi.Request.RetrieveHolidays.Type do

  @moduledoc """
  `RetrieveHolidays.Type` is for determining if this kind of request wants
  informal holidays to be included in the response, or if it just wants the
  formal holidays.

  This is ideally used in conjunction with `RetrieveHolidays`, specifically
  its `type` field.
  """

  use TypedStruct

  @typedoc """
  A `type` can either be informal or formal. This tags `Type.t()` with more
  information that people will be able to determine what type of request this
  is.
  """
  @type type :: {:formal, t()} | {:include_informal, t()}

  typedstruct do
    @typedoc "Used for encoding details of the `RetrieveHolidays` request."
    field :country, Holidefs.locale_code(), enforce: true
    field :from, Date.t(), enforce: true
    field :to, Date.t(), enforce: true
  end

  @doc """
  Converts a map to a type of `RetrieveHolidays` request.

  ## Examples

      iex> from(:ph, ~D[2022-01-01], ~D[2022-04-03], "formal")
      {:ok, {:formal, %Type{country: :ph, from: ~D[2022-01-01], to: ~D[2022-04-03]}}}

      iex> from(:ph, ~D[2022-01-01], ~D[2022-04-03], "include_informal")
      {:ok, {:include_informal, %Type{country: :ph, from: ~D[2022-01-01], to: ~D[2022-04-03]}}}

  ## Panics

  `from/4` will panic in the ff scenarios:
    If it doesn't match the typespec.
  """
  @spec from(
    Holidefs.locale_code(),
    Date.t(), Date.t(),
    String.t()
  ) :: {:ok, {:formal | :include_informal, t()}}
  def from(country, from_date, to_date, holiday_type) do
    type = %__MODULE__{
      country: country,
      from: from_date,
      to: to_date
    }

    case holiday_type do
      "formal" ->
        {:ok, {:formal, type}}

      "include_informal" ->
        {:ok, {:include_informal, type}}

      _ -> {:error, :invalid_holiday_type}
    end
  end
end
