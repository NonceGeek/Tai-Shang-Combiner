defmodule TaiShang.Parser do
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias TaiShang.{Repo, Chain}
  alias TaiShang.Parser, as: Ele

  schema "parser" do
    field :name, :string
    field :description, :string
    field :type, :string
    field :url, :string
    field :example_addr, :string
    field :example_token_id, :integer
    belongs_to :chain, Chain
    timestamps()
  end

  def get_all() do
    Repo.all(Ele)
  end

  def get_by_id(ele) do
    Repo.get_by(Ele, id: ele)
  end

  def get_by_name(ele) do
    Repo.get_by(Ele, name: ele)
  end

  def get_by_type(type) do
    Ele
    |> where([e], e.type == ^type)
    |> Repo.all()
  end

  def create(attrs \\ %{}) do
    %Ele{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  def change(%Ele{} = ele, attrs) do
    ele
    |> changeset(attrs)
    |> Repo.update()
  end

  def changeset(%Ele{} = ele) do
    changeset(ele, %{})
  end

  @doc false
  def changeset(%Ele{} = ele, attrs) do
    ele
    |> cast(attrs, [:name, :description, :type, :url, :chain_id, :example_addr, :example_token_id])
    |> unique_constraint(:name)
  end
end
