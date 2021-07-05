defmodule Utils.FileHandler do
  alias Utils.StructTranslator

  def read(:json, path) do
    path
    |> File.read!()
    |> Poison.decode!()
    |> StructTranslator.to_atom_struct()
  end

  def read(:bin, path) do
    path
    |> File.read!()
    |> String.replace("\n", "")
  end

  def fetch_files_in_path(path), do: Path.wildcard(path)
end
