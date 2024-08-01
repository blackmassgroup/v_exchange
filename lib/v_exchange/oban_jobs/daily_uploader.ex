defmodule VExchange.ObanJobs.DailyUploader do
  use Oban.Worker, queue: :vxu_uploads, max_attempts: 2
  alias VExchange.Repo
  alias VExchange.Samples.Sample
  alias VExchange.Services.S3
  import Ecto.Query

  require Logger

  def perform(_job) do
    date = Date.utc_today() |> Date.add(-1) |> Date.to_iso8601()

    Logger.info("DailyUploader - Starting upload process for date: #{date}")

    case fetch_samples_for_date(date) do
      {:ok, []} ->
        Logger.info("DailyUploader - No files to process for date: #{date}")
        :ok

      {:ok, samples} ->
        process_samples(samples, date)
    end
  end

  defp fetch_samples_for_date(date) do
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

  defp process_samples(samples, date) do
    Enum.reduce_while(samples, :ok, fn sample, acc ->
      case acc do
        :ok ->
          process_sample(sample, date)

        error ->
          {:halt, error}
      end
    end)
  end

  defp process_sample(sample, date) do
    case fetch_file(sample) do
      {:ok, file} ->
        case upload_file(file, date) do
          :ok ->
            {:cont, :ok}

          {:error, reason} ->
            Logger.error("DailyUploader - Failed to upload file: #{file.filename} - #{reason}")
            {:halt, {:error, reason}}
        end

      {:error, reason} ->
        Logger.error("DailyUploader - Failed to fetch file by id: #{sample.id} - #{reason}")
        {:halt, {:error, reason}}
    end
  end

  defp fetch_file(sample) do
    case S3.get_file_binary(sample.s3_object_key) do
      {:ok, %{body: binary, status_code: 200}} ->
        {:ok,
         %{
           filename: sample.s3_object_key,
           binary: binary,
           size: sample.size
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp upload_file(file, date) do
    upload_path = "/Daily/#{date}/#{file.filename}"

    case S3.put_object(upload_path, file.binary, :vx_underground) do
      {:ok, _} ->
        Logger.info("DailyUploader - Uploaded file: #{upload_path}")
        :ok

      {:error, reason} ->
        Logger.error("DailyUploader - Failed to upload file: #{upload_path} - #{reason}")
        {:error, reason}
    end
  end
end
