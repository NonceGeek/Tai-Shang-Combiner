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

# insert chain
payload =
  %{
    name: "Moonbeam",
    is_enabeld: true,
    adapter: "Ethereum",
    config: %{"chain_id"=> 1281}
  }

{:ok, chain} = Chain.create(payload)

# insert acct
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

# insert parsers
parser_1 =
  %{
    name: "parser_0x01",
    description: "basic parser",
    url: "https://0x01.nft.doge.university/#",
    chain_id: 1,
    example_addr: "0xB84DF36e58a31f98d6294420569c365e8e1acaCd"
  }
parser_2 =
  %{
    name: "parser_0x02",
    description: "Second Creation —— parser to present 'inherit' between nfts!",
    url: "https://0x02.nft.doge.university/#",
    type: "based_on_token_id",
    chain_id: 1,
    example_token_id: 14
  }

parser_3 =
  %{
    name: "parser_0x02",
    description: "Crypto Characters - parser to present 'gene' of nft!",
    url: "parser_0x03",
    chain_id: 1,
    example_addr: "0x6B8d4d35027C9F5a5CA269341e914ad72234aCbD"
  }

TaiShang.Parser.create(parser_1)
TaiShang.Parser.create(parser_2)
TaiShang.Parser.create(parser_3)
