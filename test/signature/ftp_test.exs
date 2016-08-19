defmodule SignatureFtpTest do
  use ExUnit.Case
  alias Signature.{Ftp, PathAgent}

  setup do
    file_name = "arms.jpg"
    path = Path.expand("priv/#{file_name}", File.cwd!)
    :inets.start
    {:ok, pid} = :inets.start(:ftpc, host: PathAgent.get.ftp_host)
    {:ok, path: path, file_name: file_name, pid: pid}
  end

  test "can upload an image to the server", %{path: path, file_name: file, pid: pid} do
    assert {:ok, "http://statiagovernment.com/" <> _rest} =  Ftp.upload(pid, path)
  end
end
