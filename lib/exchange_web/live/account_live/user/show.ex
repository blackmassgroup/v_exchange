defmodule ExchangeWeb.AccountLive.User.Show do
  use ExchangeWeb, :live_view

  alias Exchange.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:user, Accounts.get_user!(id) |> Exchange.Repo.Local.preload(:role))
     |> assign(:roles, Accounts.list_roles() |> Enum.map(&[value: &1.id, key: &1.name]))}
  end

  defp page_title(:show), do: "Show User"
  defp page_title(:edit), do: "Edit User"
end
