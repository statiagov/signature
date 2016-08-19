defmodule SignatureMailTest do
  use ExUnit.Case
  use Bamboo.Test
  alias Signature.{Item, Mail, Mailer}

  setup do
    item = Item.new(%{name: "Michail Gumbs", title: "IT Software Engineer",
            tel: "(+599 318 2835)", adres: "The Mall, Sint Eustatius, Caribish Nederland",
            email: "m.gumbs@statiagov.com"
            })
    link = "http://example.com/file.jpg"
    {:ok, %{item: item, link: link}}
  end

  test "signature instructions", %{item: item, link: link} do
    email = Mail.instructions({item, link})

    assert email.to == item.email
    assert email.html_body =~ item.name

    email |> Mailer.deliver_now

    assert_delivered_email email
  end
end
