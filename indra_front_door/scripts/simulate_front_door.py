import click

from utils import FRONT_DOOR_DIRECTORY, GRAPHS_NAME, run_simulation


@click.command()
@click.option("--trials", type=int, default=1000, show_default=True)
def main(trials: int):
    run_simulation(
        path=FRONT_DOOR_DIRECTORY.joinpath(GRAPHS_NAME),
        directory=FRONT_DOOR_DIRECTORY,
        trials=trials,
    )


if __name__ == '__main__':
    main()
