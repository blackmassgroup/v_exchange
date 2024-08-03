defmodule VExchange.Services.TriageUpload do
  @moduledoc """
  An oban job to submit uploads to Triage.
  """

  alias VExchangeWeb.SampleChannel
  alias VExchange.Services.S3

  use Oban.Worker,
    queue: :default,
    priority: 1,
    max_attempts: 2,
    unique: [period: 60]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"sample" => sample}}) do
    config_opts = S3.wasabi_config()

    with(
      {:ok, presigned_url} <-
        ExAws.Config.new(:s3, config_opts)
        |> ExAws.S3.presigned_url(:get, S3.get_wasabi_bucket(), "#{sample["sha256"]}"),
      {:ok, triage_resp} <- VExchange.Services.Triage.upload(presigned_url),
      {:ok, _hashes} <- VExchange.Services.Triage.get_sample(triage_resp["id"])
    ) do
      SampleChannel.broadcast("triage_report_complete", %{sample: sample})

      :ok
    else
      msg -> {:error, msg}
    end
  end
end
