defmodule Botany.Repo.Migrations.PlantNameToAccessionCode do
  use Ecto.Migration

  def up do
    import Ecto.Query

    create table(:accession) do
      add :code, :string
      add :species, :string
      add :orig_quantity, :integer, default: 0
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
      update: [set: [accession_id: a.id,
                     code: fragment(~S"substring(? from '\d+$')", p.name)]])
    Botany.Repo.update_all(q, [])

    q = from(a in "accession",
      join: p in "plant",
      on: p.accession_id == a.id,
      update: [set: [species: p.species,
                     orig_quantity: a.orig_quantity + p.quantity,
                     bought_on: p.bought_on,
                     bought_from: p.bought_from]])
    Botany.Repo.update_all(q, [])

    alter table(:plant) do
      remove :name
      remove :species
      remove :bought_on
      remove :bought_from
    end
  end

  def down do
    import Ecto.Query

    alter table(:plant) do
      add :name, :string
      add :species, :string
      add :bought_on, :utc_datetime
      add :bought_from, :string
    end

    flush()
    # we want to execute this one:
    # UPDATE plant p SET name=CONCAT((SELECT code FROM accession a WHERE a.id=p.accession_id),'.',p.code);

    q = from(p in "plant",
      join: a in "accession",
      on: a.id == p.accession_id,
      update: [set: [name: fragment(~S"concat(?, '.', ?)", a.code, p.code)]])
    Botany.Repo.update_all(q, [])

    alter table(:plant) do
      remove :code
      remove :accession_id
    end

    drop table(:accession)
  end
end
