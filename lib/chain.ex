defmodule TaiShang.Chain do
  use Ecto.Schema
  import Ecto.Changeset
  alias TaiShang.Repo
  alias TaiShang.Chain, as: Ele

  schema "chain" do
    field :name, :string
    field :adapter, :string
    field :config, :map
    field :is_enabled, :boolean
    timestamps()
  end

  def get_default_chain() do
    get_by_id(1)
  end

  def get_all() do
    Repo.all(Ele)
  end

  def get_by_name(ele) do
    Repo.get_by(Ele, name: ele)
  end

  def get_by_id(ele) do
    Repo.get_by(Ele, id: ele)
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
    |> cast(attrs, [:name, :is_enabled, :adapter, :config])
    |> unique_constraint(:name)
  end
end
