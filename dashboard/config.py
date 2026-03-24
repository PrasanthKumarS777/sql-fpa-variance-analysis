import mysql.connector
import pandas as pd

# ── Database Connection ──────────────────────────
DB_CONFIG = {
    "host": "localhost",
    "user": "root",
    "password": "Pr@santh001",  
    "database": "fpa_variance_db"
}

def run_query(sql: str) -> pd.DataFrame:
    conn = mysql.connector.connect(**DB_CONFIG)
    df = pd.read_sql(sql, conn)
    conn.close()
    return df

# ── Design Theme ─────────────────────────────────
COLORS = {
    "bg":          "#0F1117",
    "card":        "#1E2130",
    "positive":    "#00D4AA",
    "negative":    "#FF4B4B",
    "warning":     "#FFB347",
    "neutral":     "#7B8CDE",
    "text":        "#EAEAEA",
    "subtext":     "#8892A4",
    "border":      "#2E3347",
    "chart_grid":  "#2E3347",
}

CHART_LAYOUT = dict(
    paper_bgcolor="#1E2130",
    plot_bgcolor="#1E2130",
    font=dict(family="Inter, sans-serif", color="#EAEAEA", size=13),
    margin=dict(l=20, r=20, t=40, b=20),
    xaxis=dict(gridcolor="#2E3347", showgrid=True, zeroline=False),
    yaxis=dict(gridcolor="#2E3347", showgrid=True, zeroline=False),
    legend=dict(bgcolor="#1E2130", bordercolor="#2E3347", borderwidth=1),
    hoverlabel=dict(bgcolor="#0F1117", font_color="#EAEAEA", bordercolor="#2E3347")
)

# ── KPI Card HTML ─────────────────────────────────
def kpi_card(title, value, delta=None, delta_label="vs budget", color="#00D4AA"):
    delta_html = ""
    if delta is not None:
        arrow = "▲" if delta > 0 else "▼"
        d_color = "#FF4B4B" if delta > 0 else "#00D4AA"
        delta_html = f"""
        <div style='font-size:13px; color:{d_color}; margin-top:6px;'>
            {arrow} {abs(delta):.1f}% {delta_label}
        </div>"""
    return f"""
    <div style='
        background:#1E2130;
        border:1px solid #2E3347;
        border-radius:12px;
        padding:20px 24px;
        text-align:center;
        border-top: 3px solid {color};
    '>
        <div style='font-size:12px; color:#8892A4; text-transform:uppercase;
                    letter-spacing:1.2px; margin-bottom:8px;'>{title}</div>
        <div style='font-size:28px; font-weight:700; color:{color};'>{value}</div>
        {delta_html}
    </div>"""

# ── Page Config ───────────────────────────────────
PAGE_CONFIG = dict(
    page_title="FP&A Intelligence System",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded"
)

# ── Streamlit Global CSS ──────────────────────────
GLOBAL_CSS = """
<style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');

    html, body, [class*="css"] {
        font-family: 'Inter', sans-serif;
        background-color: #0F1117;
        color: #EAEAEA;
    }
    .block-container { padding: 2rem 2.5rem 2rem 2.5rem; }
    section[data-testid="stSidebar"] {
        background-color: #1E2130;
        border-right: 1px solid #2E3347;
    }
    section[data-testid="stSidebar"] * { color: #EAEAEA !important; }
    .stSelectbox > div > div {
        background-color: #1E2130 !important;
        border: 1px solid #2E3347 !important;
        color: #EAEAEA !important;
    }
    div[data-testid="metric-container"] {
        background-color: #1E2130;
        border: 1px solid #2E3347;
        border-radius: 12px;
        padding: 16px;
    }
    .stDataFrame { background-color: #1E2130; }
    hr { border-color: #2E3347; }
    h1 { font-weight: 700; color: #EAEAEA; }
    h2 { font-weight: 600; color: #EAEAEA; }
    h3 { font-weight: 500; color: #8892A4; }
</style>
"""
