defmodule TaiShang.Account do
  use Ecto.Schema
  import Ecto.Changeset
  alias TaiShang.Chain
  alias TaiShang.Repo
  alias TaiShang.Account, as: Ele
  alias Utils.Crypto

  schema "account" do
    field :addr, :string
    field :encrypted_privkey, :binary
    belongs_to :chain, Chain
    timestamps()
  end

  def get_default_acct() do
    get_by_id(1)
  end

  def get_all() do
    Repo.all(Ele)
  end

  def get_by_addr(ele) do
    Repo.get_by(Ele, addr: ele)
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
    |> cast(attrs, [:addr, :encrypted_privkey, :chain_id])
    |> update_change(:encrypted_privkey, &Crypto.encrypt_key/1)
  end
end
