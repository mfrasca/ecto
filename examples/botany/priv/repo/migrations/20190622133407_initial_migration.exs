defmodule Botany.Repo.Migrations.InitialMigration do
  use Ecto.Migration

  def change do
    create table(:location) do
      add :code, :string, size: 20
      add :name, :string, size: 120
      add :description, :string
    end

    create table(:plant) do
      add :location_id, references(:location, on_delete: restrict)
      add :name, :string
      add :species, :string
      add :quantity, :integer
      add :bought_on, :utc_datetime
      add :bought_from, :string
    end
  end
end
