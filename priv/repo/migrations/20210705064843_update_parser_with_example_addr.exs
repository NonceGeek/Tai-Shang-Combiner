defmodule TaiShang.Repo.Migrations.UpdateParserWithExampleAddr do
  use Ecto.Migration

  def change do
    alter table :parser do
      add :example_addr, :string
      add :example_token_id, :integer
    end
  end
end
