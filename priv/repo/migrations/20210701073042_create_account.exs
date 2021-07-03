defmodule TaiShang.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table :account do
      add :nft_balance, :map
      add :addr, :string
      add :chain_id, :integer
      add :encrypted_privkey, :binary
      timestamps()
    end
  end
end
