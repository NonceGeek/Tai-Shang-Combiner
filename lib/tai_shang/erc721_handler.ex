defmodule TaiShang.NFTPlusHandler do
  @moduledoc """
    Interact with erc721 Contract and Evidence Contract.
  """

  @func %{
    balance_of: "balanceOf(address)",
    token_of_owner_by_index: "tokenOfOwnerByIndex(address, uint256)",
    token_uri: "tokenURI(uint256)"
  }

  def get_erc721_balance(contract_addr, addr_str) do
    balance = balance_of(contract_addr, addr_str)
    0..(balance-1)
    |> Enum.map(fn index ->
      token_of_owner_by_index(contract_addr, addr_str, index)
    end)
    |> Enum.map(fn token_id ->
      %{
        token_id: token_id,
        uri: token_uri(contract_addr, token_id)
      }
    end)
  end

  def token_uri(contract_addr, token_id) do
    data =
      get_data(
        @func.token_uri,
        [token_id])
    {:ok, uri} =
      Ethereumex.HttpClient.eth_call(%{
        data: data,
        to: contract_addr})

    TaiShang.Erc721Handler.hex_to_str(uri)
  end

  def token_of_owner_by_index(contract_addr, addr_str, index) do
    {:ok, addr_bytes} = addr_to_bytes(addr_str)
    data =
      get_data(
        @func.token_of_owner_by_index,
        [addr_bytes, index])
    {:ok, token_id} =
      Ethereumex.HttpClient.eth_call(%{
        data: data,
        to: contract_addr})

    hex_to_int(token_id)
  end

  @spec balance_of(String.t(), String.t()) :: Integer.t()
  def balance_of(contract_addr, addr_str) do
    {:ok, addr_bytes} = addr_to_bytes(addr_str)
    data = get_data(@func.balance_of, [addr_bytes])
    {:ok, balance_hex} = Ethereumex.HttpClient.eth_call(%{
      data: data,
      to: contract_addr
    })
    hex_to_int(balance_hex)
  end

  @spec get_data(String.t(), List.t()) :: String.t()
  def get_data(func_str, params) do
    payload =
      func_str
      |> ABI.encode(params)
      |> Base.encode16(case: :lower)

    "0x" <> payload
  end

  def addr_to_bytes(addr_str) do
    addr_str
    |> String.slice(2..-1)
    |> Base.decode16(case: :mixed)
  end
  def hex_to_int(hex) do
    hex
    |> String.slice(2..-1)
    |> Base.decode16!(case: :lower)
    |> ABI.TypeDecoder.decode_raw([{:uint, 256}])
    |> List.first()
  end

  def hex_to_str(hex) do
    hex
    |> String.slice(2..-1)
    |> Base.decode16!(case: :lower)
    |> ABI.TypeDecoder.decode_raw([:string])
    |> List.first()
  end
end
