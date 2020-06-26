# DHT

Driver for DHT 11, DHT 22, and AM2302 temperature/humidity sensors

# Installation

This ports the [Adafruit Python DHT](https://github.com/adafruit/Adafruit_Python_DHT) library
C source to handle the pin reads.

Currently this is only supporting valid Nerves targets, but in the future will be available
to use in any Elixir environment with GPIO (like rasbian).

For none supported platforms (like host machine, MacOS, etc), readings will still work but be
randomly generated.

```elixir
def deps() do
  {:dht, "~> 0.1"}
end
```

See the datasheets for more info:
  * [Adafruit DHT22/AM2302](https://cdn-shop.adafruit.com/datasheets/Digital+humidity+and+temperature+sensor+AM2302.pdf)
  * [SparkFun DHT22](https://www.sparkfun.com/datasheets/Sensors/Temperature/DHT22.pdf)
  * [Mouser DHT11](https://www.mouser.com/datasheet/2/758/DHT11-Technical-Data-Sheet-Translated-Version-1143054.pdf)

# Usage

<!-- READDOC !-->

You need to specify the GPIO pin number and sensor type when taking a reading.
The sensor type can be a string, atom, or integer representation of the target sensor:

```elixir
iex()> DHT.read(6, :dht22)
{:ok, %{temperature: 22.6, humidity: 50.5}}

iex()> DHT.read(6, "dht22")
{:ok, %{temperature: 22.6, humidity: 50.5}}

iex()> DHT.read(6, 22)
{:ok, %{temperature: 22.6, humidity: 50.5}}

iex()> DHT.read(6, "22")
{:ok, %{temperature: 22.6, humidity: 50.5}}
```
<!-- READDOC !-->

DHT also supports polling at regular intervals which outputs `:telemetry` events:

<!-- POLLDOC !-->

  * `[:dht, :read]`
    * message is a map with `:temperature` and `:humidity` keys
    * metadata is map with `:pin` and `:sensor` keys
  * `[:dht, :error]`
    * message is a map with `:error` key containing the failure message
    * metadata is map with `:pin` and `:sensor` keys

The polling period defaults to `2` seconds, which is the minimum rate allowed for
DHT sensors, but you can specify longer:

```elixir
# Poll DHT22 on GPIO 6 every 30 seconds
iex()> DHT.start_polling(6, :dht22, 30)
{:ok, #PID<0.233.0>}
```

Once polling, you can attach to the read events view `:telemetry.attach/4`

```elixir
defmodule MyWatcher do
  def inspect_it(a, b, c, d) do
    IO.inspect(a)
    IO.inspect(b)
    IO.inspect(c)
    IO.inspect(d)
  end
end

:telemetry.attach("im-attached", [:dht, :read], &MyWatcher.inspect_it/4, nil)
```

Or do whatever else it is that you cool cats 😸 do with telemetry 😉
