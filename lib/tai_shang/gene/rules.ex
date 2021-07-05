defmodule TaiShang.Gene.Rules do
  @moduledoc """
    Operation About Rules.
  """
  alias TaiShang.NFTPlusFetcher
  alias Utils.{RandGen, TypeTranslator}

  # +---------------+
  # | rules fetcher |
  # +---------------+
  def fetch_rules_and_limits(%{config: config}, erc721_addr, evidence_addr) do
    [limits_raw_list, rules_raw_list] =
      NFTPlusFetcher.get_contract_info(
        config["chain_id"],
        erc721_addr,
        evidence_addr
      )

    if is_nil(limits_raw_list) or is_nil(rules_raw_list) do
      {:error, "limit_or_rules_not_setting"}
    else
      limits =
        limits_raw_list
        |> :binary.list_to_bin()
        |> decompose_limits()

      rules = decompose_rules(rules_raw_list)
      {rules, limits}
    end
  end

  # +-----------------+
  # | rules generator |
  # +-----------------+

  @doc """
    gen rule when init from nil.
    For both base2 & base10.
  """
  @spec gen_init_rule(integer, integer, integer) :: List.t()
  def gen_init_rule(total_num, rnd_num, fix_num) do
    nil_num = total_num - rnd_num - fix_num

    []
    |> append_with_num(:rnd, rnd_num)
    |> append_with_num(:fix, fix_num)
    |> append_with_num(nil, nil_num)
  end

  @doc """
    gen rule when combine genes.
  """
  @spec gen_rule(:base2, integer, integer, integer, integer) :: List.t()
  def gen_rule(:base2, total_num, and_num, or_num, rnd_num) do
    nil_num = total_num - and_num - or_num - rnd_num

    []
    |> append_with_num(:and, and_num)
    |> append_with_num(:or, or_num)
    |> append_with_num(:rnd, rnd_num)
    |> append_with_num(nil, nil_num)
  end

  @spec gen_rule(:base10, integer, integer, integer, integer, integer, integer) :: List.t()
  def gen_rule(:base10, total_num, add_num, or_num, rnd_or_num, multi_num, rnd_num) do
    nil_num = total_num - add_num - multi_num - or_num - rnd_or_num - rnd_num

    []
    |> append_with_num(:add, add_num)
    |> append_with_num(:or, or_num)
    |> append_with_num(:multi, multi_num)
    |> append_with_num(:rnd_or, rnd_or_num)
    |> append_with_num(:rnd, rnd_num)
    |> append_with_num(nil, nil_num)
  end

  def append_with_num(origin, _append_item, num) when num == 0, do: origin

  def append_with_num(origin, append_item, num) do
    1..num
    |> Enum.reduce(origin, fn _key, acc ->
      acc ++ [append_item]
    end)
  end

  def gen_limit(list_size, limit_list) do
    limit_len = Enum.count(limit_list)

    if limit_len >= list_size do
      limit_list
    else
      Enum.reduce((limit_len + 1)..list_size, limit_list, fn _key, acc ->
        acc ++ [0]
      end)
    end
  end

  # +--------------------+
  # | base2 rule handler |
  # +--------------------+
  def handle_base2_by_rule(_, _, :rnd), do: RandGen.gen_a_num(1)

  def handle_base2_by_rule(1, 1, :and), do: 1
  def handle_base2_by_rule(_, _, :and), do: 0

  def handle_base2_by_rule(bin_value, acc_value, :or)
      when bin_value + acc_value >= 1 do
    1
  end

  def handle_base2_by_rule(_, _, :or), do: 0
  def handle_base2_by_rule(_, _, nil), do: 0

  def handle_base2_by_rule(_limit_base2, :rnd), do: RandGen.gen_a_num(1)
  def handle_base2_by_rule(limit_base2, :fix), do: limit_base2
  def handle_base2_by_rule(_limit_base2, nil), do: 0

  # +---------------------+
  # | base10 rule handler |
  # +---------------------+

  def handle_base10_by_rule(_, _, limit, :rnd), do: RandGen.gen_a_num(limit)

  def handle_base10_by_rule(bin_value, acc_value, limit, :add) do
    bin_value
    |> Kernel.+(acc_value)
    |> payload_or_limit(limit)
  end

  def handle_base10_by_rule(bin_value, acc_value, limit, :multi) do
    bin_value
    |> Kernel.*(acc_value)
    |> payload_or_limit(limit)
  end

  def handle_base10_by_rule(bin_value, acc_value, _limit, :or)
      when bin_value <= acc_value do
    acc_value
  end

  def handle_base10_by_rule(bin_value, _acc_value, _limit, :or), do: bin_value

  def handle_base10_by_rule(bin_value, acc_value, _limit, :rnd_or) do
    num = RandGen.gen_a_num(1)

    case num do
      1 ->
        bin_value

      0 ->
        acc_value
    end
  end

  def handle_base10_by_rule(_, _, _limit, nil), do: 0

  def handle_base10_by_rule(limit, :rnd), do: RandGen.gen_a_num(limit)
  def handle_base10_by_rule(limit, :fix), do: limit
  def handle_base10_by_rule(_limit, nil), do: 0

  def payload_or_limit(payload, limit) when payload > limit, do: limit
  def payload_or_limit(payload, _limit), do: payload

  # +----------------------------+
  # | gene binary <=> limit list |
  # +----------------------------+
  def combine_limits(limits_base2, limits_base10) do
    limits_base2
    |> TypeTranslator.base2_list_to_bin()
    |> Kernel.<>(:binary.list_to_bin(limits_base10))
  end

  def decompose_limits(limits_raw) do
    len = byte_size(limits_raw)
    size_base2 = div(len, 4)

    {limits_base2_raw, limits_base10_raw} =
      Binary.split_at(limits_raw, size_base2)

    limits_base2 =
      TypeTranslator.bin_to_base2_list(limits_base2_raw, size_base2)

    limits_base10 =
      :binary.bin_to_list(limits_base10_raw)

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
    rules_base2 = gen_init_rule(total_num_base2, rnd_num_base2, fix_num_base2)
    rules_base10 = gen_init_rule(total_num, rnd_num, fix_num)
    %{rules_base2: rules_base2, rules_base10: rules_base10}
  end

  @spec count(any) :: [non_neg_integer, ...]
  def count(init_rules) do
    total_num = Enum.count(init_rules)
    rnd_num = Enum.count(init_rules, &(&1 == :rnd))
    fix_num = Enum.count(init_rules, &(&1 == :fix))
    [total_num, rnd_num, fix_num]
  end
end
