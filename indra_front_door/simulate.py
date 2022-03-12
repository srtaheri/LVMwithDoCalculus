from pathlib import Path

import click
import pandas as pd
from tqdm import tqdm

from y0.algorithm.falsification import get_graph_falsifications
from y0.graph import NxMixedGraph
from y0.simulation import simulate

HERE = Path(__file__).parent.resolve()


@click.command()
@click.option("--trials", type=int, default=1000, show_default=True)
def main(trials: int):
    df = pd.read_csv(HERE.joinpath("indra_front_door.tsv"), sep="\t")
    simuation_rows = []
    falsification_rows = []
    for i, (u, x, m, y, *_) in enumerate(
        tqdm(df.values, desc="Front door simulation", unit="motif")
    ):
        graph = NxMixedGraph.from_str_edges(
            directed=[
                (u, x),
                (x, m),
                (m, y),
                (u, y),
            ]
        )
        simulation_df = simulate(
            graph, trials=trials, return_fits=False, tqdm_kwargs=dict(leave=False)
        )
        for u_value, x_value, m_value, y_value in simulation_df.values:
            simuation_rows.append((i, u_value, x_value, m_value, y_value))

        falsification_results = get_graph_falsifications(graph, simulation_df)
        for row in falsification_results.evidence.values:
            falsification_rows.append((i, *row))

    simulation_combine_df = pd.DataFrame(
        simuation_rows,
        columns=[
            "index",
            "u",
            "x",
            "m",
            "y",
        ],
    )
    simulation_combine_df.to_csv(
        HERE.joinpath("simulated_data.tsv"), sep="\t", index=False
    )
    falsification_combine_df = pd.DataFrame(
        falsification_rows, columns=["index", *falsification_results.evidence.columns]
    )
    falsification_combine_df.to_csv(
        HERE.joinpath("simulated_falsifications.tsv"), sep="\t", index=False
    )


if __name__ == "__main__":
    main()
