from pathlib import Path

import pandas as pd
from tqdm import tqdm

from y0.algorithm.falsification import falsifications
from y0.graph import NxMixedGraph
from y0.simulation import simulate

HERE = Path(__file__).parent.resolve()


def main(trials: int = 5):
    df = pd.read_csv(HERE.joinpath("indra_front_door.tsv"), sep='\t')
    rows = []
    for i, (u, x, m, y, *_) in enumerate(tqdm(df.values, desc="Front door simulation", unit="motif")):
        print(u, x, m, y)
        graph = NxMixedGraph.from_str_edges(directed=[
            (u, x),
            (x, m),
            (m, y),
            (u, y),
        ])
        print(graph)
        simulation_df = simulate(graph, trials=trials, return_fits=False, tqdm_kwargs=dict(leave=False))
        print(simulation_df)
        falsification_results = falsifications(graph, simulation_df)

        print(falsification_results)
        print(falsification_results._failures)
        print(falsification_results.evidence)

        break

        for u_value, x_value, m_value, y_value in simulation_df.values:
            rows.append((i, u, u_value, x, x_value, m, m_value, y, y_value))
    out_df = pd.DataFrame(rows, columns=["index", "u", "u_value", "x", "x_value", "m", "m_value", "y", "y_value"])
    out_df.to_csv(HERE.joinpath("simulated_data.tsv"), sep='\t', index=False)


if __name__ == '__main__':
    main()
