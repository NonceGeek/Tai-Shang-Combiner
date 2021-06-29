defmodule TaiShang.NFTPlusFetcher do
  @moduledoc """
    Interact with erc721 Contract and Evidence Contract.
    Example Evidence Contract: "0xB942FA2273C7Bce69833e891BDdFd7212d2dA415"
    Example Erc721 Contract: "0x962c0940d72E7Db6c9a5F81f1cA87D8DB2B82A23"
  """

  alias TaiShang.KeyGenerator

  @func %{
    balance_of: "balanceOf(address)",
    token_of_owner_by_index: "tokenOfOwnerByIndex(address, uint256)",
    token_uri: "tokenURI(uint256)",
    get_evidence_by_key: "getEvidenceByKey(string)"
  }

  def get_nft_plus_balance(chain_id, evi_contract_addr, erc721_contract_addr, addr_str) do
    erc721_balance = get_erc721_balance(erc721_contract_addr, addr_str)
    Enum.map(erc721_balance, fn %{token_id: token_id} = basic_info ->
      extra_info = get_extra_info(
        chain_id,
        evi_contract_addr,
        erc721_contract_addr,
        token_id)
      Map.put(basic_info, :extra_info, extra_info)
    end)
  end

  @spec get_erc721_balance(binary, binary) :: list
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

  def get_extra_info(chain_id, evi_contract_addr, erc721_contract_addr, token_id) do
    unique_token_id = KeyGenerator.gen_unique_token_id(chain_id, erc721_contract_addr, token_id)
    basic_info = get_evidence_by_key(evi_contract_addr, unique_token_id)
    gene =
      evi_contract_addr
      |> get_evidence_by_key(KeyGenerator.gen_key(unique_token_id, :gene))
    parent = get_evidence_by_key(evi_contract_addr, KeyGenerator.gen_key(unique_token_id, :parent))
    %{
      basic_info: basic_info,
      gene: gene,
      parent: parent
    }
  end

  # +---------------------+
  # | Contract Interactor |
  # +---------------------+

  def get_evidence_by_key(contract_addr, key) do
    data =
      get_data(
        @func.get_evidence_by_key,
        [key])
    {:ok, value} =
      Ethereumex.HttpClient.eth_call(%{
        data: data,
        to: contract_addr})

    value
    |> hex_to_bin()
    |> ABI.TypeDecoder.decode_raw(
      [:string, {:array, :address}, {:array, :address}]
    )
    |> Enum.fetch!(0)
    |> handle_evi()
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

    hex_to_str(uri)
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

  # +-------------+
  # | Basic Funcs |
  # +-------------+
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
    |> hex_to_bin()
    |> ABI.TypeDecoder.decode_raw([{:uint, 256}])
    |> List.first()
  end

  def hex_to_str(hex) do
    hex
    |> hex_to_bin()
    |> ABI.TypeDecoder.decode_raw([:string])
    |> List.first()
  end

  def hex_to_bin(hex) do
    hex
    |> String.slice(2..-1)
    |> Base.decode16!(case: :lower)
  end

  def handle_evi(""), do: nil
  def handle_evi(evi) do
    evi
    |> String.replace("\t", "")
    |> String.replace("'","\"")
    |> String.replace("/", "")
    |> Poison.decode!()
  end

end
