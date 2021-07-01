defmodule TaiShang.NFTPlusFetcher do
  @moduledoc """
    Fetch NFT-Plus
  """

  alias TaiShang.{KeyGenerator, NFTPlusInteractor}



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
    balance = NFTPlusInteractor.balance_of(contract_addr, addr_str)
    0..(balance-1)
    |> Enum.map(fn index ->
      NFTPlusInteractor.token_of_owner_by_index(
        contract_addr,
        addr_str,
        index)
    end)
    |> Enum.map(fn token_id ->
      %{
        token_id: token_id,
        uri: NFTPlusInteractor.token_uri(contract_addr, token_id)
      }
    end)
  end

  def get_extra_info(chain_id, evi_contract_addr, erc721_contract_addr, token_id) do
    unique_token_id =
      KeyGenerator.gen_unique_token_id(
        chain_id,
        erc721_contract_addr,
        token_id)
    basic_info =
      NFTPlusInteractor.get_evidence_by_key(
        evi_contract_addr,
        unique_token_id
      )
    gene =
      NFTPlusInteractor.get_evidence_by_key(
        evi_contract_addr,
        KeyGenerator.gen_key(unique_token_id, :gene)
      )
    parent = NFTPlusInteractor.get_evidence_by_key(evi_contract_addr, KeyGenerator.gen_key(unique_token_id, :parent))
    %{
      basic_info: basic_info,
      gene: gene,
      parent: parent
    }
  end

end
