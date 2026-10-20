defmodule Repro do
  import Membrane.ChildrenSpec
  alias Membrane.Testing

  @width 320
  @height 240
  @frames 30

  # Encodes a few gray I420 frames, then prints the libavutil images this VM has mapped.
  def run do
    {:ok, _apps} = Application.ensure_all_started(:membrane_h264_ffmpeg_plugin)

    format = %Membrane.RawVideo{
      width: @width,
      height: @height,
      pixel_format: :I420,
      framerate: {30, 1},
      aligned: true
    }

    frame = :binary.copy(<<128>>, div(@width * @height * 3, 2))

    buffers =
      for i <- 0..(@frames - 1),
          do: %Membrane.Buffer{payload: frame, pts: div(Membrane.Time.seconds(i), 30)}

    spec =
      child(:source, %Testing.Source{output: buffers, stream_format: format})
      |> child(:encoder, Membrane.H264.FFmpeg.Encoder)
      |> child(:sink, Testing.Sink)

    {:ok, _supervisor, pipeline} = Testing.Pipeline.start(spec: spec)

    receive do
      {Testing.Pipeline, ^pipeline, {:handle_element_end_of_stream, {:sink, :input}}} -> :ok
    after
      60_000 -> raise "pipeline timed out"
    end

    Testing.Pipeline.terminate(pipeline)

    images =
      :os.cmd(~c"lsof -p #{System.pid()} -Fn")
      |> to_string()
      |> String.split("\n")
      |> Enum.filter(&String.contains?(&1, "libavutil"))
      |> Enum.map(&String.trim_leading(&1, "n"))
      |> Enum.uniq()

    IO.puts("REPRO libavutil_images=#{length(images)}")
    Enum.each(images, &IO.puts("REPRO   #{&1}"))
  end
end
