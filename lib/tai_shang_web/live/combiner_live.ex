defmodule TaiShangWeb.CombinerLive do
  alias TaiShang.{Chain, NFTPlusFetcher, NFTPlusInteractor, Account}
  alias TaiShang.Gene.{Combiner, Rules}
  alias Utils.{RandGen, StructTranslator}
  alias TaiShang.KeyGenerator
  use TaiShangWeb, :live_view

  @impl true

  @combiner_addr "0xE07D758AC318A84CCdf5E50eb79A2487C90B798B"
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(combiner_addr: @combiner_addr)
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
    |> assign(token_infos: nil)
    |> assign(gene_generated: nil)
    |> assign(gene_rules: nil)
    |> assign(gene_limits: nil)
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
    |> assign(all_in_combiner_addr: nil)
  end

  @impl true
  def handle_event("view", _params, socket), do: {:noreply, assign(socket, clicked: :view)}
  def handle_event("comb", _params, socket), do: {:noreply, assign(socket, clicked: :comb)}

  def handle_event("combine", params, socket) do
    do_handle_event(socket.assigns.clicked, params, socket)
  end

  def do_handle_event(:view, params, socket) do
    chain = Chain.get_default_chain()

    %{
      token_list: token_id_list_str,
      erc721_addr: erc721_addr,
      evidence_addr: evidence_addr
    } =
      StructTranslator.to_atom_struct(params)

    token_id_list = Poison.decode!(token_id_list_str)

    token_infos =
      chain.config["chain_id"]
      |> NFTPlusFetcher.fetch_tokens_info(
        evidence_addr,
        erc721_addr,
        token_id_list
      )
      |> Enum.map(fn token_info ->
        in_combiner_addr = String.downcase(token_info.owner) == String.downcase(@combiner_addr)
        Map.put(token_info, :in_combiner_addr, in_combiner_addr)
      end)

    all_in_combiner_addr? =
      Enum.reduce(token_infos, true, fn %{in_combiner_addr: in_combiner_addr?}, acc ->
        acc and in_combiner_addr?
      end)

    {
      :noreply,
      socket
      |> assign(token_infos: token_infos)
      |> assign(all_in_combiner_addr: all_in_combiner_addr?)
    }
  end

  def do_handle_event(:comb, params, socket) do
    chain = Chain.get_default_chain()

    %{
      token_list: token_id_list_str,
      erc721_addr: erc721_addr,
      evidence_addr: evidence_addr
    } =
      params_atom = StructTranslator.to_atom_struct(params)

    token_id_list = Poison.decode!(token_id_list_str)

    token_infos =
      chain.config["chain_id"]
      |> NFTPlusFetcher.fetch_tokens_info(
        evidence_addr,
        erc721_addr,
        token_id_list
      )
      |> Enum.map(fn token_info ->
        in_combiner_addr = String.downcase(token_info.owner) == String.downcase(@combiner_addr)
        Map.put(token_info, :in_combiner_addr, in_combiner_addr)
      end)

    all_in_combiner_addr? =
      Enum.reduce(token_infos, true, fn %{in_combiner_addr: in_combiner_addr?}, acc ->
        acc and in_combiner_addr?
      end)

    {rules, limits} = Rules.fetch_rules_and_limits(chain, erc721_addr, evidence_addr)
    # create new token by old one
    genes =
      Enum.map(token_infos, fn %{extra_info: %{gene: gene}} ->
        :binary.list_to_bin(gene)
      end)

    output_gene =
      genes
      |> Combiner.combine_genes(rules, limits)
      |> :binary.bin_to_list()

    if all_in_combiner_addr? == true do
      IO.puts("ddddd")
      Process.send_after(self(), :mint_token, 1000)

      {
        :noreply,
        socket
        |> assign(token_infos: token_infos)
        |> assign(gene_rules: rules)
        |> assign(gene_limits: limits)
        |> assign(gene_generated: output_gene)
        |> assign(token_params: params_atom)
      }
    else
      IO.puts("kkkkk")

      {
        :noreply,
        socket
        |> assign(token_infos: token_infos)
        |> assign(gene_rules: rules)
        |> assign(gene_limits: limits)
        |> assign(gene_generated: output_gene)
        |> assign(token_params: params_atom)
        |> put_flash(
          :error,
          "Please Transfer The token U want to combine to the Combiner Addr First!"
        )
      }
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(:mint_token, %{assigns: assigns} = socket) do
    {chain, erc721_addr, _evidence_addr, _token_id, acct} =
      decompose_assigns(assigns)

    receiver_addr = assigns.token_params.receiver_addr
    uri = assigns.token_params.uri

    {:ok, _tx_id} =
      NFTPlusInteractor.mint_nft(
        chain,
        acct,
        erc721_addr,
        assigns.token_params.receiver_addr,
        uri
      )

    token_id = NFTPlusFetcher.fetch_best_nft(erc721_addr, receiver_addr)
    Process.send_after(self(), :add_extra_parents, 1000)

    {
      :noreply,
      socket
      |> assign(token_id: token_id)
      |> assign(token_uri: uri)
    }
  end

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

    value = Poison.encode!(assigns.gene_generated)

    {:ok, tx_id} = NFTPlusInteractor.new_evidence_by_key(chain, acct, evidence_addr, key, value)

    Process.send_after(self(), :add_extra_infos, 1000)

    {
      :noreply,
      socket
      |> assign(token_gene: value)
      |> assign(token_gene_key: key)
      |> assign(token_gene_tx_id: tx_id)
    }
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
end
