defmodule VExchangeWeb.UserLoginLive do
  use VExchangeWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-center h-screen">
      <div class="mx-auto max-w-sm">
        <.header class="text-center">
          <span class="text-white">Log in to virus.exchange</span>
          <:subtitle>
            Don't have an account?
            <.link
              navigate={~p"/users/register"}
              class="font-semibold text-emerald-500 hover:underline"
            >
              Sign up
            </.link>
            for an account now.
          </:subtitle>
        </.header>

        <.simple_form
          :let={f}
          id="login_form"
          as={:user}
          for={%{}}
          action={~p"/users/log_in"}
          phx-update="ignore"
        >
          <.input field={{f, :email}} type="email" label="Email" required />
          <.input field={{f, :password}} type="password" label="Password" required />

          <:actions :let={f}>
            <.input field={{f, :remember_me}} type="checkbox" label="Keep me logged in" />
            <.link href={~p"/users/reset_password"} class="text-sm font-semibold text-emerald-500">
              Forgot your password?
            </.link>
          </:actions>
          <:actions>
            <.button phx-disable-with="Signing in..." class="w-full">
              Sign in <span aria-hidden="true">→</span>
            </.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)

    {:ok, socket, temporary_assigns: [email: email]}
  end
end
