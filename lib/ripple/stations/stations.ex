defmodule Ripple.Stations do
  @moduledoc """
  The Stations context.
  """

  import Ecto.Query, warn: false
  alias Ripple.Repo

  alias Ripple.Stations.{Station, StationRegistry}

  @doc """
  Returns the list of stations.

  ## Examples

      iex> list_stations()
      [%Station{}, ...]

  """
  def list_stations do
    StationRegistry.get_stations()
  end

  @doc """
  Gets a single station.

  Raises `Ecto.NoResultsError` if the Station does not exist.

  ## Examples

      iex> get_station!(123)
      %Station{}

      iex> get_station!(456)
      ** (Ecto.NoResultsError)

  """
  def get_station!(slug) do
    local = StationRegistry.get_by_slug(slug)

    case local do
      nil -> Repo.get_by!(Station, slug: slug)
      _ -> local
    end
  end

  @doc """
  Creates a station.

  ## Examples

      iex> create_station(%{field: value})
      {:ok, %Station{}}

      iex> create_station(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_station(attrs \\ %{}) do
    %Station{}
    |> Station.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking station changes.

  ## Examples

      iex> change_station(station)
      %Ecto.Changeset{source: %Station{}}

  """
  def change_station(%Station{} = station) do
    Station.changeset(station, %{})
  end
end
