defmodule VExchangeWeb.SampleJSON do
  alias VExchange.Sample
  alias VExchange.Services.S3

  @doc """
  Renders a single user.
  """

  def show_id(%{sample: sample}), do: %{id: sample.id}
  def show(%{sample: sample}), do: data(sample)

  defp data(%Sample{} = sample) do
    %{
      first_seen: sample.first_seen,
      md5: sample.md5,
      sha1: sample.sha1,
      sha256: sample.sha256,
      sha512: sample.sha512,
      download_link: S3.get_presigned_url(sample.sha256),
      size: sample.size,
      type: sample.type,
      tags: sample.tags,
      names: sample.names
    }
  end
end
