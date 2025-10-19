defmodule PulseVoteWeb.PageController do
  use PulseVoteWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
