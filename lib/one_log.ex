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
    :telemetry.attach_many("one-log", [
      [:phoenix, :router_dispatch, :exception],
      [:phoenix, :endpoint, :stop]
    ], &handle_event/4, nil)
  end

  defp handle_event([:phoenix, :router_dispatch, :exception], _measurements, metadata, _ctx) do
    log(:error, Exception.format(metadata.reason.kind, metadata.reason.reason, metadata.reason.stack))
  end

  defp handle_event([:phoenix, :endpoint, :stop], %{duration: duration}, metadata, _ctx) do
    metrics_map = Process.get(:__one_log_metrics__) || %{}
    logs_list = Process.get(:__one_log_logs__) || []
    metadata_list = Process.get(:__one_log_metadata__) || []
    request_metadata = %{
      duration: duration,
      status_code: metadata.conn.status,
      request_path: metadata.conn.request_path
    }

    determined_log_level =
      logs_list
      |> Enum.max_by(fn {level, _} -> Map.get(@log_levels, level) end)
      |> elem(0)

    log_messages = Enum.map(logs_list, fn {_, msg} -> msg end)

    metadata = metadata_list
      |> Enum.into(%{})
      |> Map.merge(metrics_map)
      |> Map.merge(request_metadata)

    Logger.log(determined_log_level, "OneLog: #{inspect(log_messages)}", metadata)
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
