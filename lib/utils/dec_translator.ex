defmodule Utils.DecTranslator do

  @spec bin_to_base2_list(Binary.t(), pos_integer) :: List.t()
  def bin_to_base2_list(bin, size) do
    bin
    |> :binary.decode_unsigned()
    |> Integer.to_string(2)
    |> String.to_integer()
    |> Integer.digits()
    |> :binary.list_to_bin()
    |> Binary.pad_leading(size*8)
    |> :binary.bin_to_list()
  end

  @spec base2_list_to_bin(List.t()) :: binary
  def base2_list_to_bin(list) do
    list
    |> Integer.undigits()
    |> Integer.to_string()
    |> String.to_integer(2)
    |> :binary.encode_unsigned()
  end
end
