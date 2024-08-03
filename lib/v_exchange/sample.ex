defmodule VExchange.Sample do
  use Ecto.Schema
  import Ecto.Changeset

  @allowed [
    :names,
    :size,
    :type,
    :first_seen,
    :s3_object_key,
    :md5,
    :sha1,
    :sha256,
    :sha512,
    :tags,
    :id
  ]

  @required []

  @derive {Jason.Encoder, only: @allowed}

  schema "samples" do
    field :first_seen, :utc_datetime
    field :names, {:array, :string}
    field :md5, :string
    field :sha1, :string
    field :sha256, :string
    field :sha512, :string
    field :s3_object_key, :string
    field :size, :integer
    field :type, :string
    field :tags, {:array, :string}

    timestamps()
  end

  @doc false
  def changeset(sample, attrs) do
    sample
    |> cast(attrs, @allowed)
    |> validate_length(:md5, is: 32)
    |> validate_length(:sha1, is: 40)
    |> validate_length(:sha256, is: 64)
    |> validate_length(:sha512, is: 128)
    |> unique_constraint(:md5)
    |> unique_constraint(:sha1, name: :samples_sha1_index)
    |> unique_constraint(:sha256)
    |> unique_constraint(:sha512)
    |> unique_constraint(:samples_pkey)
    |> validate_required(@required)
  end
end
