defmodule TaiShang.Rules do
  @moduledoc """
    Operation About Rules.
  """

  alias Utils.RandGen

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

    payload_plus_rnd =
      1..rnd_num
      |> Enum.reduce([], fn _key, acc ->
        acc ++ [:rnd]
      end)

    payload_plus_fix =
      1..fix_num
      |> Enum.reduce(payload_plus_rnd, fn _key, acc ->
        acc ++ [:fix]
      end)

    Enum.reduce(1..nil_num, payload_plus_fix, fn _key, acc ->
      acc ++ [:nil]
    end)
  end

  @doc """
    gen rule when combine genes.
  """
  @spec gen_rule(:base2, integer, integer, integer, integer) :: List.t()
  def gen_rule(:base2, total_num, and_num, or_num, rnd_num) do

    nil_num = total_num - and_num - or_num - rnd_num

    payload_plus_and =
      1..and_num
      |> Enum.reduce([], fn _key, acc ->
        acc ++ [:and]
      end)
    payload_plus_or =
      1..or_num
      |> Enum.reduce(payload_plus_and, fn _key, acc ->
        acc ++ [:or]
      end)

    payload_plus_rnd =
      1..rnd_num
      |> Enum.reduce(payload_plus_or, fn _key, acc ->
        acc ++ [:rnd]
      end)

    Enum.reduce(1..nil_num, payload_plus_rnd, fn _key, acc ->
      acc ++ [:nil]
    end)
  end

  @spec gen_rule(:base10, integer, integer, integer, integer, integer, integer) :: List.t()
  def gen_rule(:base10, total_num, add_num, or_num, rnd_or_num, multi_num, rnd_num) do

    nil_num = total_num - add_num - multi_num - or_num - rnd_or_num - rnd_num

    payload_plus_add =
      1..add_num
      |> Enum.reduce([], fn _key, acc ->
        acc ++ [:add]
      end)
    payload_plus_or =
      1..or_num
      |> Enum.reduce(payload_plus_add, fn _key, acc ->
        acc ++ [:or]
      end)

    payload_plus_rnd_or =
      1..rnd_or_num
      |> Enum.reduce(payload_plus_or, fn _key, acc ->
        acc ++ [:rnd_or]
      end)

    payload_plus_multi =
      1..multi_num
      |> Enum.reduce(payload_plus_rnd_or, fn _key, acc ->
        acc ++ [:multi]
      end)

    payload_plus_rnd =
      1..rnd_num
      |> Enum.reduce(payload_plus_multi, fn _key, acc ->
        acc ++ [:rnd]
      end)

    Enum.reduce(1..nil_num, payload_plus_rnd, fn _key, acc ->
      acc ++ [:nil]
    end)
  end

  def gen_limit(list_size, limit_list) do
    limit_len =  Enum.count(limit_list)
    if limit_len >= list_size do
      limit_list
    else
      Enum.reduce(limit_len+1..list_size, limit_list, fn _key, acc ->
        acc ++ [:nil]
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
    when bin_value + acc_value >=1 do
    1
  end

  def handle_base2_by_rule(_, _, :or), do: 0
  def handle_base2_by_rule(_, _, :nil), do: 0

  def handle_base2_by_rule(_limit_base2, :rnd), do: RandGen.gen_a_num(1)
  def handle_base2_by_rule(limit_base2, :fix), do: limit_base2
  def handle_base2_by_rule(_limit_base2, :nil), do: 0

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
  def handle_base10_by_rule(_, _, _limit,:nil), do: 0

  def handle_base10_by_rule(limit, :rnd), do: RandGen.gen_a_num(limit)
  def handle_base10_by_rule(limit, :fix), do: limit
  def handle_base10_by_rule(_limit, :nil), do: 0


  def payload_or_limit(payload, limit) when payload > limit, do: limit
  def payload_or_limit(payload, _limit), do: payload
end
