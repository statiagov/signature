defmodule SignatureProcessorTest do
  use ExUnit.Case
  alias Signature.{Item, Html, Image, Processor, PathAgent}

  test "runs through all processes" do
    {:ok, pid} = :inets.start(:ftpc, host: PathAgent.get.ftp_host)
    item = Item.new(%{name: "Dhr. A.L. (André) Brisset", title: "Supervisor Public Works",
            tel: "(+599 318 2835)", email: "dre@statiagov.com", adres: "The Mall, Sint Eustatius, Caribish Nederland"})

    Processor.start(pid, item)
  end
end
