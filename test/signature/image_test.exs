defmodule SignatureImageTest do
  use ExUnit.Case
  alias Signature.{Item, Html, Image}

  setup do
    item = Item.new(%{name: "Michail Gumbs", title: "IT Software Engineer",
            tel: "(+599 318 4439)", adres: "The Mall, Sint Eustatius, Caribish Nederland", email: "m.gumbs@statiagov.com"})
    html = Html.image(item)
    on_exit fn ->
      File.rm_rf(".temp")
    end
    {:ok, html: html, item: item}
  end

  test "can convert html to image", %{html: html, item: item} do
     assert_file_exists Image.convert({item, html})
  end

  defp assert_file_exists({:ok, temp_image}) do
     case File.stat(temp_image) do
       {:ok, %File.Stat{size: size}} -> assert size > 0
       _ -> false
     end
  end
end
