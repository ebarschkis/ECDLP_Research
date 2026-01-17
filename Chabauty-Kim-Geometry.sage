import sage.all as sg

try:
    load("reference.sage")
except Exception:
    def _next_prime_1mod3(n):
        p = sg.next_prime(n)
        while p % 3 != 1:
            p = sg.next_prime(p + 1)
        return p


def _toy_secp_curve(bits=16, p_override=None):
    if p_override is not None:
        p = int(p_override)
    else:
        p = _next_prime_1mod3(2**bits + 54321)
    return p, sg.EllipticCurve(sg.GF(p), [0, 7])


def _formal_group_log(E_Qp, P):
    F = E_Qp.formal_group()
    t = -P[0] / P[1]
    if t.valuation() <= 0:
        return None, t
    return F.log()(t), t


def _point_from_t(E_Qp, t):
    F = E_Qp.formal_group()
    x = F.x()(t)
    y = F.y()(t)
    return E_Qp(x, y)


def analyze_shadow_field(bits=16, secret_k=123, prec=20, p_override=None):
    print("--- initializing toy-secp256k1 shadow probe ---")

    # 1. Define toy secp-like curve (j=0, p ≡ 1 mod 3).
    p, E_Fp = _toy_secp_curve(bits=bits, p_override=p_override)
    print(f"Target Curve: y^2 = x^3 + 7 over F_{p} (bits={bits})")
    print(f"Order: {E_Fp.order()}")
    print(f"Trace of Frobenius: {E_Fp.trace_of_frobenius()} (Not 1 -> Not Anomalous)")

    # 2. Canonical lift to Q_p (same coefficients for j=0).
    Qp = sg.Qp(p, prec)
    E_Qp = sg.EllipticCurve(Qp, [0, 7])

    # 3. Select points on E(Fp).
    G = E_Fp.gens()[0]
    order = G.order()
    k = secret_k % order
    if k == 0:
        k = 1
    P_target = k * G

    print(f"\nGenerator G: {G}")
    print(f"Target P (hidden k): {P_target}")

    # 4. Lift points via Teichmüller lift (integral coordinates).
    try:
        G_lift = E_Qp.lift_x(Integer(G[0]))
        P_lift = E_Qp.lift_x(Integer(P_target[0]))
    except ValueError:
        print("Lifting failed (point singular or non-residue). Retrying with new points...")
        return

    print(f"\n[Shadow Field] Lifted G to Q_{p}:")
    print(f"  ({G_lift[0] + O(p**3)}, ...)")

    # 5. Formal group log only applies to points reducing to O (t has positive valuation).
    phi_G, t_G = _formal_group_log(E_Qp, G_lift)
    phi_P, t_P = _formal_group_log(E_Qp, P_lift)

    print(f"\n[Formal Group Check] t-parameters:")
    print(f"  v_p(t_G) = {t_G.valuation()}, v_p(t_P) = {t_P.valuation()}")
    if phi_G is None or phi_P is None:
        print("  Teichmüller lifts are not in the formal group (no p-adic log).")

    # 6. Demonstrate linearity inside the formal group (Smart-style regime).
    t0 = Qp(p)  # small parameter => point in E1
    G1 = _point_from_t(E_Qp, t0)
    P1 = k * G1
    phi_G1, _ = _formal_group_log(E_Qp, G1)
    phi_P1, _ = _formal_group_log(E_Qp, P1)

    print(f"\n[Formal Group Log] Example inside E1:")
    print(f"  log(G1) = {phi_G1 + O(p**5)}")
    print(f"  log(P1) = {phi_P1 + O(p**5)}")
    recovered_k = phi_P1 / phi_G1
    print(f"  log(P1)/log(G1) = {recovered_k + O(p**5)}")
    print(f"  Expected k       = {k}")


analyze_shadow_field()
