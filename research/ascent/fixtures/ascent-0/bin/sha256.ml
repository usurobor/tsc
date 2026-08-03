(* Pure-OCaml SHA-256 (FIPS 180-4). No external dependencies.

   Rationale: the fixture generator must emit *real*, independently
   checkable content digests. OCaml's stdlib [Digest] is MD5; we want a
   digest a reviewer can reproduce with the system [sha256sum] on the
   emitted bytes. So we implement the standard algorithm and verify it
   against a known-answer test at startup ([self_test]).

   This is not a security primitive for secrecy — see README "Sealing".
   It is a tamper-evident content hash. *)

let k =
  [| 0x428a2f98l; 0x71374491l; 0xb5c0fbcfl; 0xe9b5dba5l; 0x3956c25bl;
     0x59f111f1l; 0x923f82a4l; 0xab1c5ed5l; 0xd807aa98l; 0x12835b01l;
     0x243185bel; 0x550c7dc3l; 0x72be5d74l; 0x80deb1fel; 0x9bdc06a7l;
     0xc19bf174l; 0xe49b69c1l; 0xefbe4786l; 0x0fc19dc6l; 0x240ca1ccl;
     0x2de92c6fl; 0x4a7484aal; 0x5cb0a9dcl; 0x76f988dal; 0x983e5152l;
     0xa831c66dl; 0xb00327c8l; 0xbf597fc7l; 0xc6e00bf3l; 0xd5a79147l;
     0x06ca6351l; 0x14292967l; 0x27b70a85l; 0x2e1b2138l; 0x4d2c6dfcl;
     0x53380d13l; 0x650a7354l; 0x766a0abbl; 0x81c2c92el; 0x92722c85l;
     0xa2bfe8a1l; 0xa81a664bl; 0xc24b8b70l; 0xc76c51a3l; 0xd192e819l;
     0xd6990624l; 0xf40e3585l; 0x106aa070l; 0x19a4c116l; 0x1e376c08l;
     0x2748774cl; 0x34b0bcb5l; 0x391c0cb3l; 0x4ed8aa4al; 0x5b9cca4fl;
     0x682e6ff3l; 0x748f82eel; 0x78a5636fl; 0x84c87814l; 0x8cc70208l;
     0x90befffal; 0xa4506cebl; 0xbef9a3f7l; 0xc67178f2l |]

let ( &. ) = Int32.logand
let ( |. ) = Int32.logor
let ( ^. ) = Int32.logxor
let ( +. ) = Int32.add
let lnot32 = Int32.lognot

let rotr x n =
  (Int32.shift_right_logical x n) |. (Int32.shift_left x (32 - n))

let shr x n = Int32.shift_right_logical x n

let digest_bytes (msg : bytes) : string =
  let h = [| 0x6a09e667l; 0xbb67ae85l; 0x3c6ef372l; 0xa54ff53al;
             0x510e527fl; 0x9b05688cl; 0x1f83d9abl; 0x5be0cd19l |] in
  let ml = Bytes.length msg in
  (* padding: 0x80, then zeros, then 64-bit big-endian bit length *)
  let bitlen = Int64.of_int (ml * 8) in
  let padlen =
    let r = (ml + 1) mod 64 in
    if r <= 56 then 56 - r else 120 - r
  in
  let total = ml + 1 + padlen + 8 in
  let m = Bytes.make total '\000' in
  Bytes.blit msg 0 m 0 ml;
  Bytes.set m ml '\x80';
  for i = 0 to 7 do
    let shift = 8 * (7 - i) in
    Bytes.set m (total - 8 + i)
      (Char.chr (Int64.to_int (Int64.logand (Int64.shift_right_logical bitlen shift) 0xFFL)))
  done;
  let w = Array.make 64 0l in
  let nblocks = total / 64 in
  for b = 0 to nblocks - 1 do
    let base = b * 64 in
    for t = 0 to 15 do
      let o = base + t * 4 in
      let g i = Int32.of_int (Char.code (Bytes.get m (o + i))) in
      w.(t) <-
        (Int32.shift_left (g 0) 24)
        |. (Int32.shift_left (g 1) 16)
        |. (Int32.shift_left (g 2) 8)
        |. (g 3)
    done;
    for t = 16 to 63 do
      let s0 = (rotr w.(t-15) 7) ^. (rotr w.(t-15) 18) ^. (shr w.(t-15) 3) in
      let s1 = (rotr w.(t-2) 17) ^. (rotr w.(t-2) 19) ^. (shr w.(t-2) 10) in
      w.(t) <- w.(t-16) +. s0 +. w.(t-7) +. s1
    done;
    let a = ref h.(0) and b' = ref h.(1) and c = ref h.(2) and d = ref h.(3)
    and e = ref h.(4) and f = ref h.(5) and g = ref h.(6) and hh = ref h.(7) in
    for t = 0 to 63 do
      let big_s1 = (rotr !e 6) ^. (rotr !e 11) ^. (rotr !e 25) in
      let ch = (!e &. !f) ^. ((lnot32 !e) &. !g) in
      let temp1 = !hh +. big_s1 +. ch +. k.(t) +. w.(t) in
      let big_s0 = (rotr !a 2) ^. (rotr !a 13) ^. (rotr !a 22) in
      let maj = (!a &. !b') ^. (!a &. !c) ^. (!b' &. !c) in
      let temp2 = big_s0 +. maj in
      hh := !g; g := !f; f := !e; e := !d +. temp1;
      d := !c; c := !b'; b' := !a; a := temp1 +. temp2
    done;
    h.(0) <- h.(0) +. !a; h.(1) <- h.(1) +. !b'; h.(2) <- h.(2) +. !c;
    h.(3) <- h.(3) +. !d; h.(4) <- h.(4) +. !e; h.(5) <- h.(5) +. !f;
    h.(6) <- h.(6) +. !g; h.(7) <- h.(7) +. !hh
  done;
  let buf = Buffer.create 64 in
  Array.iter
    (fun x ->
       Buffer.add_string buf (Printf.sprintf "%08lx" (x &. 0xFFFFFFFFl)))
    h;
  Buffer.contents buf

let digest_string (s : string) : string = digest_bytes (Bytes.of_string s)

(* Known-answer tests (FIPS 180-4 examples). Aborts if the implementation
   is wrong, so no emitted digest can be silently incorrect. *)
let self_test () =
  let cases =
    [ "", "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
      "abc", "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad";
      "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
      "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1" ]
  in
  List.iter
    (fun (inp, expect) ->
       let got = digest_string inp in
       if got <> expect then
         failwith (Printf.sprintf "SHA-256 self-test FAILED for %S: got %s" inp got))
    cases
