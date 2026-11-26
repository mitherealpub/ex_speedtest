defmodule Speedtest.Decoder do
  @moduledoc """
  Decodes XML configuration and server list responses from the Speedtest API.
  """

  import SweetXml

  @download_sizes [350, 500, 750, 1000, 1500, 2000, 2500, 3000, 3500, 4000]
  @upload_sizes [32_768, 65_536, 131_072, 262_144, 524_288, 1_048_576, 7_340_032]

  @doc """
  Extracts the host/scheme prefix before the first colon in a URL string.
  """
  @spec url(String.t()) :: String.t()
  def url(data) when is_binary(data) do
    data |> String.split(":", parts: 2) |> hd()
  end

  @doc """
  Decodes the `<client>` attributes from an HTTP response struct or XML body.
  """
  @spec client(%{body: iodata()} | iodata()) :: map()
  def client(data) do
    data
    |> extract_body()
    |> xpath(
      ~x"//client",
      ip: ~x"./@ip"s,
      lat: ~x"./@lat"f,
      lon: ~x"./@lon"f,
      isp: ~x"./@isp"s,
      country: ~x"./@country"s,
      isprating: ~x"./@isprating"s,
      rating: ~x"./@rating"s,
      ispdlavg: ~x"./@ispdlavg"s,
      ispulavg: ~x"./@ispulavg"s
    )
  end

  @doc """
  Decodes all `<server>` elements from `<servers>`.
  """
  @spec server(%{body: iodata()} | iodata()) :: [map()]
  def server(data) do
    data
    |> extract_body()
    |> xpath(
      ~x"//servers/server"l,
      url: ~x"./@url"s,
      lat: ~x"./@lat"f,
      lon: ~x"./@lon"f,
      name: ~x"./@name"s,
      country: ~x"./@country"s,
      cc: ~x"./@cc"s,
      sponsor: ~x"./@sponsor"s,
      id: ~x"./@id"s,
      host: ~x"./@host"s
    )
  end

  @doc """
  Decodes `<server-config>` attributes.
  """
  @spec server_config(%{body: iodata()} | iodata()) :: map()
  def server_config(data) do
    data
    |> extract_body()
    |> xpath(
      ~x"//server-config",
      threadcount: ~x"./@threadcount"i,
      notonmap: ~x"./@notonmap"s,
      forcepingid: ~x"./@forcepingid"s,
      preferredserverid: ~x"./@preferredserverid"s,
      ignoreids: ~x"./@ignoreids"s
    )
  end

  @doc """
  Builds the combined test configuration map from `<server-config>`, `<download>`,
  `<upload>`, and `<client>`.
  """
  @spec config(%{body: iodata()} | iodata()) :: map()
  def config(data) do
    body = extract_body(data)
    srv_cfg = server_config(body)
    dl = download(body)
    ul = upload(body)
    cl = client(body)

    upload_sizes = Enum.slice(@upload_sizes, (ul.ratio - 1)..-1//1)
    size_count = length(upload_sizes)
    upload_count = round(ul.maxchunkcount / size_count)

    %{
      client: cl,
      ignore_servers: srv_cfg.ignoreids,
      sizes: %{upload: upload_sizes, download: @download_sizes},
      counts: %{upload: upload_count, download: dl.threads},
      threads: %{upload: ul.threads, download: srv_cfg.threadcount * 2},
      length: %{upload: ul.testlength, download: dl.testlength},
      upload_max: upload_count * size_count
    }
  end

  @doc """
  Decodes `<licensekey>` text.
  """
  @spec license(%{body: iodata()} | iodata()) :: String.t()
  def license(data) do
    data
    |> extract_body()
    |> xpath(~x"//licensekey/text()"s)
  end

  @doc """
  Decodes `<odometer>` attributes.
  """
  @spec odometer(%{body: iodata()} | iodata()) :: map()
  def odometer(data) do
    data
    |> extract_body()
    |> xpath(
      ~x"//odometer",
      start: ~x"./@start"i,
      rate: ~x"./@rate"i
    )
  end

  @doc """
  Decodes `<download>` attributes.
  """
  @spec download(%{body: iodata()} | iodata()) :: map()
  def download(data) do
    data
    |> extract_body()
    |> xpath(
      ~x"//download",
      testlength: ~x"./@testlength"i,
      initialtest: ~x"./@initialtest"s,
      mintestsize: ~x"./@mintestsize"s,
      threads: ~x"./@threadsperurl"i
    )
  end

  @doc """
  Decodes `<upload>` attributes.
  """
  @spec upload(%{body: iodata()} | iodata()) :: map()
  def upload(data) do
    data
    |> extract_body()
    |> xpath(
      ~x"//upload",
      testlength: ~x"./@testlength"i,
      ratio: ~x"./@ratio"i,
      initialtest: ~x"./@initialtest"i,
      mintestsize: ~x"./@mintestsize"s,
      threads: ~x"./@threads"i,
      maxchunksize: ~x"./@maxchunksize"s,
      maxchunkcount: ~x"./@maxchunkcount"i
    )
  end

  @doc """
  Decodes `<latency>` attributes.
  """
  @spec latency(%{body: iodata()} | iodata()) :: map()
  def latency(data) do
    data
    |> extract_body()
    |> xpath(
      ~x"//latency",
      testlength: ~x"./@testlength"i,
      waittime: ~x"./@waittime"i,
      timeout: ~x"./@timeout"i
    )
  end

  @doc """
  Decodes `<socket-download>` attributes.
  """
  @spec socket_download(%{body: iodata()} | iodata()) :: map()
  def socket_download(data) do
    data
    |> extract_body()
    |> xpath(
      ~x"//socket-download",
      testlength: ~x"./@testlength"i,
      initialthreads: ~x"./@initialthreads"i,
      minthreads: ~x"./@minthreads"i,
      maxthreads: ~x"./@maxthreads"i,
      threadratio: ~x"./@threadratio"s,
      maxsamplesize: ~x"./@maxsamplesize"i,
      minsamplesize: ~x"./@minsamplesize"i,
      startsamplesize: ~x"./@startsamplesize"i,
      startbuffersize: ~x"./@startbuffersize"i,
      bufferlength: ~x"./@bufferlength"i,
      packetlength: ~x"./@packetlength"i,
      readbuffer: ~x"./@readbuffer"i
    )
  end

  @doc """
  Decodes `<socket-upload>` attributes.
  """
  @spec socket_upload(%{body: iodata()} | iodata()) :: map()
  def socket_upload(data) do
    data
    |> extract_body()
    |> xpath(
      ~x"//socket-upload",
      testlength: ~x"./@testlength"i,
      initialthreads: ~x"./@initialthreads"s,
      minthreads: ~x"./@minthreads"s,
      maxthreads: ~x"./@maxthreads"i,
      threadratio: ~x"./@threadratio"s,
      maxsamplesize: ~x"./@maxsamplesize"i,
      minsamplesize: ~x"./@minsamplesize"i,
      startsamplesize: ~x"./@startsamplesize"i,
      startbuffersize: ~x"./@startbuffersize"i,
      bufferlength: ~x"./@bufferlength"i,
      packetlength: ~x"./@packetlength"i,
      disabled: ~x"./@disabled"s
    )
    |> Map.update!(:disabled, &(&1 == "true"))
  end

  @doc """
  Decodes `<socket-latency>` attributes.
  """
  @spec socket_latency(%{body: iodata()} | iodata()) :: map()
  def socket_latency(data) do
    data
    |> extract_body()
    |> xpath(
      ~x"//socket-latency",
      testlength: ~x"./@testlength"i,
      waittime: ~x"./@waittime"i,
      timeout: ~x"./@timeout"i
    )
  end

  # Keeps backwards compatibility if any external caller relied on these helpers
  @doc false
  def to_integer(data), do: data |> to_string() |> String.to_integer()

  @doc false
  def to_float(data), do: data |> to_string() |> String.to_float()

  defp extract_body(%{body: body}), do: body
  defp extract_body(body), do: body
end
