defmodule DHT do
  @moduledoc File.read!("README.md")
             |> String.split(~r/<!-- .*DOC !-->/)
             |> Enum.drop(1)
             |> Enum.join("\n")

  @type period :: non_neg_integer()
  @type pin :: non_neg_integer()
  @type reading :: %{temperature: float(), humidity: float()}
  @type sensor :: :am2302 | :dht11 | :dht22 | 11 | 22

  @doc ~s(
    Start polling of readings at specified period intervals that are delivered as telemtry events
    #{
         File.read!("README.md")
         |> String.split(~r/<!-- POLLDOC !-->/)
         |> Enum.drop(1)
         |> hd()
       }
  )
  @spec start_polling(pin(), sensor(), period()) ::
          DynamicSupervisor.on_start_child() | {:error, %ArgumentError{}}
  def start_polling(pin, sensor, period \\ 2)

  def start_polling(pin, sensor, period) when is_integer(period) and period >= 2 do
    case sanitize_args(pin, sensor) do
      {:ok, pin, sensor} ->
        DHT.Telemetry.start_polling(pin, sensor, period)

      err ->
        err
    end
  end

  def start_polling(_pin, _sensor, _period) do
    {:error, %ArgumentError{message: "time period must be >= 2 seconds"}}
  end

  @doc ~s(
  Take a reading on the specified pin for a sensor type
  #{
         File.read!("README.md")
         |> String.split("<!-- READDOC !-->")
         |> Enum.drop(1)
         |> hd()
       }
  )
  @spec read(pin(), sensor()) :: {:ok, reading} | {:error, %ArgumentError{}} | {:error, integer()}
  def read(pin, sensor) do
    case sanitize_args(pin, sensor) do
      {:ok, pin, sensor} -> DHT.Port.read(pin, sensor)
      err -> err
    end
  end

  @spec stop_polling(pin(), sensor()) :: :ok | {:error, :not_found}
  def stop_polling(pin, sensor) do
    case sanitize_args(pin, sensor) do
      {:ok, pin, sensor} -> DHT.Telemetry.stop_polling(pin, sensor)
      err -> err
    end
  end

  defp sanitize_args(pin, sensor) do
    with {:ok, pin} <- sanitize_pin(pin),
         {:ok, sensor} <- sanitize_sensor(sensor) do
      {:ok, pin, sensor}
    else
      {:error, msg} -> {:error, %ArgumentError{message: msg}}
    end
  end

  defp sanitize_pin(pin) when is_integer(pin), do: {:ok, pin}
  defp sanitize_pin(pin), do: {:error, "invalid pin: #{inspect(pin)}"}

  @supported_sensors Enum.reduce([{:dht11, 11}, {:dht22, 22}, {:am2302, 22}], [], fn {k, v},
                                                                                     acc ->
                       [{to_string(k), v}, {to_string(v), v} | acc]
                     end)
                     |> Map.new()

  defp sanitize_sensor(sensor) do
    cleansed = String.downcase(to_string(sensor))

    case Map.get(@supported_sensors, cleansed) do
      nil -> {:error, "invalid sensor: #{inspect(sensor)}"}
      sensor_num -> {:ok, sensor_num}
    end
  end
end
