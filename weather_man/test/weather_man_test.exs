defmodule WeatherManTest do
  use ExUnit.Case
  doctest WeatherMan

  test "greets the world" do
    assert WeatherMan.hello() == :world
  end
end
