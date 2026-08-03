# Ascent-0 fixture generator + sealed oracle (#119).
# No external dependencies beyond the OCaml stdlib + unix.

GEN = dune exec bin/ascent0_gen.exe --
OUT = generated

.PHONY: build emit replay verify selftest check clean

build:
	dune build

# Regenerate every public artifact + the reveal bundle + MANIFEST.
emit: build
	$(GEN) emit $(OUT)

# Prove byte identity: rebuild in memory and diff against the committed tree.
replay: build
	$(GEN) replay $(OUT)

# Prove the sealed-oracle commitments bind the reveal bundle.
verify: build
	$(GEN) verify $(OUT)

selftest: build
	$(GEN) selftest

# Full gate: replay (digest identity) + verify (seal) + independent sha256sum -c.
check: build
	$(GEN) replay $(OUT)
	$(GEN) verify $(OUT)
	cd $(OUT) && sha256sum -c MANIFEST.sha256

clean:
	dune clean
