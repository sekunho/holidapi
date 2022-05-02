defmodule HolidefsApi.Repo do
  use Ecto.Repo,
    otp_app: :holidefs_api,
    adapter: Ecto.Adapters.Postgres
end
