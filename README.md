# holidefs-api

## Overall Thing

- [] One should be able to retrieve all the holidays of a given time range and
  country.
- [] One should be able to configure Google Calendar to retrieve the holidays
  from this service (by serving an iCal file).
- [] Plus: One should be able to add custom holidays to the service.

Consider that the main endpoint of this service would be consumed by Toggl Plan
and the holidays would be fetched every time a new part of the timeline is
accessed or the service is reloaded. Think about measures to keep the response
times as low as possible.

## Todo List

- [] Parse inputs but no such implementation for behavior yet
- [] Implement behavior (retrieving, generating ICS file, etc.)
  - [] Retrieve holidays given a time range and a list of locales
  - [] Generate ICS file
  - [] Add a custom holiday, maybe naive approach first (man this is difficult)
- [] Benchmark naive implementation
- [] Implement better version. Like cache results to get lower response times

## Get started

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).
