# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     HolidefsApi.Repo.insert!(%HolidefsApi.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
Holidefs.Definition.Store.all_definitions()
|> HolidefsApi.Holidefs.Db.seed()
