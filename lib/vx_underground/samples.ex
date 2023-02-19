defmodule VxUnderground.Samples do
  @moduledoc """
  The Samples context.
  """

  import Ecto.Query, warn: false
  alias VxUnderground.Repo

  alias VxUnderground.Samples.Sample

  @doc """
  Returns the list of samples.

  ## Examples

      iex> list_samples()
      [%Sample{}, ...]

  """
  def list_samples(opts \\ []) do
    from(s in Sample)
    |> filter(opts)
    |> sort(opts)
    |> Repo.all()
  end

  defp sort(query, %{sort_by: sort_by, sort_dir: sort_dir})
       when sort_by in [
              :id,
              :md5,
              :sha1,
              :sha256,
              :sha,
              :name,
              :Size,
              :Type,
              :"First seen",
              :"S3 object key"
            ] and
              sort_dir in [:asc, :desc] do
    sort_by =
      case sort_by do
        :Hash -> :hash
        :Size -> :size
        :Type -> :type
        :"First seen" -> :first_seen
        :"S3 object key" -> :s3_object_key
      end

    order_by(query, {^sort_dir, ^sort_by})
  end

  defp sort(query, _opts), do: query

  defp filter(query, opts) do
    query
    |> filter_by_hash(opts)
  end

  defp filter_by_hash(query, %{hash: hash})
       when is_binary(hash) and hash != "" do
    query_string = "%#{hash}%"

    where(
      query,
      [s],
      ilike(s.md5, ^query_string) or ilike(s.sha1, ^query_string) or
        ilike(s.sha256, ^query_string) or ilike(s.sha512, ^query_string)
    )
  end

  defp filter_by_hash(query, _), do: query

  @doc """
  Gets a single sample.

  Raises `Ecto.NoResultsError` if the Sample does not exist.

  ## Examples

      iex> get_sample!(123)
      %Sample{}

      iex> get_sample!(456)
      ** (Ecto.NoResultsError)

  """
  def get_sample!(id), do: Repo.get!(Sample, id)

  @doc """
  Creates a sample.

  ## Examples

      iex> create_sample(%{field: value})
      {:ok, %Sample{}}

      iex> create_sample(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_sample(attrs \\ %{}) do
    %Sample{}
    |> Sample.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a sample.

  ## Examples

      iex> update_sample(sample, %{field: new_value})
      {:ok, %Sample{}}

      iex> update_sample(sample, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_sample(%Sample{} = sample, attrs) do
    sample
    |> Sample.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a sample.

  ## Examples

      iex> delete_sample(sample)
      {:ok, %Sample{}}

      iex> delete_sample(sample)
      {:error, %Ecto.Changeset{}}

  """
  def delete_sample(%Sample{} = sample) do
    Repo.delete(sample)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking sample changes.

  ## Examples

      iex> change_sample(sample)
      %Ecto.Changeset{data: %Sample{}}

  """
  def change_sample(%Sample{} = sample, attrs \\ %{}) do
    Sample.changeset(sample, attrs)
  end
end