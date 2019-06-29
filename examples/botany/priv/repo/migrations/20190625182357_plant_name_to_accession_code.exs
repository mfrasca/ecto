defmodule Botany.Repo.Migrations.PlantNameToAccessionCode do
  use Ecto.Migration

  def up do
    import Ecto.Query

    create table(:accession) do
      add :code, :string
      add :species, :string
      add :orig_quantity, :integer
      add :bought_on, :utc_datetime
      add :bought_from, :string
    end

    alter table(:plant) do
      add :code, :string
      add :accession_id, references(:accession)
    end

    flush()

    q = from(t in "plant",
      select: %{code: fragment(~S"substring(? from '^\d+\.\d+')", t.name)},
      distinct: fragment(~S"substring(? from '^\d+\.\d+')", t.name)) |>
      Botany.Repo.all
    Botany.Repo.insert_all("accession", q)

    q = from(p in "plant",
      join: a in "accession",
      on: a.code == fragment(~S"substring(? from '^\d+\.\d+')", p.name),
      update: [set: [accession_id: a.id]])
    Botany.Repo.update_all(q, [])

    alter table(:plant) do
      remove :name
      remove :species
    end
  end

  def down do
    alter table(:plant) do
      add :name, :string
      add :species, :string
    end

    flush()

    alter table(:plant) do
      remove :code
      remove :accession_id
    end

    drop table(:accession)

  end
end
