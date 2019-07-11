# dht
Elixir implementation to read DHT11 and DHT22 sensors

## EXPERIMENTAL

This is an experiment to use only `Circuits.GPIO` to read temperature and humidity values from DHT11 and DHT22 sensors.

See these datasheets for more info:
  * [Adafruit DHT22/AM2302](https://cdn-shop.adafruit.com/datasheets/Digital+humidity+and+temperature+sensor+AM2302.pdf)
  * [SparkFun DHT22](https://www.sparkfun.com/datasheets/Sensors/Temperature/DHT22.pdf)

**TL;DR**
You need to trigger pin LOW for ~ 1ms and then the sensor will start sending back pulses. The length of which corresponds to a bit value - `25-28 us` == "0" and anything longer == "1"

To attempt to trigger and read, run:
```elixir
{:ok, dht} = DHT.start_link
DHT.refresh # this triggers sensor to start sending data
DHT.read # shows the data captured from the last trigger attempt
```
