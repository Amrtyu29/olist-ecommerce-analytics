"""Shared chart style for all notebooks.

Colours come from a colour-blind-validated categorical palette (fixed slot order,
never cycled), a single-hue blue sequential ramp and a blue/red diverging pair.
Import with `from viz_style import *` at the top of a notebook.
"""
from pathlib import Path
import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap

# Categorical slots (identity) — assign in this order, never cycle past 8.
SERIES = ["#2a78d6", "#eb6834", "#1baf7a", "#eda100", "#e87ba4", "#008300", "#6250d6", "#e34948"]
BLUE, ORANGE, AQUA, YELLOW, MAGENTA, GREEN, VIOLET, RED = SERIES

# Sequential ramp (magnitude): one hue, light -> dark
SEQ_STEPS = ["#cde2fb", "#9ec5f4", "#6da7ec", "#3987e5", "#256abf", "#1c5cab", "#104281", "#0d366b"]
CMAP_SEQ = LinearSegmentedColormap.from_list("olist_blue", SEQ_STEPS)

# Diverging (polarity): blue <-> neutral grey <-> red
CMAP_DIV = LinearSegmentedColormap.from_list("olist_div", ["#1c5cab", "#6da7ec", "#f0efec", "#ec835a", "#d03b3b"])

# Chrome & ink
SURFACE, INK, INK2, MUTED, GRID, AXIS = "#fcfcfb", "#0b0b0b", "#52514e", "#898781", "#e1e0d9", "#c3c2b7"

FIG_DIR = Path(__file__).resolve().parent.parent / "report" / "figures"
FIG_DIR.mkdir(parents=True, exist_ok=True)

mpl.rcParams.update({
    "figure.facecolor": SURFACE, "axes.facecolor": SURFACE, "savefig.facecolor": SURFACE,
    "figure.dpi": 110, "savefig.dpi": 160, "savefig.bbox": "tight",
    "font.family": "sans-serif", "font.sans-serif": ["Segoe UI", "DejaVu Sans", "Arial"],
    "font.size": 10, "axes.titlesize": 12, "axes.titleweight": "semibold", "axes.titlelocation": "left",
    "axes.labelsize": 10, "axes.labelcolor": INK2,
    "axes.edgecolor": AXIS, "axes.linewidth": 0.8, "axes.spines.top": False, "axes.spines.right": False,
    "axes.grid": True, "axes.grid.axis": "y", "grid.color": GRID, "grid.linewidth": 0.6,
    "xtick.color": MUTED, "ytick.color": MUTED, "xtick.labelsize": 9, "ytick.labelsize": 9,
    "text.color": INK, "legend.frameon": False, "legend.fontsize": 9,
    "lines.linewidth": 2, "lines.markersize": 6,
    "axes.prop_cycle": mpl.cycler(color=SERIES),
})


def finish(ax, title: str, subtitle: str | None = None, ylabel: str | None = None, xlabel: str | None = None):
    """Title top-left, optional grey subtitle, light axis labels."""
    ax.set_title(title, pad=26 if subtitle else 8)
    if subtitle:
        ax.text(0, 1.015, subtitle, transform=ax.transAxes, color=INK2, fontsize=9, va="bottom")
    if ylabel is not None:
        ax.set_ylabel(ylabel)
    if xlabel is not None:
        ax.set_xlabel(xlabel)
    return ax


def save(fig, name: str):
    """Save a figure as PNG under report/figures and return the path."""
    path = FIG_DIR / f"{name}.png"
    fig.savefig(path)
    return path


def fmt_brl(x, _=None):
    """Axis formatter: R$ in thousands / millions."""
    if abs(x) >= 1e6:
        return f"R${x/1e6:.1f}M"
    if abs(x) >= 1e3:
        return f"R${x/1e3:.0f}k"
    return f"R${x:.0f}"
