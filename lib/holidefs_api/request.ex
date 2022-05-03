defmodule HolidefsApi.Request do
  @moduledoc """
  There are several requests that can be done:

  - `Request.RetrieveHolidays`: Retrieve holidays between a range.
  - `Request.AddCustomHoliday`: Add a custom holiday to the service.
  - `Request.GenerateICS`: Produces a `.ics` file.

  These actions are meant to be produced at the boundary of the application.
  Ideally, in the controller where the request data is parsed into this. The
  reason why this is the case is so that the data will be so much easier to handle
  as it travels deeper in the application.
  """
end
