defmodule FuelCalculatorWeb.FuelCalculatorLive do
  @moduledoc """
  Provides real-time fuel calculation interface with dynamic flight path management.
  """
  use FuelCalculatorWeb, :live_view

  alias FuelCalculator.FuelCalculation

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:mass, "")
      |> assign(:flight_path, [])
      |> assign(:total_fuel, nil)
      |> assign(:error, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("update_mass", %{"mass" => mass}, socket) do
    socket =
      socket
      |> assign(:mass, mass)
      |> assign(:error, nil)
      |> calculate_fuel()

    {:noreply, socket}
  end

  @impl true
  def handle_event("add_step", %{"action" => action, "planet" => planet}, socket) do
    action_atom = String.to_existing_atom(action)
    planet_atom = String.to_existing_atom(planet)

    socket =
      socket
      |> update(:flight_path, &(&1 ++ [{action_atom, planet_atom}]))
      |> assign(:error, nil)
      |> calculate_fuel()

    {:noreply, socket}
  end

  @impl true
  def handle_event("remove_step", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)

    socket =
      socket
      |> update(:flight_path, &List.delete_at(&1, index))
      |> assign(:error, nil)
      |> calculate_fuel()

    {:noreply, socket}
  end

  @impl true
  def handle_event("clear_path", _params, socket) do
    socket =
      socket
      |> assign(:flight_path, [])
      |> assign(:total_fuel, nil)
      |> assign(:error, nil)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200 py-8">
      <div class="container mx-auto px-4 max-w-4xl">
        <div class="text-center mb-8">
          <h1 class="text-4xl font-bold text-primary mb-2">Fuel Calculator</h1>
          <p class="text-lg text-base-content/70">
            Calculate fuel requirements for interplanetary travel
          </p>
        </div>

        <div class="grid gap-6 lg:grid-cols-2">
          <!-- Input Section -->
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title text-2xl mb-4">Mission Parameters</h2>
              
    <!-- Mass Input -->
              <div class="form-control">
                <label class="label">
                  <span class="label-text font-semibold">Spacecraft Mass (kg)</span>
                </label>
                <form phx-change="update_mass">
                  <input
                    type="number"
                    placeholder="Enter mass in kg"
                    class="input input-bordered w-full"
                    value={@mass}
                    name="mass"
                    min="1"
                  />
                </form>
              </div>
              
    <!-- Add Flight Step -->
              <div class="divider">Flight Path</div>

              <div class="form-control">
                <label class="label">
                  <span class="label-text font-semibold">Add Flight Step</span>
                </label>
                <div class="flex gap-2">
                  <select class="select select-bordered flex-1" id="action-select">
                    <option value="launch">Launch</option>
                    <option value="land">Land</option>
                  </select>
                  <select class="select select-bordered flex-1" id="planet-select">
                    <option value="earth">Earth</option>
                    <option value="moon">Moon</option>
                    <option value="mars">Mars</option>
                  </select>
                  <button
                    class="btn btn-primary"
                    phx-click="add_step"
                    phx-value-action={get_select_value(assigns, "action-select", "launch")}
                    phx-value-planet={get_select_value(assigns, "planet-select", "earth")}
                    type="button"
                    onclick="this.setAttribute('phx-value-action', document.getElementById('action-select').value); this.setAttribute('phx-value-planet', document.getElementById('planet-select').value);"
                  >
                    Add
                  </button>
                </div>
              </div>
              
    <!-- Flight Path Display -->
              <div class="form-control mt-4">
                <label class="label">
                  <span class="label-text font-semibold">Current Flight Path</span>
                  <button
                    :if={!Enum.empty?(@flight_path)}
                    class="btn btn-ghost btn-xs"
                    phx-click="clear_path"
                    type="button"
                  >
                    Clear All
                  </button>
                </label>
                <div class="space-y-2">
                  <%= if Enum.empty?(@flight_path) do %>
                    <div class="alert alert-info">
                      <span>No flight steps added yet. Add your first step above!</span>
                    </div>
                  <% else %>
                    <%= for {{action, planet}, index} <- Enum.with_index(@flight_path) do %>
                      <div class="flex items-center gap-2 p-3 bg-base-200 rounded-lg">
                        <span class="badge badge-neutral">
                          {index + 1}
                        </span>
                        <span class="flex-1 font-medium">
                          {format_action(action)} - {format_planet(planet)}
                        </span>
                        <button
                          class="btn btn-ghost btn-sm btn-circle"
                          phx-click="remove_step"
                          phx-value-index={index}
                          type="button"
                        >
                          ✕
                        </button>
                      </div>
                    <% end %>
                  <% end %>
                </div>
              </div>
            </div>
          </div>
          
    <!-- Results Section -->
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title text-2xl mb-4">Fuel Requirements</h2>

              <%= if @error do %>
                <div class="alert alert-error">
                  <span>{@error}</span>
                </div>
              <% end %>

              <%= if @total_fuel do %>
                <div class="stats stats-vertical shadow">
                  <div class="stat">
                    <div class="stat-title">Total Fuel Required</div>
                    <div class="stat-value text-primary">{format_number(@total_fuel)} kg</div>
                    <div class="stat-desc">For the complete mission</div>
                  </div>
                </div>
                
    <!-- Mission Details -->
                <div class="mt-6">
                  <h3 class="font-semibold mb-2">Mission Summary</h3>
                  <div class="space-y-1 text-sm">
                    <div class="flex justify-between">
                      <span>Spacecraft Mass:</span>
                      <span class="font-medium">{@mass} kg</span>
                    </div>
                    <div class="flex justify-between">
                      <span>Flight Steps:</span>
                      <span class="font-medium">{length(@flight_path)}</span>
                    </div>
                    <div class="flex justify-between">
                      <span>Total Mission Mass:</span>
                      <span class="font-medium">
                        {format_number(String.to_integer(@mass) + @total_fuel)} kg
                      </span>
                    </div>
                  </div>
                </div>
              <% else %>
                <div class="alert">
                  <span>
                    Enter spacecraft mass and add flight steps to calculate fuel requirements.
                  </span>
                </div>
              <% end %>
              
    <!-- Example Scenarios -->
              <div class="mt-6">
                <h3 class="font-semibold mb-2">Example Scenarios</h3>
                <div class="space-y-2 text-xs">
                  <div class="collapse collapse-arrow bg-base-200">
                    <input type="checkbox" />
                    <div class="collapse-title font-medium">Apollo 11 Mission</div>
                    <div class="collapse-content">
                      <p>Mass: 28801 kg</p>
                      <p>Path: Launch Earth → Land Moon → Launch Moon → Land Earth</p>
                      <p class="font-bold">Expected: 51898 kg</p>
                    </div>
                  </div>
                  <div class="collapse collapse-arrow bg-base-200">
                    <input type="checkbox" />
                    <div class="collapse-title font-medium">Mars Mission</div>
                    <div class="collapse-content">
                      <p>Mass: 14606 kg</p>
                      <p>Path: Launch Earth → Land Mars → Launch Mars → Land Earth</p>
                      <p class="font-bold">Expected: 33388 kg</p>
                    </div>
                  </div>
                  <div class="collapse collapse-arrow bg-base-200">
                    <input type="checkbox" />
                    <div class="collapse-title font-medium">Passenger Ship Mission</div>
                    <div class="collapse-content">
                      <p>Mass: 75432 kg</p>
                      <p>
                        Path: Launch Earth → Land Moon → Launch Moon → Land Mars → Launch Mars → Land Earth
                      </p>
                      <p class="font-bold">Expected: 212161 kg</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Private Functions

  defp calculate_fuel(%{assigns: %{mass: mass, flight_path: path}} = socket)
       when is_binary(mass) and mass != "" do
    case Integer.parse(mass) do
      {mass_int, ""} when mass_int > 0 ->
        if Enum.empty?(path) do
          assign(socket, :total_fuel, nil)
        else
          case FuelCalculation.calculate_total_fuel(mass_int, path) do
            {:ok, fuel} ->
              socket
              |> assign(:total_fuel, fuel)
              |> assign(:error, nil)

            {:error, reason} ->
              socket
              |> assign(:total_fuel, nil)
              |> assign(:error, reason)
          end
        end

      _ ->
        socket
        |> assign(:total_fuel, nil)
        |> assign(:error, "Please enter a valid positive mass")
    end
  end

  defp calculate_fuel(socket) do
    assign(socket, :total_fuel, nil)
  end

  defp format_action(:launch), do: "Launch"
  defp format_action(:land), do: "Land"

  defp format_planet(:earth), do: "Earth"
  defp format_planet(:moon), do: "Moon"
  defp format_planet(:mars), do: "Mars"

  defp format_number(number) when is_integer(number) do
    number
    |> Integer.to_string()
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
  end

  defp get_select_value(_assigns, _id, default), do: default
end
