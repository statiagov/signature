defmodule SignatureItemTest do
  use ExUnit.Case

  @valid_attrs %{name: "Dhr. A.L. (André) Brisset", title: "Supervisor Public Works",
          tel: "(+599 318 2835)", adres: "The Mall, Sint Eustatius, Caribish Nederland", email: "uisnech@gmail.com"}

 @invalid_attrs %{}

  test "valid struct" do
    item = Signature.Item.new(@valid_attrs)
    assert Vex.valid? item
  end

  test "invalid struct" do
    item = Signature.Item.new(@invalid_attrs)
    refute Vex.valid? item
  end
end
