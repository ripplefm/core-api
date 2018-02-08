defmodule Ripple.StationServerTest do
  use Ripple.DataCase

  alias Ripple.Stations.StationServer

  describe "station server" do
    @base_state %{
      name: "some name",
      slug: "some-slug",
      tags: [],
      guests: 0,
      queue: [],
      current_track: nil
    }

    @track_url "https://www.youtube.com/watch?v=4Rc-NGWEHdU"

    setup do
      {:ok, user} = Ripple.Users.create_user(%{username: "tester"})
      %{state: Map.put(@base_state, :users, [user]), user: user}
    end

    test "add a user to a station", %{state: state, user: user} do
      {:ok, new_user} = Ripple.Users.create_user(%{username: "tester2"})
      {:reply, :ok, new_state} = StationServer.handle_call({:add_user, new_user}, self(), state)
      assert state.users == [user]
      assert new_state.users == [user, new_user]
      assert Map.delete(new_state, :users) == Map.delete(state, :users)
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

    test "remove a guest from a station with 1 guest", %{state: state, user: user} do
      {:reply, :ok, state_with_guest} = StationServer.handle_call({:add_user, nil}, self(), state)
      assert state_with_guest.users == [user]
      assert state_with_guest.guests == 1

      {:reply, false, state_with_guest_without_user} =
        StationServer.handle_call({:remove_user, user}, self(), state_with_guest)

      assert state_with_guest_without_user.users == []
      assert state_with_guest_without_user.guests == 1

      {:reply, true, new_state} =
        StationServer.handle_call({:remove_user, nil}, self(), state_with_guest_without_user)

      assert new_state.users == []
      assert new_state.guests == 0
      assert Map.delete(new_state, :users) == Map.delete(state, :users)
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
