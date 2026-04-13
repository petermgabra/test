from decimal import Decimal, ROUND_HALF_UP

def abap_round(value, decimals):
    return value.quantize(Decimal('1.' + '0' * decimals), rounding=ROUND_HALF_UP)

def simulate_ztest7aga(p_input):
    # P has 4 decimals (BAPIACCR09-AMT_DOCCUR)
    p = abap_round(Decimal(str(p_input)), 4)

    # p = p / 10
    # The result of the division is assigned back to p, so it is rounded to 4 decimals
    p = abap_round(p / Decimal('10'), 4)

    # V_round has 2 decimals
    v_round = abap_round(p, 2)

    return p, v_round

test_cases = [100.00, 123.4567, 1.2345, 1.2355, 5.5555, 5.5554, 5.5556]

for tc in test_cases:
    p_after_div, v_round = simulate_ztest7aga(tc)
    print(f"Input: {tc} -> P after div: {p_after_div}, V_round: {v_round}")
