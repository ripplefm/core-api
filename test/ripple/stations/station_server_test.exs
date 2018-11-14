defmodule Ripple.StationServerTest do
  use Ripple.DataCase

  alias Ripple.Stations.{StationServer, LiveStation, StationStore, StationHandoffStore}

  describe "StationServer" do
    @track_url "https://www.youtube.com/watch?v=4Rc-NGWEHdU"

    setup do
      {:ok, user} = Ripple.Users.create_user(%{username: "tester"})

      {:ok, station} =
        Ripple.Stations.create_station(%{
          creator_id: user.id,
          tags: [],
          play_type: "public",
          name: "Test Station"
        })

      state = %LiveStation{
        id: station.id,
        name: station.name,
        play_type: station.play_type,
        slug: station.slug,
        guests: 0,
        users: [user],
        current_track: nil,
        queue: [],
        creator_id: user.id
      }

      %{state: state, user: user, station: station}
    end

    test "init successfully creates station server for a user", %{
      state: state,
      station: station,
      user: user
    } do
      assert {:ok, result_station} = StationServer.init({station, user})
      assert result_station == state
    end

    test "init succesfully creates station server for a guest", %{state: state, station: station} do
      assert {:ok, result_station} = StationServer.init({station, nil})
      assert result_station == %LiveStation{state | users: [], guests: 1}
    end

    test "init successfully retrieves station from handoff store", %{
      state: state,
      station: station,
      user: user
    } do
      initial_state = %LiveStation{state | tags: ["test"]}
      assert :ok == StationHandoffStore.put(initial_state)
      assert {:ok, result_station} = StationServer.init({station, user})
      assert result_station == %LiveStation{initial_state | users: []}
    end

    test "init successfully saves state to handoff store when exitting", %{state: state} do
      assert :mnesia.table_info(StationHandoffStore, :size) == 0
      assert :ok = StationServer.terminate(:exit, state)
      assert [{_, _, saved_state, _}] = :mnesia.dirty_read(StationHandoffStore, state.slug)
      assert saved_state == state
    end

    test "add a new user to a station", %{state: state, user: user} do
      {:ok, new_user} = Ripple.Users.create_user(%{username: "tester2"})
      {:reply, :ok, new_state} = StationServer.handle_call({:add_user, new_user}, self(), state)
      assert new_state == %LiveStation{state | users: [user, new_user]}
    end

    test "adding a duplicate user to a station does nothing", %{state: state, user: user} do
      initial_state = Map.put(state, :users, [user])

      assert {:reply, :ok, returned_state} =
               StationServer.handle_call({:add_user, user}, self(), initial_state)

      assert returned_state == initial_state
    end

    test "add a guest to a station", %{state: state} do
      {:reply, :ok, new_state} = StationServer.handle_call({:add_user, nil}, self(), state)
      assert state.guests == 0
      assert new_state.guests == 1
      assert Map.delete(new_state, :guests) == Map.delete(state, :guests)
    end

    test "remove a user from a station with 1 user", %{state: state, user: user} do
      {:reply, true, new_state} = StationServer.handle_call({:remove_user, user}, self(), state)
      assert state.users == [user]
      assert new_state.users == []
      assert Map.delete(new_state, :users) == Map.delete(state, :users)
    end

    test "remove a guest from a station with 1 guest", %{state: state} do
      initial_state = %LiveStation{state | users: [], guests: 1}

      assert {:reply, true, new_state} =
               StationServer.handle_call({:remove_user, nil}, self(), initial_state)

      assert new_state == %LiveStation{initial_state | guests: 0}
    end

    test "remove the last user from a station with guests", %{state: state, user: user} do
      initial_state = %LiveStation{state | guests: 2}

      assert {:reply, false, new_state} =
               StationServer.handle_call({:remove_user, user}, self(), initial_state)

      assert new_state == %LiveStation{initial_state | users: []}
    end

    test "remove the last guest from a station with users", %{state: state} do
      initial_state = %LiveStation{state | guests: 1}

      assert {:reply, false, new_state} =
               StationServer.handle_call({:remove_user, nil}, self(), initial_state)

      assert new_state == %LiveStation{initial_state | guests: 0}
    end

    test "state not saved to handoff when exit called by server", %{state: state, user: user} do
      assert {:reply, true, new_state} =
               StationServer.handle_call({:remove_user, user}, self(), state)

      assert :mnesia.table_info(StationHandoffStore, :size) == 0
    end

    test "station removed from station store when exit called by server", %{
      state: state,
      user: user
    } do
      assert {:reply, true, new_state} =
               StationServer.handle_call({:remove_user, user}, self(), state)

      assert StationStore.read(state.slug) == {:ok, nil}
    end

    test "station with private play_type does not allow random user to play tracks", %{
      state: state,
      user: user
    } do
      {:ok, new_user} = Ripple.Users.create_user(%{username: "tester2"})
      initial_state = %LiveStation{state | play_type: "private", users: [user, new_user]}

      assert {:reply, {:error, :not_creator}, returned_state} =
               StationServer.handle_cast({:add_track, @track_url, new_user}, initial_state)

      assert returned_state == initial_state
    end

    test "station with private play_type allows creator to play tracks", %{
      state: state,
      user: user
    } do
      initial_state = %LiveStation{state | play_type: "private"}

      assert {:noreply, returned_state} =
               StationServer.handle_cast({:add_track, @track_url, user}, initial_state)

      assert returned_state.current_track.url == @track_url
      assert %LiveStation{returned_state | current_track: nil} == initial_state
    end

    test "adding a track fails if user not in station", %{state: state, user: user} do
      initial_state = %LiveStation{state | users: []}

      assert {:reply, {:error, :not_in_station}, new_state} =
               StationServer.handle_cast({:add_track, @track_url, user}, initial_state)

      assert new_state == initial_state
    end

    test "adding a track fails if guest is passed in", %{state: state} do
      assert_raise FunctionClauseError,
                   "no function clause matching in Ripple.Stations.StationServer.handle_cast/2",
                   fn ->
                     StationServer.handle_cast({:add_track, @track_url, nil}, state)
                   end
    end

    test "add a track to a station with no track", %{state: state, user: user} do
      {:noreply, new_state} = StationServer.handle_cast({:add_track, @track_url, user}, state)
      assert state.current_track == nil
      assert new_state.current_track.url == @track_url
      assert Map.delete(new_state, :current_track) == Map.delete(state, :current_track)
    end

    test "add a track to a station with a track playing", %{state: state, user: user} do
      {:noreply, state_with_track} =
        StationServer.handle_cast({:add_track, @track_url, user}, state)

      {:noreply, new_state} =
        StationServer.handle_cast({:add_track, @track_url, user}, state_with_track)

      assert state_with_track.queue == []
      assert new_state.current_track != nil
      assert Enum.at(new_state.queue, 0).url == @track_url
      assert Map.delete(new_state, :queue) == Map.delete(state_with_track, :queue)
    end

    test "track finishes with empty queue", %{state: state, user: user} do
      {:noreply, state_with_track} =
        StationServer.handle_cast({:add_track, @track_url, user}, state)

      {:noreply, new_state} = StationServer.handle_info(:track_finished, state_with_track)
      assert state_with_track.current_track.url == @track_url
      assert new_state.current_track == nil
      assert new_state == state
    end

    test "track finishes with non-empty queue", %{state: state, user: user} do
      {:noreply, state_with_track} =
        StationServer.handle_cast({:add_track, @track_url, user}, state)

      {:noreply, state_with_track_and_queue} =
        StationServer.handle_cast({:add_track, @track_url, user}, state_with_track)

      {:noreply, new_state} =
        StationServer.handle_info(:track_finished, state_with_track_and_queue)

      assert state_with_track_and_queue.current_track.url == @track_url
      assert state_with_track_and_queue.queue != []
      assert new_state.queue == []
      assert new_state.current_track.url == @track_url
      assert Map.delete(new_state, :current_track) === Map.delete(state, :current_track)
    end
  end
end
