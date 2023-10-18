defmodule KingdomTest do
  use ExUnit.Case
  doctest Kingdom

  test "greets the world" do
    assert Kingdom.hello() == :world
  end
end
