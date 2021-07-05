defmodule TaiShangWeb.GeneratorLive do
  use TaiShangWeb, :live_view
  alias TaiShang.{KeyGenerator, NFTPlusInteractor, NFTPlusFetcher}
  alias TaiShang.{Account, Chain}
  alias TaiShang.Gene.{Generator, Rules}
  alias Utils.StructTranslator
  alias Utils.RandGen

  @doc """

  """

  @impl true
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(form: :payloads)
      |> assign(erc721_addr: "0x962c0940d72E7Db6c9a5F81f1cA87D8DB2B82A23")
      |> assign(evidence_addr: "0xB942FA2273C7Bce69833e891BDdFd7212d2dA415")
      |> assign(chain: Chain.get_default_chain())
      |> assign(acct: Account.get_default_acct())
      |> assign(effective_timestamp: Integer.to_string(RandGen.get_timestamp()))
      |> assign(expir_timestamp: "forever")
      |> set_nil_assigns()
    }
  end

  def set_nil_assigns(socket) do
    socket
    |> assign(limits: nil)
    |> assign(rules: nil)
    |> assign(token_id: nil)
    |> assign(token_uri: nil)
    |> assign(token_params: nil)
    |> assign(token_parent: nil)
    |> assign(token_parent_key: nil)
    |> assign(token_parent_tx_id: nil)
    |> assign(token_gene: nil)
    |> assign(token_gene_key: nil)
    |> assign(token_gene_tx_id: nil)
    |> assign(token_gen_name: nil)
    |> assign(token_gen_description: nil)
    |> assign(token_gen_effective_timestamp: nil)
    |> assign(token_gen_expir_timestamp: nil)
    |> assign(token_gen_first_owner: nil)
    |> assign(token_gen_url: nil)
    |> assign(basic_info_key: nil)
    |> assign(basic_info_tx_id: nil)
  end

  @impl true
  def handle_event(
        "change_v",
        %{"_target" => ["erc721_addr"], "erc721_addr" => erc721_addr},
        socket
      ) do
    {:noreply,
     socket
     |> assign(erc721_addr: erc721_addr)}
  end

  def handle_event(
        "change_v",
        %{"_target" => ["evidence_addr"], "evidence_addr" => evidence_addr},
        socket
      ) do
    {:noreply,
     socket
     |> assign(evidence_addr: evidence_addr)}
  end

  @doc """
    generate => add_extra_parents => add_extra_genes => add_extra_infos
  """
  def handle_event(
        "generate",
        params,
        %{
          assigns: %{
            chain: chain,
            acct: acct
          }
        } = socket
      ) do
    %{
      erc721_addr: erc_721_addr,
      receiver_addr: receiver_addr,
      uri: uri,
      existed_token_id: existed_token_id
    } = params_atom = StructTranslator.to_atom_struct(params)

    {token_id, uri} =
      if existed_token_id == "" do
        {:ok, _tx_id} = NFTPlusInteractor.mint_nft(chain, acct, erc_721_addr, receiver_addr, uri)
        token_id = NFTPlusFetcher.fetch_best_nft(erc_721_addr, receiver_addr)
        Process.send_after(self(), :add_extra_parents, 1000)
        {token_id, uri}
      else
        uri = NFTPlusInteractor.token_uri(erc_721_addr, String.to_integer(existed_token_id))
        Process.send_after(self(), :add_extra_parents, 1000)
        {existed_token_id, uri}
      end

    {
      :noreply,
      socket
      |> assign(token_id: token_id)
      |> assign(token_params: params_atom)
      |> assign(token_uri: uri)
    }
  end

  def handle_event(
        "fetch_rules_and_limits",
        %{
          "erc721" => erc721_addr,
          "evidencer" => evidence_addr
        },
        %{assigns: %{chain: chain}} = socket
      ) do
    {rules, limits} =
      Rules.fetch_rules_and_limits(
        chain,
        erc721_addr,
        evidence_addr
      )

    {:noreply,
     socket
     |> assign(limits: limits)
     |> assign(rules: rules)}
  end

  def handle_event(_, _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(:add_extra_parents, %{assigns: assigns} = socket) do
    {chain, erc721_addr, evidence_addr, token_id, acct} =
      decompose_assigns(assigns)

    %{config: %{"chain_id" => chain_id}} = chain

    %{parent_token_ids: parent_token_ids} = assigns.token_params

    key =
      chain_id
      |> KeyGenerator.gen_unique_token_id(erc721_addr, token_id)
      |> KeyGenerator.gen_key(:parent)

    value =
      parent_token_ids
      |> String.replace("\"", "'")

    {:ok, tx_id} = NFTPlusInteractor.new_evidence_by_key(chain, acct, evidence_addr, key, value)

    Process.send_after(self(), :add_extra_genes, 1000)

    {
      :noreply,
      socket
      |> assign(token_parent: parent_token_ids)
      |> assign(token_parent_key: key)
      |> assign(token_parent_tx_id: tx_id)
    }
  end

  def handle_info(:add_extra_genes, %{assigns: assigns} = socket) do
    {chain, erc721_addr, evidence_addr, token_id, acct} =
      decompose_assigns(assigns)

    %{config: %{"chain_id" => chain_id}} = chain

    key =
      chain_id
      |> KeyGenerator.gen_unique_token_id(erc721_addr, token_id)
      |> KeyGenerator.gen_key(:gene)

    result = Rules.fetch_rules_and_limits(chain, erc721_addr, evidence_addr)

    case result do
      {:error, _msg} ->
        Process.send_after(self(), :add_extra_infos, 1000)
        {:noreply, socket}

      _ ->
        {rules_mixed, limits_mixed} = result

        value =
          rules_mixed
          |> Generator.generate_gen(limits_mixed)
          |> :binary.bin_to_list()
          |> Poison.encode!()

        {:ok, tx_id} =
          NFTPlusInteractor.new_evidence_by_key(chain, acct, evidence_addr, key, value)

        Process.send_after(self(), :add_extra_infos, 1000)

        {
          :noreply,
          socket
          |> assign(token_gene: value)
          |> assign(token_gene_key: key)
          |> assign(token_gene_tx_id: tx_id)
        }
    end
  end

  def handle_info(:add_extra_infos, %{assigns: assigns = %{token_params: token_params}} = socket) do
    {chain, erc721_addr, evidence_addr, token_id, acct} =
      decompose_assigns(assigns)

    %{config: %{"chain_id" => chain_id}} = chain
    key = KeyGenerator.gen_unique_token_id(chain_id, erc721_addr, token_id)

    value =
      %{}
      |> Map.put(:name, token_params.token_name)
      |> Map.put(:description, token_params.token_description)
      |> Map.put(:first_owner, token_params.receiver_addr)
      |> Map.put(:url, token_params.token_url)
      |> Map.put(:effective_date, String.to_integer(token_params.effective_timestamp))
      |> Map.put(:expiration_date, handle_expir(token_params.expir_timestamp))
      |> Poison.encode!()
      |> String.replace("\"", "'")

    {:ok, tx_id} = NFTPlusInteractor.new_evidence_by_key(chain, acct, evidence_addr, key, value)

    {
      :noreply,
      socket
      |> assign(token_gen_name: token_params.token_name)
      |> assign(token_gen_description: token_params.token_description)
      |> assign(token_gen_url: token_params.token_url)
      |> assign(token_gen_effective_timestamp: token_params.effective_timestamp)
      |> assign(token_gen_expir_timestamp: token_params.expir_timestamp)
      # first owner is receiver
      |> assign(token_gen_first_owner: token_params.receiver_addr)
      |> assign(basic_info_key: key)
      |> assign(basic_info_tx_id: tx_id)
    }
  end

  def handle_expir(expir_timestamp) do
    if Integer.parse(expir_timestamp) == :error do
      expir_timestamp
    else
      String.to_integer(expir_timestamp)
    end
  end

  def decompose_assigns(assigns) do
    chain = assigns.chain
    erc721_addr = assigns.erc721_addr
    evidence_addr = assigns.evidence_addr
    token_id = assigns.token_id
    acct = assigns.acct
    {chain, erc721_addr, evidence_addr, token_id, acct}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end
