defmodule OneLog do
  @moduledoc """
  OneLog - TODO
  """

  require Logger

  @log_levels %{
    debug: 0,
    info: 1,
    warn: 2,
    error: 3,
    fatal: 4
  }

  def install() do
    :telemetry.attach("one-log", [:phoenix, :endpoint, :stop], &handle_event/4, nil)
  end

  defp handle_event(_evt, _measurements, _metadata, _ctx) do
    metrics_map = Process.get(:__one_log_metrics__) || %{}
    logs_list = Process.get(:__one_log_logs__) || []
    metadata_list = Process.get(:__one_log_metadata__) || []

    determined_log_level =
      logs_list
      |> Enum.max_by(fn {level, _} -> Map.get(@log_levels, level) end)
      |> elem(0)

    log_messages = Enum.map(logs_list, fn {_, msg} -> msg end)

    Logger.log(determined_log_level, "OneLog: #{inspect(log_messages)}", Map.merge(
      Enum.into(metadata_list, %{}), metrics_map
    ))
  end

  def metadata(args) do
    current_metadata = Process.get(:__one_log_metadata__) || []
    Process.put(:__one_log_metadata__, Keyword.merge(current_metadata, args))
  end

  def increment(metric_name, value) do
    current_metrics = Process.get(:__one_log_metrics__) || %{}
    current_value = Map.get(current_metrics, metric_name, 0)
    Process.put(:__one_log_metrics__, Map.put(current_metrics, metric_name, current_value + value))
  end

  def log(level, msg) do
    current_logs = Process.get(:__one_log_logs__) || []
    Process.put(:__one_log_logs__, current_logs ++ [{level, msg}])
  end
end
