defmodule TaiShang.Combiner do
  @doc """
    Multi-Input to Single Output
  """


  # +-------+
  # | Rules | <<255,255,255,255,255,255,255,255>>
  # +-------+ <<255,255,255,255,255,255,255,255>>

  alias Utils.{DecTranslator, RandGen}
  require Logger

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
    Enum.reduce(Enum.count(limit_list)..list_size, limit_list, fn _key, acc ->
      acc ++ [:nil]
    end)
  end

  # +---------+
  # | Level 1 |
  # +---------+
  def combine_genes(input_genes) do
    len =
      input_genes
      |> Enum.fetch!(0)
      |> byte_size()
    do_combine_genes(len, input_genes)
  end


  @spec do_combine_genes(integer(), binary()) :: binary()
  def do_combine_genes(byte_size, input_genes) do
    Enum.reduce(input_genes, fn input_gene, acc->
      base2_size = div(byte_size, 4)
      combine_couples(input_gene, acc, base2_size)
    end)
  end

  @spec combine_couples(<<_::16, _::_*8>>, <<_::16, _::_*8>>, integer()) :: binary
  def combine_couples(input_gene, acc, base2_size) do
    <<binary_base2 :: bytes-size(base2_size), binary_base10 :: binary>> = input_gene
    <<acc_binary_base2 :: bytes-size(base2_size), acc_binary_base10:: binary>> = acc


    handled_base2_bin =
      handle_base2(binary_base2, acc_binary_base2, base2_size)

    handle_base10_bin =
      handle_base10(binary_base10, acc_binary_base10)
    handled_base2_bin <> handle_base10_bin
  end

  # +---------+
  # | Level 2 |
  # +---------+

  ## +----------------+
  ## | base10 handler |
  ## +----------------+

  @spec handle_base10(binary, binary) :: binary()
  def handle_base10(binary, acc_binary) do
    binary
    |> :binary.bin_to_list()
    |> handle_base10_list(:binary.bin_to_list(acc_binary))
  end

  def handle_base10_list(base10_list, acc_base10_list) do

    list_size = Enum.count(base10_list)
    # rules to adjust
    rules = gen_rule(:base10, list_size, 1, 1, 1, 1, 1)
    limit = gen_limit(list_size, [16, 16, 16, 16, 32])
    payload =
      base10_list
      |> Enum.zip(acc_base10_list)
      |> Enum.zip(rules)
      |> Enum.zip(limit)
      |> handle_properties()

    Logger.info("+------------------------------+")
    Logger.info("input base10 gene :#{inspect(base10_list)}")
    Logger.info("input acc base10 gene :#{inspect(acc_base10_list)}")
    Logger.info("base10 rules :#{inspect(rules)}")
    Logger.info("output base10 gene :#{inspect(payload)}")

    :binary.list_to_bin(payload)

  end

  ## +---------------+
  ## | base2 handler |
  ## +---------------+

  @spec handle_base2(binary, binary, integer()) :: binary
  def handle_base2(binary, acc_binary, base2_size) do
    binary
    |> DecTranslator.bin_to_base2_list(base2_size)
    |> handle_base2_list(DecTranslator.bin_to_base2_list(acc_binary, base2_size))
  end

  @spec handle_base2_list(List.t(), List.t()) :: binary
  def handle_base2_list(base2_list, acc_base2_list) do
    list_size = Enum.count(base2_list)

    # rules to adjust
    rules = gen_rule(:base2, list_size, 5, 5, 5)

    payload =
      base2_list
      |> Enum.zip(acc_base2_list)
      |> Enum.zip(rules)
      |> handle_properties()

    Logger.info("+------------------------------+")
    Logger.info("input base2 gene :#{inspect(base2_list)}")
    Logger.info("input acc base2 gene :#{inspect(acc_base2_list)}")
    Logger.info("base2 rules :#{inspect(rules)}")
    Logger.info("output base2 gene :#{inspect(payload)}")
    DecTranslator.base2_list_to_bin(payload, 2)
  end

  def handle_properties(bin_list) do
    bin_list
    |> Enum.map(fn payload ->
      case payload do
        {{{bin_value, acc_value}, rule}, limit} ->
          handle_base10_by_rule(bin_value, acc_value, limit, rule)
        {{bin_value, acc_value}, rule} ->
          handle_base2_by_rule(bin_value, acc_value, rule)
      end
    end)
  end

  # -----------------

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

  def payload_or_limit(payload, limit) when payload > limit, do: limit
  def payload_or_limit(payload, _limit), do: payload

  # -----------------
  def handle_base2_by_rule(_, _, :rnd), do: RandGen.gen_a_num(1)

  def handle_base2_by_rule(1, 1, :and), do: 1
  def handle_base2_by_rule(_, _, :and), do: 0

  def handle_base2_by_rule(bin_value, acc_value, :or)
    when bin_value + acc_value >=1 do
    1
  end

  def handle_base2_by_rule(_, _, :or), do: 0
  def handle_base2_by_rule(_, _, :nil), do: 0

end
