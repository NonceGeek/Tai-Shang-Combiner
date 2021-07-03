defmodule TaiShang.Repo.Migrations.CreateParser do
  use Ecto.Migration

  def change do
    create table :parser do
      add :name, :string
      add :description, :string
      add :type, :string, default: "based_on_addr"
      add :chain_id, :integer
      add :url, :string
      timestamps()
    end
  end
end
