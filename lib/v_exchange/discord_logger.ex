defmodule VExchange.DiscordLogger do
  require Logger
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://discord.com/api/v10"
  plug Tesla.Middleware.JSON

  @behaviour :gen_event

  def init({__MODULE__, name}) do
    {:ok, configure(name, [])}
  end

  def handle_call({:configure, opts}, %{name: name} = state) do
    {:ok, :ok, configure(name, opts, state)}
  end

  def handle_event({_level, gl, {Logger, _, _, _}}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({level, _gl, {Logger, msg, ts, md}}, %{} = state) do
    if is_level_okay(level, state.level) do
      log_to_discord(state.channel_id, level, msg, ts, md)
    end

    {:ok, state}
  end

  def handle_event(:flush, state) do
    {:ok, state}
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  defp is_level_okay(lvl, min_level) do
    is_nil(min_level) or Logger.compare_levels(lvl, min_level) != :lt
  end

  def log_to_discord(channel_id, level, msg, ts, md) do
    # Websocket Connections timeout after 60seconds of inactivity
    inactivity_error = "(DBConnection.ConnectionError) tcp recv (idle): closed"

    if IO.iodata_to_binary(msg) |> String.slice(0..1900) |> String.contains?(inactivity_error) do
      :ok
    else
      formatted_msg = format_message(level, msg, ts, md)
      url = "/channels/#{channel_id}/messages"
      body = %{"content" => formatted_msg}

      headers = [
        {"authorization",
         "Bot #{Application.get_env(:logger, :discord) |> Keyword.get(:bot_token)}"}
      ]

      post(url, body, headers: headers)
      |> case do
        {:ok, %{status: status}} when status in 200..299 -> :ok
        {:error, reason} -> Logger.error("Error sending log to Discord: #{reason}")
        _any -> Logger.error("Error sending log to Discord")
      end
    end
  end

  def format_message(level, msg, _ts, md) do
    timestamp = DateTime.utc_now()

    source = md[:application]
    msg = IO.iodata_to_binary(msg) |> String.slice(0..1900)

    "[#{timestamp}] #{source} [#{level}] `#{msg}`"
  end

  defp configure(name, opts) do
    state = %{name: name, format: nil, level: nil, metadata: nil, metadata_filter: nil}

    configure(name, opts, state)
  end

  defp configure(name, opts, state) do
    env = Application.get_env(:logger, name, [])
    opts = Keyword.merge(env, opts)
    Application.put_env(:logger, name, opts)

    new_state = %{
      channel_id: Keyword.get(opts, :channel_id, nil),
      level: Keyword.get(opts, :level)
    }

    Map.merge(state, new_state)
  end
end
