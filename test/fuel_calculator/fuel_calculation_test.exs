defmodule FuelCalculator.FuelCalculationTest do
  use ExUnit.Case, async: true

  alias FuelCalculator.FuelCalculation

  describe "calculate_base_fuel/3" do
    test "calculates fuel for launch from Earth" do
      # 28801 * 9.807 * 0.042 - 33 = 11829.098994 -> floor = 11829
      assert FuelCalculation.calculate_base_fuel(28801, :launch, 9.807) == 11_829
    end

    test "calculates fuel for landing on Earth" do
      # 28801 * 9.807 * 0.033 - 42 = 9278.476623 -> floor = 9278
      assert FuelCalculation.calculate_base_fuel(28801, :land, 9.807) == 9278
    end

    test "calculates fuel for landing on Moon" do
      # 28801 * 1.62 * 0.033 - 42 = 1497.101340 -> floor = 1497
      assert FuelCalculation.calculate_base_fuel(28801, :land, 1.62) == 1497
    end

    test "calculates fuel for launching from Mars" do
      # 14606 * 3.711 * 0.042 - 33 = 2243.479932 -> floor = 2243
      assert FuelCalculation.calculate_base_fuel(14606, :launch, 3.711) == 2243
    end

    test "returns negative value for small masses" do
      assert FuelCalculation.calculate_base_fuel(10, :launch, 9.807) == -29
    end
  end

  describe "calculate_fuel_for_step/3" do
    test "calculates fuel for landing on Earth including fuel for fuel" do
      # Landing Apollo 11 CSM on Earth
      assert FuelCalculation.calculate_fuel_for_step(28801, :land, :earth) == 13_447
    end

    test "calculates fuel for launch from Earth" do
      assert FuelCalculation.calculate_fuel_for_step(28801, :launch, :earth) == 19_772
    end

    test "calculates fuel for landing on Moon" do
      assert FuelCalculation.calculate_fuel_for_step(28801, :land, :moon) == 1535
    end

    test "returns zero for small masses that need no fuel" do
      assert FuelCalculation.calculate_fuel_for_step(1, :launch, :earth) == 0
    end
  end

  describe "calculate_total_fuel/2" do
    test "Apollo 11 Mission: launch Earth, land Moon, launch Moon, land Earth" do
      flight_path = [
        {:launch, :earth},
        {:land, :moon},
        {:launch, :moon},
        {:land, :earth}
      ]

      assert FuelCalculation.calculate_total_fuel(28801, flight_path) == {:ok, 51_898}
    end

    test "Mars Mission: launch Earth, land Mars, launch Mars, land Earth" do
      flight_path = [
        {:launch, :earth},
        {:land, :mars},
        {:launch, :mars},
        {:land, :earth}
      ]

      assert FuelCalculation.calculate_total_fuel(14606, flight_path) == {:ok, 33_388}
    end

    test "Passenger Ship Mission: launch Earth, land Moon, launch Moon, land Mars, launch Mars, land Earth" do
      flight_path = [
        {:launch, :earth},
        {:land, :moon},
        {:launch, :moon},
        {:land, :mars},
        {:launch, :mars},
        {:land, :earth}
      ]

      assert FuelCalculation.calculate_total_fuel(75432, flight_path) == {:ok, 212_161}
    end

    test "single step mission: launch from Earth" do
      flight_path = [{:launch, :earth}]
      assert FuelCalculation.calculate_total_fuel(28801, flight_path) == {:ok, 19_772}
    end

    test "returns error for empty flight path" do
      assert FuelCalculation.calculate_total_fuel(28801, []) ==
               {:error, "Flight path cannot be empty"}
    end

    test "returns error for invalid mass (zero)" do
      flight_path = [{:launch, :earth}]

      assert FuelCalculation.calculate_total_fuel(0, flight_path) ==
               {:error, "Invalid mass or flight path"}
    end

    test "returns error for invalid mass (negative)" do
      flight_path = [{:launch, :earth}]

      assert FuelCalculation.calculate_total_fuel(-100, flight_path) ==
               {:error, "Invalid mass or flight path"}
    end

    test "returns error for invalid mass (non-integer)" do
      flight_path = [{:launch, :earth}]

      assert FuelCalculation.calculate_total_fuel("not a number", flight_path) ==
               {:error, "Invalid mass or flight path"}
    end
  end

  describe "supported_planets/0" do
    test "returns list of planets with gravity values" do
      planets = FuelCalculation.supported_planets()

      assert Enum.sort(planets) == [
               {:earth, 9.807},
               {:mars, 3.711},
               {:moon, 1.62}
             ]
    end
  end
end
