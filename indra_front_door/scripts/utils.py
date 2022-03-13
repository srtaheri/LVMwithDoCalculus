from pathlib import Path

import pandas as pd
from tqdm import tqdm

from y0.algorithm.falsification import get_graph_falsifications
from y0.graph import NxMixedGraph
from y0.simulation import simulate

__all__ = [
    "HERE",
    "run_simulation",
]

HERE = Path(__file__).parent.resolve()
RESULTS = HERE.joinpath("results")
RESULTS.mkdir(exist_ok=True, parents=True)
FRONT_DOOR_DIRECTORY = RESULTS.joinpath("front_door")
FRONT_DOOR_DIRECTORY.mkdir(exist_ok=True, parents=True)

GRAPHS_NAME = "graphs.tsv"
DATA_NAME = "data.tsv"
FALSIFICATIONS_NAME = "falsifications.tsv"


def run_simulation(*, path: Path, directory: Path, trials: int = 1000):
    df = pd.read_csv(path, sep="\t")
    simuation_rows = []
    falsification_rows = []
    for i, (u, x, m, y, *_) in enumerate(
        tqdm(df.values, desc="Simulation", unit="motif")
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
        directory.joinpath(DATA_NAME), sep="\t", index=False
    )
    falsification_combine_df = pd.DataFrame(
        falsification_rows, columns=["index", *falsification_results.evidence.columns]
    )
    falsification_combine_df.to_csv(
        directory.joinpath(FALSIFICATIONS_NAME), sep="\t", index=False
    )
