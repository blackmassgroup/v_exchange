defmodule VExchange.ObanJobs.JobScheduler do
  @moduledoc """
  Usage:
  ```
  start_date = ~D[2023-05-13]
  VExchange.ObanJobs.JobScheduler.insert_daily_uploader_jobs()
  ```
  """
  alias VExchange.ObanJobs.DailyUploader
  require Logger

  def insert_daily_uploader_jobs(start_date) do
    end_date = Date.utc_today()

    insert_jobs(start_date, end_date)
  end

  defp insert_jobs(start_date, end_date) do
    Enum.each(Date.range(start_date, end_date), fn date ->
      args = %{"date" => Date.to_iso8601(date)}

      DailyUploader.new(args)
      |> Oban.insert!()

      Logger.info("Inserted DailyUploader job for date: #{date}")
    end)
  end
end
