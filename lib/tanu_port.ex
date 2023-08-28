defmodule TanuPort do

  @doc """
  指定したネットワーク内のホストのアドレスを検出
  """
  def ip_sweep(network_ip) do
    sweeper(self(), network_ip)

    receive do
      {:done, results} ->
        results
    end
  end

  defp sweeper(pid, network_ip) do
    results = []

    Enum.each(1..254, fn ip ->
      spawn(fn ->
        case System.cmd("ping", ["-c", "1", "#{network_ip}.#{ip}"]) do
          {_, 0}  ->  send(pid, {:child, "#{network_ip}.#{ip}"})
          _       ->  {}
        end
      end)
    end)

    loop(pid, results)
  end

  defp loop(pid, results) do
    receive do
      {:child, address} ->
        new_results = [address | results]
        loop(pid, new_results)
    after
        5000 -> send(pid, {:done, results})
    end
  end

  @doc """
  ホストが指定したポートを開放されているか検出します。
  """
  def port_scanner(ip_list, port_list) when is_list(ip_list) and is_list(port_list) do
    ip_list
    |> Flow.from_enumerable()
    |> Flow.map(fn ip ->
      port_list
      |> Flow.from_enumerable()
      |> Flow.map(fn port ->
        String.to_charlist(ip)
        |> scanner(port)
      end)
    end)
    |> Enum.map(fn ip -> IO.puts ip end)
  end

  def port_scanner(ip_list, port) when is_list(ip_list) do
    ip_list
    |> Flow.from_enumerable()
    |> Flow.map(fn ip ->
      String.to_charlist(ip)
      |> scanner(port)
    end)
    |> Enum.map(fn ip -> IO.puts ip end)
  end

  def port_scanner(ip, port_list) when is_list(port_list) do
    port_list
    |> Flow.from_enumerable()
    |> Flow.map(fn port ->
      String.to_charlist(ip)
      |> scanner(port)

    end)
    |> Enum.map(fn ip -> IO.puts ip end)
  end

  def port_scanner(ip, port)  do
    String.to_charlist(ip)
    |> scanner(port)
    |> IO.puts
  end

  defp scanner(ip, port) do
    case :gen_tcp.connect(ip, port, [:binary, active: false]) do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        "#{ip}\t: Opened port #{port}"

      {:error, _} ->
        "#{ip}\t: Closed port on #{port}"
    end
  end

  def benchmark() do
    {time, _result} = :timer.tc(fn -> port_scanner(TanuPort.ip_sweep("192.168.0"), 22) end)
    IO.puts("Execution time: #{time} microseconds")
  end

end
