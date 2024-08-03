defmodule VExchange.ApiBodyReader do
  def read_body(%Plug.Conn{request_path: path} = conn, opts)
      when path in ["/api/upload", "/api/samples/new"] do
    new_opts = [read_length: 52_000_000, length: 52_000_000, read_timeout: 20_000]
    opts = Keyword.merge(opts, new_opts)

    {:ok, body, conn} =
      Plug.Conn.read_body(conn, opts)
      |> case do
        {:ok, body, conn} -> {:ok, body, conn}
        {:more, data} -> {:ok, data, conn}
        {:more, data, conn} -> {:ok, data, conn}
      end

    params = %{"file" => body}
    conn = Map.put(conn, :params, params)

    {:ok, "", conn}
  end

  def read_body(conn, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    {:ok, body, conn}
  end
end
