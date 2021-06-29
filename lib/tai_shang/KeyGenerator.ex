defmodule TaiShang.KeyGenerator do
  @moduledoc """
    Generate keys in NFT-PLUS.
  """

  @spec gen_key(String.t(), Atom.t()) :: String.t()
  def gen_key(unique_token_id, ele), do: "#{unique_token_id}##{Atom.to_string(ele)}"

  def gen_unique_token_id(chain_id, erc721_contract_addr, token_id) do
    "#{chain_id}:#{erc721_contract_addr}:#{token_id}"
  end
end
