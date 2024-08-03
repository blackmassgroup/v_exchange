defmodule VExchange.Services.S3 do
  @doc """
  Returns the base URL for the bucket.
  """
  def get_base_url(), do: "http://#{Application.get_env(:v_exchange, :s3_host)}/"

  @doc """
  Returns the bucket name from the application config.
  """
  def get_wasabi_bucket(), do: Application.get_env(:v_exchange, :s3_bucket_name)

  @doc """
  Returns the bucket name from the application config.
  """
  def get_alibaba_bucket(), do: Application.get_env(:v_exchange, :vxu_bucket_name)

  @doc """
  Returns a binary of the file from S3.
  """
  def get_file_binary(object_key) do
    ExAws.S3.get_object(get_wasabi_bucket(), object_key) |> ExAws.request(wasabi_config())
  end

  @doc """
  Returns a presigned URL for the given object key.
  """
  def get_presigned_url(s3_object_key) do
    opts = [expires_in: 300]
    bucket = get_wasabi_bucket()
    config_opts = wasabi_config()

    ExAws.Config.new(:s3, config_opts)
    |> ExAws.S3.presigned_url(:get, bucket, s3_object_key, opts)
    |> case do
      {:ok, url} -> url
      _ -> "#"
    end
  end

  @doc """
  Config Used to upload to Alibaba
  """
  def alibaba_config() do
    host = Application.get_env(:v_exchange, :vxu_host)
    secret_access_key = Application.get_env(:v_exchange, :vxu_secret_access_key)
    access_key_id = Application.get_env(:v_exchange, :vxu_access_key_id)

    [host: host, secret_access_key: secret_access_key, access_key_id: access_key_id]
  end

  @doc """
  Config Used to Upload to Wasabi
  """
  def wasabi_config() do
    host = Application.get_env(:v_exchange, :s3_host)
    secret_access_key = Application.get_env(:v_exchange, :s3_secret_access_key)
    access_key_id = Application.get_env(:v_exchange, :s3_access_key_id)

    [host: host, secret_access_key: secret_access_key, access_key_id: access_key_id]
  end

  @doc """
  Upload an object to s3
  """
  def put_object(object_key, binary, :alibaba) do
    get_alibaba_bucket()
    |> ExAws.S3.put_object(object_key, binary)
    |> ExAws.request(alibaba_config())
  end

  def put_object(object_key, binary, :wasabi) do
    opts = [{:content_type, "application/octet-stream"}]
    config_opts = wasabi_config()

    get_wasabi_bucket()
    |> ExAws.S3.put_object(object_key, binary, opts)
    |> ExAws.request(config_opts)
  end
end
