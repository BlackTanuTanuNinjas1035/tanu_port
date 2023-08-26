defmodule TanuPortTest do
  use ExUnit.Case
  doctest TanuPort

  test "greets the world" do
    assert TanuPort.hello() == :world
  end
end
