defmodule ExchangeWeb.SampleController do
  use ExchangeWeb, :controller

  action_fallback ExchangeWeb.FallbackController

  plug ExchangeWeb.Plugs.ApiKeyValidator

  require Logger

  alias Exchange.Samples

  def show(conn, %{"sha256" => sha256}) do
    case Exchange.Samples.get_sample_by_sha256(sha256) do
      nil ->
        conn
        |> put_status(:not_found)
        |> put_view(html: ExchangeWeb.ErrorHTML, json: ExchangeWeb.ErrorJSON)
        |> render(:"404")

      sample ->
        conn
        |> put_status(:ok)
        |> render(:show, sample: sample)
    end
  end

  def create(conn, %{"file" => %Plug.Upload{path: path, filename: filename}} = _params) do
    case File.read(path) do
      {:ok, file} ->
        user_id = conn.assigns.current_user.id

        Samples.create_from_binary(%{"file" => file, "filename" => filename}, user_id)
        |> case do
          {:ok, sample} ->
            conn
            |> put_status(:created)
            |> render(:show_id, sample: sample)

          {:error, :too_large} ->
            conn
            |> put_status(:request_entity_too_large)
            |> put_view(json: ExchangeWeb.ErrorJSON)
            |> render(:"413")

          {:error, :duplicate} ->
            conn
            |> put_status(:conflict)
            |> put_view(json: ExchangeWeb.ErrorJSON)
            |> render(:"409")

          err ->
            "SampleController.create - User: #{inspect(conn.assigns.current_user.email)} - create_from_binary: #{inspect(err)}"
            |> Logger.error()

            conn
            |> put_status(500)
            |> put_view(json: ExchangeWeb.ErrorJSON)
            |> render(:"500")
        end

      err ->
        "SampleController.create - User: #{inspect(conn.assigns.current_user.email)} - Couldn't read file: #{inspect(err)}"
        |> Logger.error()

        conn
        |> put_view(html: ExchangeWeb.ErrorHTML, json: ExchangeWeb.ErrorJSON)
        |> render(:"500")
    end
  end

  def create(conn, params) do
    "SampleController.create - User: #{inspect(conn.assigns.current_user.email)} - Invalid params: #{inspect(params) |> String.slice(0, 100)}"
    |> Logger.error()

    conn
    |> put_status(:bad_request)
    |> put_view(html: ExchangeWeb.ErrorHTML, json: ExchangeWeb.ErrorJSON)
    |> render(:"400")
  end
end
