# reference/python/parser_interface.py
from __future__ import annotations

"""
Functional parser interface for TSC verification.

A parser is just a function: str → ParsedInput
Register parsers by pattern matching on file content.
"""

from collections.abc import Callable
from dataclasses import dataclass

from reference.python.tsc_controller import (
    PolicyConfig,
    State,
    VerifyEnv,
    VerifyPolicy,
    WitnessFloors,
)


@dataclass(frozen=True)
class ParsedInput:
    """Immutable container for verification inputs."""

    env: VerifyEnv
    floors: WitnessFloors
    cfg: PolicyConfig
    policy: VerifyPolicy | None = None
    state: State | None = None

    def __post_init__(self):
        # Set defaults immutably
        if self.policy is None:
            object.__setattr__(self, "policy", VerifyPolicy())
        if self.state is None:
            object.__setattr__(self, "state", State.OPTIMIZE)


# Type alias for parser functions
Parser = Callable[[str, int | None], ParsedInput]


def parse_file(path: str, seed: int | None = None) -> ParsedInput:
    """
    Parse file using registered parsers.

    Pure function that dispatches based on file content.
    """
    # Deferred import prevents circulars (parsers import this module).
    from reference.python.parsers import select_parser

    parser_fn = select_parser(path)
    return parser_fn(path, seed)
