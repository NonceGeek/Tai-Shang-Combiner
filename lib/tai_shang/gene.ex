defmodule TaiShang.Gene do
  alias Utils.TypeTranslator

  def parse(gene, rules_list) when is_list(gene) do
    bin_gen = :binary.list_to_bin(gene)
    parse(bin_gen, rules_list)
  end

  def parse(gene, rules_list) do
    %{rules_base2: rules_base2, rules_base10: rules_base10} =
      rules_list

    {binary_base2, binary_base10} = split_gene(gene)

    list_base2 =
      binary_base2
      |> TypeTranslator.bin_to_base2_list()
      |> handle_gene_by_rules(rules_base2)

    list_base10 =
      binary_base10
      |> :binary.bin_to_list()
      |> handle_gene_by_rules(rules_base10)

    {list_base2, list_base10}
  end

  @spec handle_gene_by_rules(List.t(), List.t()) :: List.t()
  def handle_gene_by_rules(gene, rules) do
    gene
    |> Enum.zip(rules)
    |> Enum.map(fn {v, rules} ->
      if is_nil(rules) do
        nil
      else
        v
      end
    end)
  end

  def split_gene(gene) do
    len =
      gene
      |> byte_size()

    # 1/4 is base2
    base2_size = div(len, 4)
    <<binary_base2::bytes-size(base2_size), binary_base10::binary>> = gene
    {binary_base2, binary_base10}
  end
end
