defmodule Exchange.Repo.Migrations.ImportScript do
  # alias Exchange.Samples
  use Ecto.Migration

  NimbleCSV.define(MyParser, separator: ",", escape: "\"")

  def change do
    # File.stream!("import.csv")
    # |> MyParser.parse_stream()
    # |> Stream.map(fn
    #   [
    #     _id,
    #     _type,
    #     _dhash,
    #     _upload_time,
    #     _blob_name,
    #     _blob_size,
    #     _blob_type,
    #     _content,
    #     last_seen,
    #     _family,
    #     _cfg,
    #     _config_type,
    #     alt_names,
    #     _crc32,
    #     file_name,
    #     file_size,
    #     file_type,
    #     md5,
    #     sha1,
    #     sha256,
    #     sha512,
    #     _ssdeep
    #   ] ->
    #     attrs = %{
    #       first_seen: last_seen,
    #       names: [file_name | String.split(alt_names)],
    #       md5: md5,
    #       sha1: sha1,
    #       sha256: sha256,
    #       sha512: sha512,
    #       size: file_size,
    #       file_type: file_type
    #     }

    #     Exchange.Samples.create_sample(attrs)

    #   any ->
    #     {:count, Enum.count(any), any}
    # end)
    # |> Enum.to_list()
  end
end
