from pathlib import Path
from typing import Optional

import click
import pandas as pd
from indra_cogex.client import Neo4jClient

columns = ["u", "x", "m", "y", "r1.belief", "r2.belief", "r3.belief", "r4.belief"]


@click.command()
@click.option("--minimum-evidence", type=int, default=5, show_default=True)
@click.option("--output", type=Path)
def main(minimum_evidence: int, output: Optional[Path]):
    client = Neo4jClient()
    query = f"""\
    MATCH p=(u:BioEntity)
        -[r1:indra_rel]->(x:BioEntity)
        -[r2:indra_rel]->(m:BioEntity)
        -[r3:indra_rel]->(y:BioEntity)
        <-[r4:indra_rel]-(u:BioEntity)
    WHERE
        NOT (u)-[:indra_rel]->(m)
        AND NOT (x)-[:indra_rel]->(y)
        AND NOT (y)-[:indra_rel]->(m)
        AND NOT (y)-[:indra_rel]->(x)
        AND NOT (y)-[:indra_rel]->(u)
        AND NOT (x)-[:indra_rel]->(u)
        AND NOT (m)-[:indra_rel]->(u)
        AND NOT (m)-[:indra_rel]->(x)
        AND u.id <> x.id
        AND u.id <> m.id
        AND u.id <> y.id
        AND x.id <> m.id
        AND x.id <> y.id
        AND m.id <> y.id
        AND u.id STARTS WITH "hgnc"
        AND x.id STARTS WITH "hgnc"
        AND m.id STARTS WITH "hgnc"
        AND y.id STARTS WITH "hgnc"
        AND r1.stmt_type IN ['Inhibition', 'Activation', 'IncreaseAmount', 'DecreaseAmount']
        AND r2.stmt_type IN ['Inhibition', 'Activation', 'IncreaseAmount', 'DecreaseAmount']
        AND r3.stmt_type IN ['Inhibition', 'Activation', 'IncreaseAmount', 'DecreaseAmount']
        AND r4.stmt_type IN ['Inhibition', 'Activation', 'IncreaseAmount', 'DecreaseAmount']
        AND r1.evidence_count > {minimum_evidence}
        AND r2.evidence_count > {minimum_evidence}
        AND r3.evidence_count > {minimum_evidence}
        AND r4.evidence_count > {minimum_evidence}
    RETURN DISTINCT 
        u.id, x.id, m.id, y.id, round(r1.belief, 2), round(r2.belief, 2), round(r3.belief, 2), round(r4.belief, 2)
    """
    res = client.query_tx(query)
    df = pd.DataFrame(res, columns=columns)
    df.to_csv(output, sep="\t", index=False)


if __name__ == '__main__':
    main()
