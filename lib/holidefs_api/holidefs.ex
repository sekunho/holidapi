defmodule HolidefsApi.Holidefs do
  @moduledoc """
  Wrapper around the `holidefs` library. This wrapper adds some conveniences
  like caching, and an alternative way to load a locale definition.
  """

  alias Holidefs, as: Holib
  alias HolidefsApi.Request.RetrieveHolidays

  @doc """
  Fetches the holidays given a retrieve request.

  The naive implementation.
  """
  @spec between(RetrieveHolidays.t())
    :: {:ok, [Holidefs.Holiday.t()]} | {:error, atom()}
  def between(%{country: country_code, from: from, to: to, opts: opts}) do
    Holib.between(
      country_code,
      from,
      to,
      &Holib.Definition.Store.get_definition/1,
      opts
    )
  end

  @doc """
  Convenience function for wrapping `Holidefs.between/5` with the DB store rather
  than the default one.
  """
  @spec between_db(RetrieveHolidays.t())
    :: {:ok, [Holidefs.Holiday.t()]} | {:error, atom()}
  def between_db(%{country: country_code, from: from, to: to, opts: opts}) do
    Holib.between(
      country_code,
      from,
      to,
      &__MODULE__.Db.get_definition!/1,
      opts
    )
  end
end
