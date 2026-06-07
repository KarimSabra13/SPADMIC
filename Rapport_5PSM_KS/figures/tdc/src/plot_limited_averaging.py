from pathlib import Path

import matplotlib.pyplot as plt


OUT_DIR = Path(__file__).resolve().parents[1] / "final_mptdc"
OUT_DIR.mkdir(parents=True, exist_ok=True)

points = [
    (1, 18.823, 15.528, 31.581),
    (2, 13.227, 10.704, 21.616),
    (4, 9.284, 7.448, 15.185),
    (8, 6.574, 5.295, 10.708),
    (15, 4.769, 3.802, 7.882),
    (20, 4.199, 3.351, 6.925),
    (25, 3.629, 2.902, 5.909),
    (30, 3.391, 2.694, 5.574),
    (40, 2.919, 2.323, 4.790),
    (50, 2.643, 2.101, 4.339),
]

n = [p[0] for p in points]
rmse = [p[1] for p in points]
mae = [p[2] for p in points]
p90 = [p[3] for p in points]

plt.rcParams.update({
    "font.size": 9,
    "axes.titlesize": 11,
    "axes.labelsize": 9,
    "legend.fontsize": 8,
})

fig, ax = plt.subplots(figsize=(6.6, 3.7), dpi=180)
ax.plot(n, rmse, marker="o", linewidth=1.8, color="#315F8C", label="RMSE")
ax.plot(n, mae, marker="s", linewidth=1.4, color="#3A7A57", label="MAE")
ax.plot(n, p90, marker="^", linewidth=1.4, color="#8A4B08", label="P90")

ax.axhline(10, color="#6C737A", linestyle="--", linewidth=0.9)
ax.axhline(5, color="#6C737A", linestyle=":", linewidth=0.9)
ax.text(51.5, 10.2, "10 ps", color="#6C737A", fontsize=8, va="bottom")
ax.text(51.5, 5.2, "5 ps", color="#6C737A", fontsize=8, va="bottom")

ax.set_xlim(0, 64)
ax.set_ylim(0, 34)
ax.set_xticks([1, 2, 4, 8, 15, 30, 50, 64])
ax.set_xlabel("Nombre de mesures moyennées N")
ax.set_ylabel("Erreur (ps)")
ax.set_title("Moyennage post-LUT sur le domaine statistique retenu")
ax.grid(True, which="major", color="#D6DCE2", linewidth=0.7)
ax.legend(loc="upper right", frameon=True)

fig.tight_layout()
for ext in ("png", "pdf"):
    fig.savefig(OUT_DIR / f"03_rmse_vs_moyennage_limited.{ext}", bbox_inches="tight")
plt.close(fig)
