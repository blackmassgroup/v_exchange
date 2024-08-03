defmodule VExchange.QueryCache do
  use GenServer
  alias VExchange.Samples

  @ets_table_name :query_cache

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    :ets.new(@ets_table_name, [:named_table])
    refresh_value()
    {:ok, %{}}
  end

  def query_database do
    samples = Samples.quick_list_samples()

    count =
      Samples.get_sample_count!()
      |> Number.Delimit.number_to_delimited(delimiter: ",", precision: 0)

    %{samples: samples, count: count}
  end

  def refresh_value() do
    %{samples: samples, count: count} = query_database()

    create_table_if_dne()

    :ets.insert(:query_cache, {:samples, samples})
    :ets.insert(:query_cache, {:count, count})

    :ok
  end

  def update do
    GenServer.cast(__MODULE__, :update)
  end

  def handle_cast(:update, state) do
    refresh_value()

    {:noreply, state}
  end

  def handle_info(:update, state) do
    refresh_value()

    {:noreply, state}
  end

  def fetch_value do
    create_table_if_dne()

    with(
      [{:samples, samples}] <- :ets.lookup(@ets_table_name, :samples),
      [{:count, count}] <- :ets.lookup(@ets_table_name, :count)
    ) do
      %{samples: samples, count: count}
    else
      _ ->
        update()
        fetch_value()
    end
  end

  defp create_table_if_dne() do
    case :ets.whereis(@ets_table_name) do
      :undefined -> :ets.new(@ets_table_name, [:named_table])
      _ -> :ok
    end
  end
end
