defmodule VExchange.ObanJobs.DailyUploader do
  use Oban.Worker
  alias VExchange.Repo
  alias VExchange.Samples.Sample
  alias VExchange.Services.S3
  import Ecto.Query

  require Logger

  # 1GB in bytes
  @chunk_size 1 * 1024 * 1024 * 1024

  def perform(_job) do
    # yesterday's date
    date = Date.utc_today() |> Date.add(-1) |> Date.to_iso8601()

    Logger.info("Starting upload process for date: #{date}")

    with {:ok, files} when files != [] <- fetch_files_for_date(date),
         :ok <- process_files_in_chunks(files, date) do
      Logger.info("Successfully completed upload process for date: #{date}")
    else
      error ->
        Logger.error("Error during upload process for date: #{date} - #{inspect(error)}")
        error
    end
  end

  defp fetch_files_for_date(date) do
    Logger.info("Fetching files for date: #{date}")

    start_datetime = Date.from_iso8601!(date) |> DateTime.new!(~T[00:00:00], "Etc/UTC")
    end_datetime = DateTime.add(start_datetime, 86400 - 1, :second)

    files =
      from(s in Sample,
        where: s.inserted_at >= ^start_datetime and s.inserted_at <= ^end_datetime
      )
      |> Repo.all()
      |> Stream.map(fn sample ->
        {:ok, %{body: binary, status_code: 200}} = S3.get_file_binary(sample.s3_object_key)

        %{
          filename: sample.s3_object_key,
          binary: binary,
          size: sample.size
        }
      end)
      |> Enum.to_list()

    Logger.info("Fetched #{length(files)} files for date: #{date}")
    {:ok, files}
  end

  defp process_files_in_chunks(files, date) do
    Enum.reduce_while(files, {[], 0}, fn file, {current_chunk, current_size} ->
      if current_size + file.size > @chunk_size do
        zip_path = create_zip(current_chunk, date)

        if zip_path do
          Logger.info("Created zip file: #{zip_path} with size #{current_size}")

          case upload_and_delete_zip(zip_path) do
            :ok ->
              Logger.info("Uploaded and deleted zip file: #{zip_path}")
              {:cont, {[file], file.size}}

            {:error, reason} ->
              Logger.error("Failed to upload or delete zip file: #{zip_path} - #{reason}")
              {:halt, {:error, reason}}
          end
        else
          {:halt, {:error, "Failed to create zip"}}
        end
      else
        {:cont, {[file | current_chunk], current_size + file.size}}
      end
    end)
    |> case do
      {:error, reason} ->
        {:error, reason}

      {remaining_files, remaining_size} when remaining_files != [] ->
        zip_path = create_zip(remaining_files, date)

        if zip_path do
          Logger.info("Created zip file: #{zip_path} with size #{remaining_size}")

          case upload_and_delete_zip(zip_path) do
            :ok ->
              Logger.info("Uploaded and deleted zip file: #{zip_path}")
              :ok

            {:error, reason} ->
              Logger.error("Failed to upload or delete zip file: #{zip_path} - #{reason}")
              {:error, reason}
          end
        else
          {:error, "Failed to create zip"}
        end

      _ ->
        :ok
    end
  end

  defp create_zip(files, date) do
    zip_path = "/tmp/#{date}-#{System.unique_integer([:positive])}.zip"

    file_list =
      Enum.map(files, fn %{filename: filename, binary: binary} -> {filename, binary} end)

    case :zip.create(zip_path, file_list, [:compressed]) do
      {:ok, _} ->
        Logger.info("Successfully created zip file: #{zip_path}")
        zip_path

      {:error, reason} ->
        Logger.error("Failed to create zip file: #{reason}")
        nil
    end
  end

  defp upload_and_delete_zip(zip_path) do
    case File.read(zip_path) do
      {:ok, binary} ->
        case S3.put_object(zip_path, binary, :vx_underground) do
          :ok ->
            File.rm(zip_path)

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
