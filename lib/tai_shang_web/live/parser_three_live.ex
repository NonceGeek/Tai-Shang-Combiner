defmodule TaiShangWeb.ParserThreeLive do
  use TaiShangWeb, :live_view
  alias TaiShang.{Chain, NFTPlusFetcher, Gene}
  alias TaiShang.Gene.Rules
  @impl true

  @base2_mapping [
    {"英俊的", "相貌平凡的"},
    {"热情的", "冷峻的"},
    {"善于沟通的", "笨嘴笨舌的"},
    {"大方的", "节俭的"},
    {"长发飘飘的", "短发的"},
    {"个子很高的", "矮个的"},
    {"衣冠楚楚的", "不修边幅的"},
    {"男性", "女性"}
  ]
  @base10_mapping [
    "武力",
    "魅力",
    "智力",
    "魔法力",
    "音乐能力",
    "敏捷"
  ]
  def mount(
        %{
          "addr" => addr,
          "evidence_addr" => evidence_addr,
          "erc721_addr" => erc721_addr
        },
        _session,
        socket
      ) do
    %{config: %{"chain_id" => chain_id}} = chain = Chain.get_default_chain()

    balances =
      NFTPlusFetcher.get_nft_plus_balance(
        chain_id,
        evidence_addr,
        erc721_addr,
        addr
      )

    {rules, _limits} = Rules.fetch_rules_and_limits(chain, erc721_addr, evidence_addr)

    balances_handled =
      Enum.map(balances, fn %{
                              extra_info: %{
                                gene: gene,
                                basic_info: %{
                                  "expiration_date" => expir_timestamp,
                                  "effective_date" => effective_timestamp
                                }
                              }
                            } = balance ->
        life = cal_life(expir_timestamp, effective_timestamp)

        gene_handled =
          gene
          |> Gene.parse(rules)
          |> to_spec()

        balance
        |> Map.put(:gene_handled, gene_handled)
        |> Map.put(:life, life)
      end)

    {:ok,
     socket
     |> assign(balances: balances_handled)
     |> assign(chain: chain)
     |> assign(erc721_addr: erc721_addr)}
  end

  def cal_life("forever", _), do: "无限"

  def cal_life(expir_timestamp, effective_timestamp) do
    div(expir_timestamp - effective_timestamp, 3600 * 24)
  end

  def to_spec({base2_gene, base10_gene}) do
    base2_spec =
      @base2_mapping
      |> Enum.zip(base2_gene)
      |> Enum.map(fn {base2_spec, base2_gene} ->
        elem(base2_spec, base2_gene)
      end)

    base10_spec =
      @base10_mapping
      |> Enum.zip(base10_gene)
      |> Enum.into(%{})

    {base2_spec, base10_spec}
  end
end
