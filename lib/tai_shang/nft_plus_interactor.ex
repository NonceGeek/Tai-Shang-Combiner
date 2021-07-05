defmodule TaiShang.NFTPlusInteractor do
  @moduledoc """
    Interact with erc721 Contract and Evidence Contract.
    Example Evidence Contract: "0xB942FA2273C7Bce69833e891BDdFd7212d2dA415"
    Example Erc721 Contract: "0x962c0940d72E7Db6c9a5F81f1cA87D8DB2B82A23"
  """

  alias TaiShang.{Chain, Account}
  alias TaiShang.Ethereum.Transaction
  alias Ethereumex.HttpClient
  alias Utils.{Crypto, TypeTranslator}

  @func %{
    balance_of: "balanceOf(address)",
    token_of_owner_by_index: "tokenOfOwnerByIndex(address, uint256)",
    token_uri: "tokenURI(uint256)",
    get_evidence_by_key: "getEvidenceByKey(string)",
    new_evidence_by_key: "newEvidenceByKey(string, string)",
    mint_nft: "mintNft(address, string)",
    owner_of: "ownerOf(uint256)"
  }

  # +----------------------+
  # | value changed funcs. |
  # +----------------------+

  def mint_nft(
        chain,
        %{
          addr: from,
          encrypted_privkey: encrypted_privkey
        },
        contract_addr,
        receiver_addr,
        uri
      ) do
    priv = Crypto.decrypt_key(encrypted_privkey)
    mint_nft(chain, priv, from, contract_addr, receiver_addr, uri)
  end

  def mint_nft(chain, priv, from, contract_addr, receiver_addr, uri) do
    {:ok, addr_bytes} = TypeTranslator.hex_to_bytes(receiver_addr)

    str_data =
      get_data(
        @func.mint_nft,
        [addr_bytes, uri]
      )

    send_raw_tx(chain, priv, from, contract_addr, str_data)
  end

  @doc """
    two funcs:
      set new evi by acct;
      set new evi by priv and addr.
  """
  @spec new_evidence_by_key(Chain.t(), Account.t(), String.t(), String.t(), String.t()) ::
          {:ok, String.t()}
  def new_evidence_by_key(
        chain,
        %{
          addr: from,
          encrypted_privkey: encrypted_privkey
        },
        contract_addr,
        key,
        value
      ) do
    priv = Crypto.decrypt_key(encrypted_privkey)
    new_evidence_by_key(chain, priv, from, contract_addr, key, value)
  end

  @spec new_evidence_by_key(Chain.t(), Binary.t(), String.t(), String.t(), String.t(), String.t()) ::
          {:ok, String.t()}
  def new_evidence_by_key(chain, priv, from, contract_addr, key, value) do
    str_data =
      get_data(
        @func.new_evidence_by_key,
        [key, value]
      )

    send_raw_tx(chain, priv, from, contract_addr, str_data)
  end

  def send_raw_tx(%{config: %{"chain_id" => chain_id}}, priv, from, contract_addr, str_data) do
    {:ok, data_bin} = TypeTranslator.hex_to_bytes(str_data)
    unsigned_tx = Transaction.build_tx(from, contract_addr, data_bin)
    signed_tx = Transaction.sign(unsigned_tx, priv, chain_id)
    raw_tx = Transaction.signed_tx_to_raw_tx(signed_tx)
    HttpClient.eth_send_raw_transaction(raw_tx)
  end

  # +------------------+
  # | constrant funcs. |
  # +------------------+
  def get_evidence_by_key(contract_addr, key) do
    data =
      get_data(
        @func.get_evidence_by_key,
        [key]
      )

    {:ok, value} =
      Ethereumex.HttpClient.eth_call(%{
        data: data,
        to: contract_addr
      })

    value
    |> TypeTranslator.hex_to_bin()
    |> ABI.TypeDecoder.decode_raw([:string, {:array, :address}, {:array, :address}])
    |> Enum.fetch!(0)
    |> handle_evi()
  end

  def token_uri(contract_addr, token_id) do
    data =
      get_data(
        @func.token_uri,
        [token_id]
      )

    {:ok, uri} =
      Ethereumex.HttpClient.eth_call(%{
        data: data,
        to: contract_addr
      })

    TypeTranslator.hex_to_str(uri)
  end

  def token_of_owner_by_index(contract_addr, addr_str, index) do
    {:ok, addr_bytes} = TypeTranslator.hex_to_bytes(addr_str)

    data =
      get_data(
        @func.token_of_owner_by_index,
        [addr_bytes, index]
      )

    {:ok, token_id} =
      Ethereumex.HttpClient.eth_call(%{
        data: data,
        to: contract_addr
      })

    TypeTranslator.hex_to_int(token_id)
  end

  def owner_of(contract_addr, token_id) do
    data =
      get_data(
        @func.owner_of,
        [token_id]
      )

    {:ok, addr_raw} =
      Ethereumex.HttpClient.eth_call(%{
        data: data,
        to: contract_addr
      })

    TypeTranslator.get_addr(addr_raw)
  end

  @spec balance_of(String.t(), String.t()) :: Integer.t()
  def balance_of(contract_addr, addr_str) do
    {:ok, addr_bytes} = TypeTranslator.hex_to_bytes(addr_str)
    data = get_data(@func.balance_of, [addr_bytes])

    {:ok, balance_hex} =
      Ethereumex.HttpClient.eth_call(%{
        data: data,
        to: contract_addr
      })

    TypeTranslator.hex_to_int(balance_hex)
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

  def handle_evi(""), do: nil

  def handle_evi(evi) do
    result =
      evi
      |> String.replace("\t", "")
      |> String.replace("'", "\"")
      |> String.replace("/", "")
      |> Poison.decode()

    case result do
      {:ok, payload} ->
        payload

      {:error, _error} ->
        evi
    end
  end
end
