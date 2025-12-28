defmodule OneLog.Phoenix do
  @behaviour OneLog

  import OneLog

  def id(), do: "one-log-phx"

  def stop_events(), do: [[:phoenix, :endpoint, :stop]]

  def exception_events(), do: [[:phoenix, :router_dispatch, :exception]]

  def handle_event([:phoenix, :router_dispatch, :exception], _measurements, metadata, _ctx) do
    log(:error, Exception.format(metadata.reason.kind, metadata.reason.reason, metadata.reason.stack))
  end

  def handle_event([:phoenix, :endpoint, :stop], %{duration: duration}, metadata, _ctx) do
    metadata(duration: duration, status_code: metadata.conn.status, request_path: metadata.conn.request_path)
    OneLog.finish()
  end
end
