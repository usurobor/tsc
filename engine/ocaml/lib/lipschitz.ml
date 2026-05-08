(** Lipschitz constants for the barrier+exponential coherence link.

    For the canonical barrier phi(delta) = delta/(1-delta), the coherence
    link f_lambda(delta) = exp(-lambda * phi(delta)) has closed-form
    Lipschitz constant L_link(lambda) from spec/tsc-core.md §7.1:

      L_link(lambda) = (4/lambda) * exp(lambda - 2)   for 0 < lambda <= 2
                     = lambda                          for lambda >= 2

    Continuous at lambda = 2 (both branches give 2). *)

(** l_link: link-Lipschitz constant for the canonical barrier phi.
    Requires lambda > 0. *)
let l_link lambda =
  if lambda <= 0.0 then invalid_arg "l_link: lambda must be > 0"
  else if lambda <= 2.0 then
    (4.0 /. lambda) *. exp (lambda -. 2.0)
  else
    lambda
