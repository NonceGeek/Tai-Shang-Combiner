defmodule TaiShang.KeyGenerator do
  @moduledoc """
    Generate keys in NFT-PLUS.
  """

  @spec gen_key(String.t(), Atom.t()) :: String.t()
  def gen_key(unique_id, ele), do: "#{unique_id}##{Atom.to_string(ele)}"

  def gen_contract_full(chain_id, erc721_contract_addr) do
    "#{chain_id}:#{erc721_contract_addr}"
  end

  def gen_unique_token_id(chain_id, erc721_contract_addr, token_id) do
    chain_id
    |> gen_contract_full(erc721_contract_addr)
    |> Kernel.<>(":#{token_id}")
  end
end
