defmodule SignatureRendererTest do
  use ExUnit.Case

  alias Signature.{Item, Html}

  test "can render passed in paramaters as html" do
    item = Item.new(%{name: "Dhr. A.L. (André) Brisset", title: "Supervisor Public Works",
            tel: "(+599 318 2835)", adres: "The Mall, Sint Eustatius, Caribish Nederland"})
    html = Html.image(item)

    assert html =~ item.name
    assert html =~ item.title
    assert html =~ item.tel
    assert html =~ item.adres
  end
end
