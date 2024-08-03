defmodule VExchange.ObanJobs.FileUploader do
  use Oban.Worker,
    queue: :file_uploads,
    max_attempts: 5,
    unique: [period: :infinity, fields: [:args]]

  alias VExchange.Services.S3
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"s3_object_key" => s3_object_key, "date" => date}}) do
    case fetch_file(s3_object_key) do
      {:ok, file} ->
        upload_path = "/Daily/#{date}/#{file.filename}"

        case S3.put_object(upload_path, file.binary, :wasabi) do
          {:ok, _} ->
            # Logger.info("FileUploader - Uploaded file: #{upload_path}")
            :ok

          {:error, reason} ->
            Logger.error("FileUploader - Failed to upload file: #{upload_path} - #{reason}")
            {:error, reason}
        end

      {:error, reason} ->
        Logger.error("FileUploader - Failed to fetch file: #{s3_object_key} - #{reason}")
        {:error, reason}
    end
  end

  defp fetch_file(s3_object_key) do
    case S3.get_file_binary(s3_object_key) do
      {:ok, %{body: binary, status_code: 200}} ->
        {:ok, %{filename: s3_object_key, binary: binary}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
