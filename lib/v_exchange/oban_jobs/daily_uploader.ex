defmodule VExchange.ObanJobs.DailyUploader do
  @moduledoc """
  A module responsible for queuing file upload jobs to S3 on a daily basis.

  This module uses `Oban.Worker` to define a job that runs daily, fetching files
  that were inserted on a specified date and queuing separate jobs for uploading them to an S3 bucket.
  """

  use Oban.Worker, queue: :vxu_uploads, max_attempts: 15
  alias VExchange.Repo
  alias VExchange.Sample
  alias VExchange.ObanJobs.FileUploader
  import Ecto.Query

  require Logger

  @impl Oban.Worker

  def perform(%Oban.Job{args: %{"date" => date}}) do
    Logger.info("DailyUploader - Starting upload process for date: #{date}")

    case fetch_samples_for_date(date) do
      {:ok, []} ->
        Logger.info("DailyUploader - No files to process for date: #{date}")
        :ok

      {:ok, samples} ->
        enqueue_file_upload_jobs(samples, date)
    end
  end

  def perform(%Oban.Job{}) do
    date = Date.utc_today() |> Date.add(-1) |> Date.to_iso8601()

    case fetch_samples_for_date(date) do
      {:ok, []} ->
        Logger.info("DailyUploader - No files to process for date: #{date}")
        :ok

      {:ok, samples} ->
        enqueue_file_upload_jobs(samples, date)
    end
  end

  @doc """
  Fetches the sample IDs for a given date.

  This function retrieves all sample IDs from the database that were inserted
  on the specified date.

  ## Parameters

    - date: The date for which to fetch sample IDs, in ISO8601 format.

  ## Returns

    - {:ok, samples}: A tuple containing `:ok` and a list of samples.
  """
  def fetch_samples_for_date(date) do
    Logger.info("DailyUploader - Fetching sample ids for date: #{date}")

    start_datetime = Date.from_iso8601!(date) |> DateTime.new!(~T[00:00:00], "Etc/UTC")
    end_datetime = DateTime.add(start_datetime, 86400 - 1, :second)

    samples =
      from(s in Sample,
        where: s.inserted_at >= ^start_datetime and s.inserted_at <= ^end_datetime
      )
      |> Repo.all()

    Logger.info("DailyUploader - Fetched #{length(samples)} sample ids for date: #{date}")
    {:ok, samples}
  end

  @doc """
  Enqueues jobs to upload files for each sample.

  This function enqueues a separate Oban job for each sample to handle its file upload.

  ## Parameters

    - samples: A list of samples to process.
    - date: The date for which the files are being processed, in ISO8601 format.
  """
  def enqueue_file_upload_jobs(samples, date) do
    samples
    |> Enum.each(fn sample ->
      args = %{"s3_object_key" => sample.s3_object_key, "date" => date}

      FileUploader.new(args)
      |> Oban.insert!()
    end)
  end
end
