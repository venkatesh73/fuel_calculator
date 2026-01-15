defmodule FuelCalculator.FuelCalculation do
  @moduledoc """
  Context module for fuel calculation logic.
  Handles all business logic for calculating fuel requirements for interplanetary travel.
  """

  @type action :: :launch | :land
  @type planet :: :earth | :moon | :mars
  @type flight_step :: {action, planet}

  @gravity %{
    earth: 9.807,
    moon: 1.62,
    mars: 3.711
  }

  @doc """
  Calculates total fuel required for a complete flight path.

  ## Parameters
    - mass: Integer representing spacecraft mass in kg
    - flight_path: List of {action, planet} tuples

  ## Returns
    - {:ok, total_fuel} when calculation succeeds
    - {:error, reason} when validation fails

  ## Examples
      iex> FuelCalculation.calculate_total_fuel(28801, [{:launch, :earth}, {:land, :moon}, {:launch, :moon}, {:land, :earth}])
      {:ok, 51898}
  """
  @spec calculate_total_fuel(integer(), [flight_step()]) ::
          {:ok, integer()} | {:error, String.t()}
  def calculate_total_fuel(mass, flight_path)
      when is_integer(mass) and mass > 0 and is_list(flight_path) do
    if Enum.empty?(flight_path) do
      {:error, "Flight path cannot be empty"}
    else
      total =
        flight_path
        |> Enum.reverse()
        |> Enum.reduce(0, fn {action, planet}, acc_fuel ->
          current_mass = mass + acc_fuel
          calculate_fuel_for_step(current_mass, action, planet) + acc_fuel
        end)

      {:ok, total}
    end
  end

  def calculate_total_fuel(_mass, _flight_path), do: {:error, "Invalid mass or flight path"}

  @doc """
  Calculates fuel required for a single step (launch or land) including fuel for fuel.

  ## Parameters
    - mass: Integer representing current mass in kg
    - action: :launch or :land
    - planet: :earth, :moon, or :mars

  ## Returns
    - Integer representing total fuel required
  """
  @spec calculate_fuel_for_step(integer(), action(), planet()) :: integer()
  def calculate_fuel_for_step(mass, action, planet) when is_integer(mass) and mass > 0 do
    gravity = Map.fetch!(@gravity, planet)
    calculate_fuel_recursive(mass, action, gravity, 0)
  end

  @doc """
  Calculates base fuel requirement before accounting for fuel weight.

  ## Parameters
    - mass: Integer representing mass in kg
    - action: :launch or :land
    - gravity: Float representing planet gravity

  ## Returns
    - Integer representing base fuel required (can be negative)
  """
  @spec calculate_base_fuel(integer(), action(), float()) :: integer()
  def calculate_base_fuel(mass, :launch, gravity) do
    floor(mass * gravity * 0.042 - 33)
  end

  def calculate_base_fuel(mass, :land, gravity) do
    floor(mass * gravity * 0.033 - 42)
  end

  @doc """
  Returns the list of supported planets with their gravity values.
  """
  @spec supported_planets() :: [{planet(), float()}]
  def supported_planets do
    Enum.to_list(@gravity)
  end

  # Private Functions

  @spec calculate_fuel_recursive(integer(), action(), float(), integer()) :: integer()
  defp calculate_fuel_recursive(mass, action, gravity, acc) do
    fuel_needed = calculate_base_fuel(mass, action, gravity)

    if fuel_needed <= 0 do
      acc
    else
      calculate_fuel_recursive(fuel_needed, action, gravity, acc + fuel_needed)
    end
  end
end
