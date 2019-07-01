defmodule Botany.Repo.Migrations.TaxonIdentification do
  use Ecto.Migration

  def up do
    import Ecto.Query
    alter table(:accession) do
      add :taxon_id, references(:taxon, on_delete: :restrict)
    end

    flush()

    ## let's match genera
    q = from(a in "accession",
      where: fragment(~S"substring(? from '\w+\.$') = 'sp.'", a.species),
      join: g in "taxon",
      on: g.epithet==fragment(~S"substring(? from '^\w+')", a.species),
      update: [set: [taxon_id: g.id]])
    Botany.Repo.update_all(q, [])

    ## then species
    q = from(a in "accession",
      where: fragment(~S"substring(? from '[\w\.]+$') != 'sp.'", a.species),
      join: g in "taxon",
      on: g.epithet==fragment(~S"substring(? from '^\w+')", a.species),
      join: s in "taxon",
      on: s.epithet==fragment(~S"substring(? from '\w+$')", a.species) and s.parent_id==g.id,
      update: [set: [taxon_id: s.id]])
    Botany.Repo.update_all(q, [])

    alter table(:accession) do
      remove :species
    end
  end

  def down do
    import Ecto.Query
    alter table(:accession) do
      add :species, :string
    end
    flush()
    ## retrieve the name from the taxon and put it in the new column
    # update accession set species=concat(g.epithet, ' ', s.epithet) from 

    %{id: id_genus} = Botany.Repo.one(from(r in "rank", select: [:id], where: r.name=="genus"))
    %{id: id_species} = Botany.Repo.one(from(r in "rank", select: [:id], where: r.name=="species"))
    q = from(a in "accession",
      join: s in "taxon",
      on: a.taxon_id==s.id,
      join: g in "taxon",
      on: s.parent_id==g.id,
      where: s.rank_id == ^id_species,
      update: [set: [species: fragment(~S"concat(?, ' ', ?)", g.epithet, s.epithet)]])
    Botany.Repo.update_all(q, [])
    q = from(a in "accession",
      join: g in "taxon",
      on: a.taxon_id==g.id,
      where: g.rank_id == ^id_genus,
      update: [set: [species: fragment(~S"concat(?, ' sp.')", g.epithet)]])
    Botany.Repo.update_all(q, [])

    alter table(:accession) do
      remove :taxon_id
    end
  end
end
