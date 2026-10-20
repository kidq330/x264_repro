defmodule Repro.MixProject do
  use Mix.Project
  def project, do: [app: :repro, version: "0.1.0", deps: deps(), releases: [repro: []]]
  def application, do: [extra_applications: [:logger]]
  defp deps, do: [{:membrane_core, "~> 1.2"}, {:membrane_h264_ffmpeg_plugin, "~> 0.32.7"}]
end
