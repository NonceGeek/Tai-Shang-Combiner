defmodule TaiShang.Generator do
  @moduledoc """
    NFT-Base Generator
  """
  alias TaiShang.Rules
  require Logger

  def genrate_gene(init_rules_base2, init_rules_base10, limits_base2, limits_base10) do
    gene_base2 = do_generate_gene(:base2, init_rules_base2, limits_base2)
    gene_base10 = do_generate_gene(:base10, init_rules_base10, limits_base10)
    payload = gene_base2 <> gene_base10

    Logger.info("+------------------------------+")
    Logger.info("base2 rules: #{inspect(init_rules_base2)}")
    Logger.info("limits base2: #{inspect(limits_base2)}")
    Logger.info("base10 rules: #{inspect(init_rules_base10)}")
    Logger.info("limits base10: #{inspect(limits_base10)}")
    Logger.info("rnd gene generated: #{inspect(payload)}")

    payload
  end

  def do_generate_gene(type, init_rules, limits) do
    init_rules
    |> Enum.zip(limits)
    |> Enum.map(fn {init_rule, limit} ->
      case type do
        :base2 ->
          Rules.handle_base2_by_rule(limit, init_rule)
        :base10 ->
          Rules.handle_base10_by_rule(limit, init_rule)
      end
    end)
    |> :binary.list_to_bin()
  end
end
