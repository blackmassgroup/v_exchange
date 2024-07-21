defmodule VExchangeWeb.SampleLive.SortingComponent do
  use VExchangeWeb, :live_component

  def render(%{key: key} = assigns) when is_atom(key) do
    ~H"""
    <div phx-click="sort_by_key" phx-target={@myself} class="sorting-header flex justify-items-center">
      <%= @key %> <%= chevron(@sorting, @key) %>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div
      phx-click="sort_by_key"
      phx-target={@myself}
      class="sorting-header flex justify-items-center items-center"
    >
      <%= @key %> <%= chevron(@sorting, String.to_existing_atom(@key)) %>
    </div>
    """
  end

  def handle_event("sort_by_key", _params, socket) do
    %{sorting: %{sort_dir: sort_dir}, key: key} = socket.assigns

    sort_dir = if sort_dir == :asc, do: :desc, else: :asc
    opts = %{sort_by: String.to_existing_atom(key), sort_dir: sort_dir}

    send(self(), {:update, opts})

    socket = assign(socket, :key, String.to_existing_atom(key))
    {:noreply, socket}
  end

  def chevron(%{sort_by: sort_by, sort_dir: :asc} = assigns, key) when sort_by == key do
    ~H"""
    <Heroicons.chevron_up solid class="h-5 w-5 stroke-current" />
    """
  end

  def chevron(%{sort_by: sort_by, sort_dir: :desc} = assigns, key) when sort_by == key do
    ~H"""
    <Heroicons.chevron_down solid class="h-5 w-5 stroke-current" />
    """
  end

  def chevron(assigns, _key) do
    ~H"""
    <Heroicons.chevron_right solid class="h-5 w-5 stroke-current" />
    """
  end
end
