defmodule VExchange.FileProcessor do
  use Oban.Worker, queue: :default, max_attempts: 3

  alias VExchange.Repo
  alias VExchange.Samples.Sample
  alias VExchange.Services.S3
  import Ecto.Query

  # 10GB in bytes
  # @chunk_size 10 * 1024 * 1024 * 1024

  def perform(%Oban.Job{args: %{"start_date" => start_date, "end_date" => end_date}} = job) do
    samples = fetch_samples(start_date, end_date)
    total_samples = length(samples)

    files =
      samples
      |> Enum.with_index(1)
      |> Enum.map(fn {sample, index} ->
        # Update the job progress
        Oban.insert!(%Oban.Job{
          id: job.id,
          state: :executing,
          tags: ["progress"],
          args: %{
            start_date: start_date,
            end_date: end_date,
            progress: index / total_samples * 100
          }
        })

        S3.get_file_binary(sample.s3_object_key)
      end)

    zip_files(files, start_date, end_date)
  end

  defp fetch_samples(start_date, end_date) do
    from(s in Sample, where: s.date >= ^start_date and s.date <= ^end_date)
    |> Repo.all()
  end

  defp zip_files(files, start_date, end_date) do
    path = ~c"tmp/#{start_date}-#{end_date}.zip"

    :zip.create(path, files)
    |> case do
      {:ok, _} -> upload_zip(path)
      {:error, reason} -> {:error, reason}
    end
  end

  defp upload_zip(zip_path) do
    S3.put_object(zip_path, File.read!(zip_path), :wasabi_upload)
  end
end
