# holidefs-api

## Overall Thing

- [ ] One should be able to retrieve all the holidays of a given time range and
  country.
- [ ] One should be able to configure Google Calendar to retrieve the holidays
  from this service (by serving an iCal file).
- [ ] Plus: One should be able to add custom holidays to the service.

Consider that the main endpoint of this service would be consumed by Toggl Plan
and the holidays would be fetched every time a new part of the timeline is
accessed or the service is reloaded. Think about measures to keep the response
times as low as possible.

## Todo List

- [x] Parse inputs but no such implementation for behavior yet
- [x] Implement behavior (retrieving, generating ICS file, etc.)
    - [x] Retrieve holidays given a time range and a list of locales
    - [x] Generate ICS file
    - [x] Add a custom holiday, maybe naive approach first (man this is difficult)
- [x] Benchmark naive implementation
- [ ] Caching
  - [ ] When holidays are retrieved given a date range
      - Have to check if this requested range overlaps with any existing range that
      were cached.
    - Otherwise, just insert to the cache table.
  - [ ] When a new holiday rule is inserted
      - Check if rule applies to any of the cached date ranges. The function that
      handles this will be triggered after every insert/statement This can be done by:
          1. Converting the request into a rule (belonging to a definition)
          2. Running `year/2`, or something similar
          3. Checking if the rule applies to any of the days cached in the DB.
              - If it does, then insert the new holiday (not rule) to the cache table.
              - If it doesn't, then ignore.
- [ ] Benchmark cached implementation

## Get started

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).
