defmodule TaiShang.Gene.Combiner do
  @moduledoc """
    Multi-Input to Single Output.
    Example.
    8 Bit Input: combine_genes[<<1, 2, 3, 4, 5, 6, 7, 8>>, <<1, 2, 3, 4, 5, 6, 7, 8>>]
  """

  alias TaiShang.Gene.Rules
  alias Utils.TypeTranslator
  require Logger

  # +---------+
  # | Level 1 |
  # +---------+

  def combine_genes(input_genes, rules_mixed, limits_mixed) do
    %{rules_base2: rules_base2, rules_base10: rules_base10} = rules_mixed
    %{limits_base2: _limits_base2, limits_base10: limits_base10} = limits_mixed

    combine_genes(input_genes, rules_base2, rules_base10, limits_base10)
  end

  def combine_genes(input_genes, rules_base2, rules_base10, limits) do
    len =
      input_genes
      |> Enum.fetch!(0)
      |> byte_size()

    do_combine_genes(len, input_genes, rules_base2, rules_base10, limits)
  end

  @spec do_combine_genes(integer(), binary(), List.t(), List.t(), List.t()) :: binary()
  def do_combine_genes(byte_size, input_genes, rules_base2, rules_base10, limits) do
    Enum.reduce(input_genes, fn input_gene, acc ->
      # 1/4 is base2
      base2_size = div(byte_size, 4)
      combine_couples(input_gene, acc, base2_size, rules_base2, rules_base10, limits)
    end)
  end

  @spec combine_couples(
          <<_::16, _::_*8>>,
          <<_::16, _::_*8>>,
          integer(),
          List.t(),
          List.t(),
          List.t()
        ) :: binary
  def combine_couples(input_gene, acc, base2_size, rules_base2, rules_base10, limits) do
    <<binary_base2::bytes-size(base2_size), binary_base10::binary>> = input_gene
    <<acc_binary_base2::bytes-size(base2_size), acc_binary_base10::binary>> = acc

    handled_base2_bin = handle_base2(binary_base2, acc_binary_base2, base2_size, rules_base2)

    handle_base10_bin = handle_base10(binary_base10, acc_binary_base10, rules_base10, limits)
    handled_base2_bin <> handle_base10_bin
  end

  # +---------+
  # | Level 2 |
  # +---------+

  ## +----------------+
  ## | base10 handler |
  ## +----------------+

  @spec handle_base10(binary, binary, List.t(), List.t()) :: binary()
  def handle_base10(binary, acc_binary, rules_base10, limits) do
    binary
    |> :binary.bin_to_list()
    |> handle_base10_list(:binary.bin_to_list(acc_binary), rules_base10, limits)
  end

  def handle_base10_list(base10_list, acc_base10_list, rules_base10, limits) do
    # rules to adjust
    # list_size = Enum.count(base10_list)
    # rules = Rules.gen_rule(:base10, list_size, 1, 1, 1, 1, 1)
    # limit = Rules.gen_limit(list_size, [16, 16, 16, 16, 32])
    payload =
      base10_list
      |> Enum.zip(acc_base10_list)
      |> Enum.zip(rules_base10)
      |> Enum.zip(limits)
      |> handle_properties()

    Logger.info("+------------------------------+")
    Logger.info("input base10 gene :#{inspect(base10_list)}")
    Logger.info("input acc base10 gene :#{inspect(acc_base10_list)}")
    Logger.info("base10 rules :#{inspect(rules_base10)}")
    Logger.info("output base10 gene :#{inspect(payload)}")

    :binary.list_to_bin(payload)
  end

  ## +---------------+
  ## | base2 handler |
  ## +---------------+

  @spec handle_base2(binary, binary, integer(), List.t()) :: binary
  def handle_base2(binary, acc_binary, base2_size, rules_base2) do
    binary
    |> TypeTranslator.bin_to_base2_list(base2_size)
    |> handle_base2_list(TypeTranslator.bin_to_base2_list(acc_binary, base2_size), rules_base2)
  end

  @spec handle_base2_list(List.t(), List.t(), List.t()) :: binary
  def handle_base2_list(base2_list, acc_base2_list, rules_base2) do
    # rules to adjust
    # list_size = Enum.count(base2_list)
    # rules = Rules.gen_rule(:base2, list_size, 5, 5, 5)

    payload =
      base2_list
      |> Enum.zip(acc_base2_list)
      |> Enum.zip(rules_base2)
      |> handle_properties()

    Logger.info("+------------------------------+")
    Logger.info("input base2 gene: #{inspect(base2_list)}")
    Logger.info("input acc base2 gene: #{inspect(acc_base2_list)}")
    Logger.info("base2 rules: #{inspect(rules_base2)}")
    Logger.info("output base2 gene: #{inspect(payload)}")

    size_in_bin = ceil(Enum.count(base2_list) / 8)

    payload
    |> TypeTranslator.base2_list_to_bin()
    |> Binary.pad_leading(size_in_bin)
  end

  def handle_properties(bin_list) do
    bin_list
    |> Enum.map(fn payload ->
      case payload do
        {{{bin_value, acc_value}, rule}, limit} ->
          Rules.handle_base10_by_rule(bin_value, acc_value, limit, rule)

        {{bin_value, acc_value}, rule} ->
          Rules.handle_base2_by_rule(bin_value, acc_value, rule)
      end
    end)
  end
end
