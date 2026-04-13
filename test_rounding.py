from decimal import Decimal, ROUND_HALF_UP

def abap_round(value, decimals):
    return value.quantize(Decimal('1.' + '0' * decimals), rounding=ROUND_HALF_UP)

def simulate_ztest7aga(p_input):
    p = abap_round(Decimal(str(p_input)), 4)
    p = abap_round(p / Decimal('10'), 4)
    v_round = abap_round(p, 2)
    return v_round

def test_rounding():
    assert simulate_ztest7aga(100.00) == Decimal('10.00')
    assert simulate_ztest7aga(50.00) == Decimal('5.00')
    assert simulate_ztest7aga(1.2345) == Decimal('0.12')
    assert simulate_ztest7aga(1.2355) == Decimal('0.12')
    assert simulate_ztest7aga(1.25) == Decimal('0.13')
    print("All tests passed!")

if __name__ == "__main__":
    test_rounding()
