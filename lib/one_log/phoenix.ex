defmodule OneLog.Phoenix do
  import OneLog

  def install() do
    :telemetry.attach_many(
      "one-log-phx",
      [
        [:phoenix, :endpoint, :stop],
        [:phoenix, :router_dispatch, :exception]
      ],
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def handle_event([:phoenix, :router_dispatch, :exception], _measurements, metadata, _ctx) do
    log(:error, Exception.format(metadata.reason.kind, metadata.reason.reason, metadata.reason.stack))
  end

  def handle_event([:phoenix, :endpoint, :stop], %{duration: duration}, metadata, _ctx) do
    metadata(duration: duration, status_code: metadata.conn.status, request_path: metadata.conn.request_path)
    OneLog.finish()
  end
end
