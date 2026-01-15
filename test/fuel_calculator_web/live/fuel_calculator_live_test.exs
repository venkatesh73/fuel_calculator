defmodule FuelCalculatorWeb.FuelCalculatorLiveTest do
  @moduledoc """
  Tests for the FuelCalculatorLive LiveView module.
  """
  use FuelCalculatorWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "mount/3" do
    test "initializes with empty state", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "h1", "Fuel Calculator")
      assert has_element?(view, "input[name='mass']")
      assert has_element?(view, "#action-select")
      assert has_element?(view, "#planet-select")
    end

    test "displays empty flight path message on mount", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "No flight steps added yet"
    end

    test "displays fuel requirements prompt on mount", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Enter spacecraft mass and add flight steps to calculate fuel requirements"
    end
  end

  describe "update_mass event" do
    test "updates mass assign when valid mass is entered", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> form("form[phx-change='update_mass']", mass: "1000")
      |> render_change()

      assert view |> element("input[name='mass']") |> render() =~ "value=\"1000\""
    end

    test "displays error for invalid mass", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> form("form[phx-change='update_mass']", mass: "invalid")
        |> render_change()

      assert html =~ "Please enter a valid positive mass"
    end

    test "displays error for negative mass", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> form("form[phx-change='update_mass']", mass: "-100")
        |> render_change()

      assert html =~ "Please enter a valid positive mass"
    end

    test "calculates fuel when mass and flight path are present", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Add a flight step
      view
      |> element("button", "Add")
      |> render_click(%{action: "launch", planet: "earth"})

      # Enter mass
      html =
        view
        |> form("form[phx-change='update_mass']", mass: "28801")
        |> render_change()

      assert html =~ "kg"
    end
  end

  describe "add_step event" do
    test "adds a launch step to flight path", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> element("button", "Add")
        |> render_click(%{action: "launch", planet: "earth"})

      assert html =~ "Launch - Earth"
      refute html =~ "No flight steps added yet"
    end

    test "adds a land step to flight path", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> element("button", "Add")
        |> render_click(%{action: "land", planet: "moon"})

      assert html =~ "Land - Moon"
    end

    test "adds multiple steps in sequence", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> element("button", "Add")
      |> render_click(%{action: "launch", planet: "earth"})

      view
      |> element("button", "Add")
      |> render_click(%{action: "land", planet: "moon"})

      html =
        view
        |> element("button", "Add")
        |> render_click(%{action: "launch", planet: "mars"})

      assert html =~ "Launch - Earth"
      assert html =~ "Land - Moon"
      assert html =~ "Launch - Mars"
    end

    test "displays step numbers correctly", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> element("button", "Add")
      |> render_click(%{action: "launch", planet: "earth"})

      html =
        view
        |> element("button", "Add")
        |> render_click(%{action: "land", planet: "moon"})

      assert html =~ "1"
      assert html =~ "2"
    end

    test "calculates fuel when mass is present", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Enter mass first
      view
      |> form("form[phx-change='update_mass']", mass: "1000")
      |> render_change()

      # Add step
      html =
        view
        |> element("button", "Add")
        |> render_click(%{action: "launch", planet: "earth"})

      assert html =~ "Total Fuel Required"
    end
  end

  describe "remove_step event" do
    test "removes a step from flight path", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Add two steps
      view
      |> element("button", "Add")
      |> render_click(%{action: "launch", planet: "earth"})

      view
      |> element("button", "Add")
      |> render_click(%{action: "land", planet: "moon"})

      # Remove first step
      html =
        view
        |> element("button[phx-click='remove_step'][phx-value-index='0']")
        |> render_click()

      refute html =~ "Launch - Earth"
      assert html =~ "Land - Moon"
    end

    test "recalculates fuel after removing step", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Enter mass
      view
      |> form("form[phx-change='update_mass']", mass: "1000")
      |> render_change()

      # Add two steps
      view
      |> element("button", "Add")
      |> render_click(%{action: "launch", planet: "earth"})

      view
      |> element("button", "Add")
      |> render_click(%{action: "land", planet: "moon"})

      # Remove a step
      html =
        view
        |> element("button[phx-click='remove_step'][phx-value-index='0']")
        |> render_click()

      assert html =~ "Total Fuel Required"
    end

    test "shows empty message when all steps removed", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Add one step
      view
      |> element("button", "Add")
      |> render_click(%{action: "launch", planet: "earth"})

      # Remove it
      html =
        view
        |> element("button[phx-click='remove_step'][phx-value-index='0']")
        |> render_click()

      assert html =~ "No flight steps added yet"
    end
  end

  describe "clear_path event" do
    test "clears all steps from flight path", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Add multiple steps
      view
      |> element("button", "Add")
      |> render_click(%{action: "launch", planet: "earth"})

      view
      |> element("button", "Add")
      |> render_click(%{action: "land", planet: "moon"})

      # Clear all
      html =
        view
        |> element("button", "Clear All")
        |> render_click()

      assert html =~ "No flight steps added yet"
      refute html =~ "Launch - Earth"
      refute html =~ "Land - Moon"
    end

    test "resets fuel calculation", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Enter mass and add step
      view
      |> form("form[phx-change='update_mass']", mass: "1000")
      |> render_change()

      view
      |> element("button", "Add")
      |> render_click(%{action: "launch", planet: "earth"})

      # Clear path
      html =
        view
        |> element("button", "Clear All")
        |> render_click()

      refute html =~ "Total Fuel Required"
    end

    test "clears any error messages", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Cause an error
      view
      |> form("form[phx-change='update_mass']", mass: "invalid")
      |> render_change()

      # Add a step to have clear button
      view
      |> element("button", "Add")
      |> render_click(%{action: "launch", planet: "earth"})

      # Clear path
      html =
        view
        |> element("button", "Clear All")
        |> render_click()

      refute html =~ "Please enter a valid positive mass"
    end
  end

  describe "fuel calculation integration" do
    test "calculates fuel for Apollo 11 mission", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Enter mass
      view
      |> form("form[phx-change='update_mass']", mass: "28801")
      |> render_change()

      # Build Apollo 11 path
      view
      |> element("button", "Add")
      |> render_click(%{action: "launch", planet: "earth"})

      view
      |> element("button", "Add")
      |> render_click(%{action: "land", planet: "moon"})

      view
      |> element("button", "Add")
      |> render_click(%{action: "launch", planet: "moon"})

      html =
        view
        |> element("button", "Add")
        |> render_click(%{action: "land", planet: "earth"})

      assert html =~ "51,898 kg"
    end

    test "calculates fuel for Mars mission", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Enter mass
      view
      |> form("form[phx-change='update_mass']", mass: "14606")
      |> render_change()

      # Build Mars mission path
      view
      |> element("button", "Add")
      |> render_click(%{action: "launch", planet: "earth"})

      view
      |> element("button", "Add")
      |> render_click(%{action: "land", planet: "mars"})

      view
      |> element("button", "Add")
      |> render_click(%{action: "launch", planet: "mars"})

      html =
        view
        |> element("button", "Add")
        |> render_click(%{action: "land", planet: "earth"})

      assert html =~ "33,388 kg"
    end

    test "calculates fuel for Passenger Ship mission", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Enter mass
      view
      |> form("form[phx-change='update_mass']", mass: "75432")
      |> render_change()

      # Build complex mission path
      view
      |> element("button", "Add")
      |> render_click(%{action: "launch", planet: "earth"})

      view
      |> element("button", "Add")
      |> render_click(%{action: "land", planet: "moon"})

      view
      |> element("button", "Add")
      |> render_click(%{action: "launch", planet: "moon"})

      view
      |> element("button", "Add")
      |> render_click(%{action: "land", planet: "mars"})

      view
      |> element("button", "Add")
      |> render_click(%{action: "launch", planet: "mars"})

      html =
        view
        |> element("button", "Add")
        |> render_click(%{action: "land", planet: "earth"})

      assert html =~ "212,161 kg"
    end

    test "displays mission summary with correct values", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Enter mass
      view
      |> form("form[phx-change='update_mass']", mass: "1000")
      |> render_change()

      # Add steps
      view
      |> element("button", "Add")
      |> render_click(%{action: "launch", planet: "earth"})

      html =
        view
        |> element("button", "Add")
        |> render_click(%{action: "land", planet: "moon"})

      assert html =~ "Mission Summary"
      assert html =~ "Spacecraft Mass:"
      assert html =~ "1000 kg"
      assert html =~ "Flight Steps:"
      assert html =~ "2"
      assert html =~ "Total Mission Mass:"
    end
  end

  describe "UI elements" do
    test "displays all planet options", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Earth"
      assert html =~ "Moon"
      assert html =~ "Mars"
    end

    test "displays all action options", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Launch"
      assert html =~ "Land"
    end

    test "displays example scenarios", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Example Scenarios"
      assert html =~ "Apollo 11 Mission"
      assert html =~ "Mars Mission"
      assert html =~ "Passenger Ship Mission"
    end

    test "shows clear button only when flight path has steps", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/")

      refute html =~ "Clear All"

      html =
        view
        |> element("button", "Add")
        |> render_click(%{action: "launch", planet: "earth"})

      assert html =~ "Clear All"
    end

    test "formats large numbers with commas", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Enter mass
      view
      |> form("form[phx-change='update_mass']", mass: "100000")
      |> render_change()

      # Add step
      html =
        view
        |> element("button", "Add")
        |> render_click(%{action: "launch", planet: "earth"})

      # Should format numbers with commas
      assert html =~ ~r/\d{1,3}(,\d{3})* kg/
    end
  end

  describe "error handling" do
    test "shows error for empty mass with flight path", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Add step without mass
      html =
        view
        |> element("button", "Add")
        |> render_click(%{action: "launch", planet: "earth"})

      refute html =~ "Total Fuel Required"
    end

    test "clears error when valid input is provided", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Enter invalid mass
      view
      |> form("form[phx-change='update_mass']", mass: "invalid")
      |> render_change()

      # Enter valid mass
      html =
        view
        |> form("form[phx-change='update_mass']", mass: "1000")
        |> render_change()

      refute html =~ "Please enter a valid positive mass"
    end

    test "error persists when adding step with invalid mass", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Cause error
      view
      |> form("form[phx-change='update_mass']", mass: "invalid")
      |> render_change()

      # Add step - error should persist since mass is still invalid
      html =
        view
        |> element("button", "Add")
        |> render_click(%{action: "launch", planet: "earth"})

      assert html =~ "alert-error"
      assert html =~ "Please enter a valid positive mass"
    end
  end
end
