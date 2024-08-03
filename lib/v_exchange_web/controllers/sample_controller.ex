defmodule VExchangeWeb.SampleController do
  use VExchangeWeb, :controller

  action_fallback VExchangeWeb.FallbackController

  plug VExchangeWeb.Plugs.ApiKeyValidator

  alias VExchange.Services.S3
  alias VExchange.Samples

  def show(conn, %{"sha256" => sha256}) do
    case VExchange.Samples.get_sample_by_sha256(sha256) do
      nil ->
        conn
        |> put_status(:not_found)
        |> put_view(html: VExchangeWeb.ErrorHTML, json: VExchangeWeb.ErrorJSON)
        |> render(:"404")

      sample ->
        conn
        |> put_status(:ok)
        |> render(:show, sample: sample)
    end
  end

  def create(conn, %{"file" => file} = _params) when is_binary(file) do
    # malcore_api_key =
    #   conn.assigns.current_user.malcore_api_key || System.get_env("MALCORE_API_KEY")

    # {:ok, _user} <- MalcoreRuntime.upload(malcore_api_key, sample.id)

    with params <- build_sample_params(file),
         {:ok, sample} <- Samples.create_sample(params),
         {:ok, _sample} <- S3.put_object(sample.s3_object_key, file, :wasabi) do
      conn
      |> put_status(:created)
      |> render(:show_id, sample: sample)
    else
      {:error, %Ecto.Changeset{}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(html: VExchangeWeb.ErrorHTML, json: VExchangeWeb.ErrorJSON)
        |> render(:"422")

      _ ->
        conn
        |> put_status(500)
        |> put_view(html: VExchangeWeb.ErrorHTML, json: VExchangeWeb.ErrorJSON)
        |> render(:"500")
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> put_view(html: VExchangeWeb.ErrorHTML, json: VExchangeWeb.ErrorJSON)
    |> render(:"400")
  end

  def build_sample_params(file) do
    type = "unknown"

    md5 =
      :crypto.hash(:md5, file)
      |> Base.encode16()
      |> String.downcase()

    sha1 =
      :crypto.hash(:sha, file)
      |> Base.encode16()
      |> String.downcase()

    sha256 =
      :crypto.hash(:sha256, file)
      |> Base.encode16()
      |> String.downcase()

    sha512 =
      :crypto.hash(:sha3_512, file)
      |> Base.encode16()
      |> String.downcase()

    %{
      md5: md5,
      sha1: sha1,
      sha256: sha256,
      sha512: sha512,
      type: type,
      size: byte_size(file),
      names: [sha256],
      s3_object_key: sha256,
      first_seen: DateTime.utc_now() |> DateTime.truncate(:second)
    }
  end
end
