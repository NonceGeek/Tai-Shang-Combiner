defmodule TaiShang.NFTPlusGenerator do
  @moduledoc """
    Generate extra info for exist NFT.
    or
    Generate new NFT with extra info.
  """
  alias TaiShang.KeyGenerator

  def gen_extra_info(property, chain_id, evi_contract_addr, erc721_contract_addr, token_id, info) do
    unique_token_id = KeyGenerator.gen_unique_token_id(chain_id, erc721_contract_addr, token_id)

    if is_nil(property) do
      do_gen_extra_info(evi_contract_addr, unique_token_id, info)
    else
      key = KeyGenerator.gen_key(unique_token_id, property)
      do_gen_extra_info(evi_contract_addr, key, info)
    end
  end

  def do_gen_extra_info(evi_contract_addr, key, info) do
  end
end
