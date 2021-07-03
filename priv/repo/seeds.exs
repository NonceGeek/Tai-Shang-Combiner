# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     TaiShang.Repo.insert!(%TaiShang.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias TaiShang.{Chain, Account}

payload =
  %{
    name: "Moonbeam",
    is_enabeld: true,
    adapter: "Ethereum",
    config: %{"chain_id"=> 1281}
  }

{:ok, chain} = Chain.create(payload)

priv =
  "5fb92d6e98884f76de468fa3f6278f8807c48bebc13595d45af5bdc4da702133"
  |> Base.decode16!(case: :mixed)
payload =
  %{
    addr: "0xf24FF3a9CF04c71Dbc94D0b566f7A27B94566cac",
    encrypted_privkey: priv,
    chain_id: chain.id
  }

{:ok, _acct} = Account.create(payload)
