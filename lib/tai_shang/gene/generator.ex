defmodule TaiShang.Gene.Generator do
  @moduledoc """
    NFT-Base Generator
  """
  alias TaiShang.Rules
  alias Utils.TypeTranslator
  require Logger

  @doc """
    generate gene by params.
    8 Bit Gene Example:

    ```
    init_rules_base2 = TaiShang.Rules.gen_init_rule(16, 4, 4) # 16 b = 2 bit
    limits_base2 = TaiShang.Rules.gen_limit(16, [1,1,1,1,0,0,0,0,1,1,1,1])
    init_rules_base10 = TaiShang.Rules.gen_init_rule(16, 6, 6)
    limits_base10 = TaiShang.Rules.gen_limit(6, [20, 30, 40, 50, 60, 70])
    TaiShang.Generator.genrate_gene(init_rules_base2, init_rules_base10, limits_base2, limits_base10)
    ```
  """
  def generate_gen(rules_mixed, limits_mixed) do
    %{rules_base2: rules_base2, rules_base_10: rules_base10}
      = rules_mixed
    %{limits_base2: limits_base2, limits_base10: limits_base10}
      = limits_mixed
    generate_gene(rules_base2, rules_base10, limits_base2, limits_base10)
  end
  def generate_gene(init_rules_base2, init_rules_base10, limits_base2, limits_base10) do
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
    |> handle_result(type)
  end

  def handle_result(payload, :base2) do
    TypeTranslator.base2_list_to_bin(payload)
  end

  def handle_result(payload, :base10) do
    :binary.list_to_bin(payload)
  end

  # +----------------------------+
  # | gene binary <=> limit list |
  # +----------------------------+
  def combine_limits(limits_base2, limits_base10) do
    limits_base2
    |> TypeTranslator.base2_list_to_bin()
    |> Kernel.<>(:binary.list_to_bin(limits_base10))
  end

  def decompse_limits(limits_raw) do
    len = byte_size(limits_raw)
    size_base2 = div(len, 4)
    {limits_base2_raw, limits_base10_raw}
      = Binary.split_at(limits_raw, size_base2)
    limits_base2
      = TypeTranslator.bin_to_base2_list(limits_base2_raw, size_base2)
    limits_base10
      = :binary.bin_to_list(limits_base10_raw)
    %{limits_base2: limits_base2, limits_base10: limits_base10}
  end

  # +---------------------------------+
  # | rules count list <=> rules list |
  # +---------------------------------+
  def combine_rules(init_rules_base2, init_rules_base10) do
    [count(init_rules_base2), count(init_rules_base10)]
  end

  def decompose_rules([init_rules_base2, init_rules_base10]) do
    [total_num_base2, rnd_num_base2, fix_num_base2] = init_rules_base2
    [total_num, rnd_num, fix_num] = init_rules_base10
    rules_base2 =
      Rules.gen_init_rule(total_num_base2, rnd_num_base2, fix_num_base2)
    rules_base10 =
      Rules.gen_init_rule(total_num, rnd_num, fix_num)
    %{rules_base2: rules_base2, rules_base_10: rules_base10}
  end

  @spec count(any) :: [non_neg_integer, ...]
  def count(init_rules) do
    total_num = Enum.count(init_rules)
    rnd_num = Enum.count(init_rules, &(&1==:rnd))
    fix_num = Enum.count(init_rules, &(&1==:fix))
    [total_num, rnd_num, fix_num]
  end
end
