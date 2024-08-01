defmodule VExchange.Services.S3 do
  @doc """
  Returns the base URL for the bucket.
  """
  def get_base_url(), do: "http://#{Application.get_env(:v_exchange, :s3_host)}/"

  @doc """
  Returns the bucket name from the application config.
  """
  def get_bucket(), do: Application.get_env(:v_exchange, :s3_bucket_name)

  @doc """
  Returns a binary of the file from S3.
  """
  def get_file_binary(object_key) do
    ExAws.S3.get_object(get_bucket(), object_key) |> ExAws.request(default_config())
  end

  @doc """
  Returns a presigned URL for the given object key.
  """
  def get_presigned_url(s3_object_key) do
    opts = [expires_in: 300]
    bucket = get_bucket()

    config_opts = default_config()

    ExAws.Config.new(:s3, config_opts)
    |> ExAws.S3.presigned_url(:get, bucket, s3_object_key, opts)
    |> case do
      {:ok, url} -> url
      _ -> "#"
    end
  end

  def upload_config() do
    host = Application.get_env(:v_exchange, :vxu_host)
    secret_access_key = Application.get_env(:v_exchange, :vxu_secret_access_key)
    access_key_id = Application.get_env(:v_exchange, :vxu_access_key_id)

    [host: host, secret_access_key: secret_access_key, access_key_id: access_key_id]
  end

  def default_config() do
    host = Application.get_env(:v_exchange, :s3_host)
    secret_access_key = Application.get_env(:v_exchange, :s3_secret_access_key)
    access_key_id = Application.get_env(:v_exchange, :s3_access_key_id)

    [host: host, secret_access_key: secret_access_key, access_key_id: access_key_id]
  end

  @doc """
  Upload to VX-Underground
  """
  def put_object(object_key, binary, :vx_underground) do
    bucket = Application.get_env(:v_exchange, :vxu_bucket_name)

    bucket
    |> ExAws.S3.put_object(object_key, binary)
    |> ExAws.request(upload_config())
  end
end
