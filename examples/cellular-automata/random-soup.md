______________________________________________________________________

## name: random-soup role: negative_control target: low_coherence metric: C_Σ expected_value: "~0.25" expected_outcome: FAIL seed: 1337 grid: "16x16" frames: 8 symbols: ["#", "."]

# Random Soup (Negative Control for Coherence)

**Why this exists:** This is the *failure case* to pair with `glider.md` (high coherence, C_Σ ≈ 0.996; PASS).\
Your TSC implementation should report **low coherence** on this file: **C_Σ ≈ 0.25 → FAIL**.

**What it is:** Each time step is an **independent** 16×16 binary grid.\
Cells are drawn i.i.d. from Bernoulli(p=0.5), with `#` = 1 and `.` = 0. Frames are not related to each other, by design.

**How to use:** Run the exact same pipeline you used for `glider.md` on these frames.
You should observe:

- `glider.md` → **high** C_Σ (~0.996), PASS
- `random_soup.md` → **low** C_Σ (~0.25), **FAIL**

If `random_soup.md` scores high, your implementation likely has a leakage/normalization issue
(e.g., measuring within-frame similarity, mixing up time indexing, or averaging the wrong axes).

______________________________________________________________________

## Reference parameters

- Frames: 8
- Grid: 16×16
- RNG seed: 1337
- Symbols: `#` (1), `.` (0)
- Expected C_Σ: ~0.25 (tolerate ~±0.05 depending on implementation details)
- Status: **FAIL** (negative control)

______________________________________________________________________

## Frames

Below are the 8 frames. Trailing spaces are significant: there are none.

### Frame 1

.#.####..#..####.
#..#..#.#..##.##.
#.#..#...#..#..##
##......#..#.##.#
##...#..##.#..##.
..###.###..#..#..
#..#......##..#..
...#.###....#####
##...#....#..####
#.###.#...####...
.##......#.######
#...#.#.##.#..###
......#....##..##
.#..#...##.###.##
#.#..###....#.#.#
....#..###..#....

### Frame 2

...#.####.##...##
....###.#.#.##.#.
.##..#...#.#..##.
##.####.#.###..#.
.....#..#.##..#..
.##...#.##.#..#.#
#.....#.#.##...#.
##...#.###......#
......###.##..#.#
###....#.##..#..#
...##.###.#..##..
..#.#..##.###..##
###.##.#..#...#.#
.#....##..#.##.#.
#..##..#.#..#..#.
.###.#..#..#.#..#

### Frame 3

#.#.#..#..#.....#
#..##.#..###..#.#
.##..##..###.##.#
.#...##.##..##.#.
..#...##..##.#.##
#.#..#######.....
#.##.....#....#.#
..#..#...#...###.
#...#.##.##...###
####..#.....#..##
.#.##..#..##....#
#.#.#..#.#.###.##
.#.###.###.##..##
#.#.##......#.#.#
....#..###.#.####
.###...#####.#..#

### Frame 4

#..#.#....#.#.#.#
.#.#.##..#....#.#
#..#.##.#..##.#.#
.###.##....#..###
#..#######..#.#.#
.#...#...###.#..#
##.#.#.####..###.
..#..##.....#.###
#..###..#.#..#..#
..#..#.#..#..#..#
..#..#....##....#
#.#....##..##.###
#.##...#..####..#
#####...#.#..#.#.
.#..##...##.#.###
#.#.##.#.#.###.##

### Frame 5

..#...#.###.#.###
#..#...#..#..#..#
##.#..#.##..#.###
#.#.##....#...##.
#.##.#.###....##.
.##.#..#.#.#.....
###..##.#..##.###
#..#...#..#.#....
#..###.##...#....
.###..##.#..#..##
#..#..#.##..#..##
#.###......#..###
..##..#..#...#..#
#..##.##..#..#...
#####.#...#...#..
.#..#.#.####..#.#

### Frame 6

...##..#...##..#.
###.#.###.####..#
...##.#..##..##.#
.#.####..#......#
###.##.....#..#.#
..##...###...#...
###.....####..#.#
.#.#.#..#..#..#.#
..#...#..##.###..
.######.###.#.#.#
#.#.####.####..#.
#.#..##.##.##....
.#....##...#..#.#
.#..#.#.#.#..##.#
....#.#.#..##...#
#..#.###..#..#...

### Frame 7

.####....#...#.#.
#.#.#.###.....#.#
##....#.#...#.##.
##.##...#..#.##..
..#..#......######
#...#.#.##.#..#..
###.....#...#.#..
...##..#.#..##...
#.##.##.##......#
......##.##.#..##
..##.#.....#..#.#
...###...##.##..#
...#...#.###.#..#
##..#.#.#.#.#.#.#
#.#.#.##...#..#.#
.###...##.#......

### Frame 8

.#..#.##.#..##..#
.#..#.##..#..#..#
#..##..#.....#.##
#..####......#.##
..#..#..####.#.##
.####....#..##..#
.#.#.##..##..##..
#..#.#.#..#..##.#
#.##.#.##..##...#
#..#.#.#.#######.
.##.###..#.#.#.##
#######..#.##.#..
###..##..#.##..#.
.##.....###...###
..#..#..#...#..##
.##.##..#..#.#..#

______________________________________________________________________

## Reproducibility

- RNG seed: `1337`
- Bernoulli p: `0.5`
- MD5 of concatenated frame characters (including newlines between rows/frames):\
  `363c791829522b3dc2174520bc6e2ac0`

## Troubleshooting checklist

- **High score here?** Check that you are:
  - Comparing **across time** (t vs. t+1), not within-frame.
  - Using the **same preprocessing** as `glider.md` (tokenization, binarization, normalization).
  - Averaging the correct **time axis** and not including t=0 twice.
  - Not accidentally shuffling frames or caching results across examples.

## License

CC0-1.0 / Public Domain.
