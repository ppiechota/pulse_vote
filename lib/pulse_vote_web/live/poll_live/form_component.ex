defmodule PulseVoteWeb.PollLive.FormComponent do
  use PulseVoteWeb, :live_component

  alias PulseVote.Polls

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white shadow-sm rounded-lg p-6">
      <h2 class="text-2xl font-bold text-gray-900 mb-6"><%= @title %></h2>

      <.form
        for={@form}
        id="poll-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="space-y-6"
      >
        <div>
          <.input field={@form[:title]} type="text" label="Poll Title" required />
        </div>

        <div>
          <.input field={@form[:description]} type="textarea" label="Description (optional)" />
        </div>

        <div>
          <label class="block text-sm font-semibold leading-6 text-zinc-800 mb-2">
            Options (minimum 2, maximum 10)
          </label>

          <div class="space-y-3">
            <%= for {option_form, index} <- Enum.with_index(@form[:options].value || []) do %>
              <div class="flex gap-2 items-start">
                <div class="flex-1">
                  <input
                    type="text"
                    name={"poll[options][#{index}][text]"}
                    value={option_form["text"] || ""}
                    placeholder={"Option #{index + 1}"}
                    class="block w-full rounded-md border-zinc-300 shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm"
                  />
                </div>
                <%= if length(@form[:options].value || []) > 2 do %>
                  <button
                    type="button"
                    phx-click="remove-option"
                    phx-value-index={index}
                    phx-target={@myself}
                    class="mt-2 text-sm text-red-600 hover:text-red-800 font-medium"
                  >
                    Remove
                  </button>
                <% end %>
              </div>
            <% end %>
          </div>

          <%= if length(@form[:options].value || []) < 10 do %>
            <button
              type="button"
              phx-click="add-option"
              phx-target={@myself}
              class="mt-3 text-sm text-indigo-600 hover:text-indigo-800 font-medium"
            >
              + Add Option
            </button>
          <% end %>
        </div>

        <div class="flex gap-3">
          <.button type="submit" phx-disable-with="Creating..." class="flex-1">
            Create Poll
          </.button>
          <.link
            patch={@patch}
            class="inline-flex items-center justify-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
          >
            Cancel
          </.link>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{poll: poll} = assigns, socket) do
    changeset = Polls.change_poll(poll)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"poll" => poll_params}, socket) do
    changeset =
      socket.assigns.poll
      |> Polls.change_poll(poll_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("add-option", _params, socket) do
    existing_options = get_in(socket.assigns.form.params, ["options"]) || []
    new_options = existing_options ++ [%{"text" => ""}]

    params = Map.put(socket.assigns.form.params, "options", new_options)
    changeset = Polls.change_poll(socket.assigns.poll, params)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("remove-option", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    existing_options = get_in(socket.assigns.form.params, ["options"]) || []
    new_options = List.delete_at(existing_options, index)

    params = Map.put(socket.assigns.form.params, "options", new_options)
    changeset = Polls.change_poll(socket.assigns.poll, params)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"poll" => poll_params}, socket) do
    save_poll(socket, socket.assigns.action, poll_params)
  end

  defp save_poll(socket, :new, poll_params) do
    # Add the current user's ID to the poll params
    poll_params = Map.put(poll_params, "user_id", socket.assigns.current_user.id)

    case Polls.create_poll(poll_params) do
      {:ok, poll} ->
        notify_parent({:saved, poll})

        {:noreply,
         socket
         |> put_flash(:info, "Poll created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end