"""Download the Olist dataset from Kaggle into data/raw/.

Requires a Kaggle account and an API token saved at ~/.kaggle/kaggle.json
(Kaggle → Settings → API → Create New Token). Run from the repo root:

    .venv\\Scripts\\python.exe scripts\\download_data.py

If you prefer, download the zip manually from
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce and extract it
into data/raw/ — this script then just verifies the files.
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw"

EXPECTED = {
    "olist_customers_dataset.csv": 99_441,
    "olist_geolocation_dataset.csv": 1_000_163,
    "olist_order_items_dataset.csv": 112_650,
    "olist_order_payments_dataset.csv": 103_886,
    "olist_order_reviews_dataset.csv": 99_224,
    "olist_orders_dataset.csv": 99_441,
    "olist_products_dataset.csv": 32_951,
    "olist_sellers_dataset.csv": 3_095,
    "product_category_name_translation.csv": 71,
}


def missing_files() -> list[str]:
    return [f for f in EXPECTED if not (RAW / f).exists()]


def download() -> None:
    try:
        import kaggle  # noqa: F401  (import triggers credential check)
    except ImportError:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "-q", "kaggle"])
    # Use the kaggle CLI installed next to this interpreter (venv Scripts/ is not on PATH).
    exe = Path(sys.executable).parent / ("kaggle.exe" if sys.platform == "win32" else "kaggle")
    subprocess.check_call(
        [str(exe), "datasets", "download", "-d", "olistbr/brazilian-ecommerce",
         "-p", str(RAW), "--unzip"]
    )


def verify() -> bool:
    import pandas as pd

    ok = True
    print(f"{'file':45s} {'rows':>10s} {'expected':>10s}")
    for name, expected in EXPECTED.items():
        path = RAW / name
        if not path.exists():
            print(f"{name:45s} {'MISSING':>10s} {expected:>10,d}")
            ok = False
            continue
        # pandas, not a raw line count: review comments contain quoted newlines.
        rows = len(pd.read_csv(path, usecols=[0]))
        flag = "" if rows == expected else "  <-- differs"
        print(f"{name:45s} {rows:>10,d} {expected:>10,d}{flag}")
    return ok


if __name__ == "__main__":
    RAW.mkdir(parents=True, exist_ok=True)
    if missing_files():
        print("Downloading from Kaggle ...")
        try:
            download()
        except Exception as exc:  # credentials missing, no network, etc.
            print(f"\nDownload failed: {exc}\n"
                  "Download manually from the Kaggle page and extract into data/raw/.")
    print()
    sys.exit(0 if verify() else 1)
