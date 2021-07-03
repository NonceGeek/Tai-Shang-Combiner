defmodule TaiShang.Repo.Migrations.Init do
  use Ecto.Migration

  def change do
    # ↓common↓
    create table :chain do
      add :name, :string
      # add :min_height, :integer
      # add :height_now, :integer
      add :is_enabled, :boolean, default: false
      add :adapter, :string
      add :config, :map

      timestamps()
    end

    # create table :contract do
    #   add :addr, :string
    #   add :type, :string
    #   add :creater, :string
    #   add :init_params, :map
    #   add :description, :string

    #   add :chain_id, :integer
    #   add :contract_template_id, :integer

    #   timestamps()
    # end

    # create table :contract_template do
    #   add :name, :string
    #   add :abi, {:array, :map}
    #   add :bin, :text

    #   timestamps()
    # end

    # create table :block do
    #   add :chain_id, :integer
    #   add :block_height, :integer
    #   add :block_hash, :string
    #   timestamps()
    # end

    # create table :event do
    #   add :address, :string
    #   add :log_index, :integer
    #   add :topics, {:array, :string}
    #   add :data, :text
    #   add :block_id, :integer

    #   add :contract_id, :integer
    #   timestamps()
    # end

    # # ↓specific↓
    # create table :evidence do
    #   add :key, :string
    #   add :value, :string
    #   add :describe, :string
    #   add :tx_id, :string

    #   add :owners, {:array, :string}
    #   add :signers, {:array, :string}
    #   add :contract_id, :integer

    #   timestamps()
    # end

    # create table :account do
    #   add :addr, :string
    #   add :balance, :integer
    #   add :chain_id, :integer

    #   timestamps()
    # end

    # create table :nft do
    #   add :contract_ids, :map

    #   timestamps()
    # end
  end
end
