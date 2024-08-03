defmodule VExchange.SamplesTest do
  use VExchange.DataCase

  alias VExchange.Samples

  describe "samples" do
    alias VExchange.Sample

    import VExchange.SamplesFixtures

    @invalid_attrs %{
      first_seen: nil,
      s3_object_key: nil,
      size: nil,
      tags: ["tag"],
      type: nil,
      md5: "A STRING THATS TOO LONG TO BE A MD5"
    }

    test "list_samples/0 returns all samples" do
      sample = sample_fixture()
      assert Samples.list_samples() == [sample]
    end

    test "get_sample!/1 returns the sample with given id" do
      sample = sample_fixture()
      assert Samples.get_sample!(sample.id) == sample
    end

    test "create_sample/1 with valid data creates a sample" do
      valid_attrs = %{
        names: ["Test Name"],
        first_seen: ~U[2023-02-05 17:21:00Z],
        s3_object_key: "some new s3_object_key",
        size: 43,
        type: "some new type",
        md5: "8f1e3ebe78bf1e81b9d278dfdf278f24",
        sha1: "261ce8aa87bd3c520c577290ce3073d83509e343",
        sha256: "adf8e94bced4691aadc5b7695116929289623cd925bbf087165c6a7e6e3dd6e2",
        sha512:
          "38ae7e95990689ff4f209f765452a164ef22ce5fd805ebc185278b8aa03196b3f7e76df17da6d755d3e4cd58caae8c485e4cd01c913b91d14de68b6e701dbe81"
      }

      assert {:ok, %Sample{} = sample} = Samples.create_sample(valid_attrs)
      assert sample.first_seen == ~U[2023-02-05 17:21:00Z]
      assert sample.s3_object_key == "some new s3_object_key"
      assert sample.size == 43

      assert sample.type == "some new type"
    end

    test "create_sample/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Samples.create_sample(@invalid_attrs)
    end

    test "update_sample/2 with valid data updates the sample" do
      sample = sample_fixture()

      update_attrs = %{
        names: ["Test Name"],
        first_seen: ~U[2023-02-05 17:21:00Z],
        hash: "some updated hash",
        s3_object_key: "some updated s3_object_key",
        size: 43,
        type: "some updated type",
        md5: "",
        sha1: "",
        sha256: "",
        sha512: ""
      }

      assert {:ok, %Sample{} = sample} = Samples.update_sample(sample, update_attrs)
      assert sample.first_seen == ~U[2023-02-05 17:21:00Z]
      assert sample.s3_object_key == "some updated s3_object_key"
      assert sample.size == 43
      assert sample.type == "some updated type"
    end

    test "update_sample/2 with invalid data returns error changeset" do
      sample = sample_fixture()
      assert {:error, %Ecto.Changeset{}} = Samples.update_sample(sample, @invalid_attrs)
      assert sample == Samples.get_sample!(sample.id)
    end

    test "delete_sample/1 deletes the sample" do
      sample = sample_fixture()
      assert {:ok, %Sample{}} = Samples.delete_sample(sample)
      assert_raise Ecto.NoResultsError, fn -> Samples.get_sample!(sample.id) end
    end

    test "change_sample/1 returns a sample changeset" do
      sample = sample_fixture()
      assert %Ecto.Changeset{} = Samples.change_sample(sample)
    end
  end
end
