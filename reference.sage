import csv, math, os

###############
# Utilities
###############

def _float(x):
    try:
        return float(x)
    except Exception:
        return None

def _int(x):
    try:
        return int(float(x))
    except Exception:
        return None

def _next_prime_1mod3(n):
    p = next_prime(n)
    while p % 3 != 1:
        p = next_prime(p + 1)
    return p

def _read_csv_rows(fname):
    rows = []
    with open(fname, 'r') as f:
        for r in csv.DictReader(f):
            rows.append(r)
    return rows

def _write_csv(fname, rows, header):
    with open(fname, 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=header)
        w.writeheader()
        for r in rows:
            w.writerow(r)

