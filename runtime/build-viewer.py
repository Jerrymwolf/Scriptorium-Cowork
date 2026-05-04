#!/usr/bin/env python3
"""Build a click-to-source HTML viewer from a synthesis + corpus + evidence triple.

Usage:
  python3 scripts/build-viewer.py \\
    --synthesis path/to/synthesis.md \\
    --corpus path/to/corpus.jsonl \\
    --evidence path/to/evidence.jsonl \\
    --out path/to/viewer.html [--title "My Review"]

The output is a self-contained HTML file. Drop it into mcp__cowork__create_artifact
to render it as a persistent Cowork sidebar artifact, or open it directly in a browser.
"""
import argparse
import json
import re
import sys
from html import escape
from pathlib import Path


TOKEN_RE = re.compile(
    r"\[([a-zA-Z][a-zA-Z0-9_\-]*:[a-zA-Z0-9_\-]+):"
    r"(abstract|page:[0-9\-]+|sec:[a-zA-Z_\-]+|L[0-9]+-L[0-9]+)\]"
)


def author_year(p):
    auths = p.get("authors", [])
    if not auths:
        return f"Anon ({p.get('year', '?')})"
    first = auths[0]
    lastname = first.split(",")[0].strip().split()[-1] if "," in first else first.split()[-1]
    if len(auths) == 1:
        return f"{lastname} ({p.get('year', '?')})"
    if len(auths) == 2:
        second = auths[1]
        l2 = second.split(",")[0].strip().split()[-1] if "," in second else second.split()[-1]
        return f"{lastname} & {l2} ({p.get('year', '?')})"
    return f"{lastname} et al. ({p.get('year', '?')})"


def md_to_html(text, paper_lookup):
    def render_token(m):
        pid, loc = m.group(1), m.group(2)
        paper = paper_lookup.get(pid)
        if not paper:
            return f'<span class="cite cite-broken" title="Unresolved: {pid}">{pid}</span>'
        label = author_year(paper)
        return (
            f'<span class="cite" data-pid="{escape(pid)}" '
            f'data-loc="{escape(loc)}">{escape(label)}</span>'
        )

    text = TOKEN_RE.sub(render_token, text)
    out, in_para = [], False
    for line in text.split("\n"):
        line = line.rstrip()
        if line.startswith("# "):
            if in_para: out.append("</p>"); in_para = False
            out.append(f"<h1>{line[2:]}</h1>")
        elif line.startswith("## "):
            if in_para: out.append("</p>"); in_para = False
            out.append(f"<h2>{line[3:]}</h2>")
        elif line.startswith("### "):
            if in_para: out.append("</p>"); in_para = False
            out.append(f"<h3>{line[4:]}</h3>")
        elif line.startswith("---"):
            if in_para: out.append("</p>"); in_para = False
            out.append("<hr>")
        elif line.startswith(">"):
            if in_para: out.append("</p>"); in_para = False
            out.append(f"<blockquote>{line[1:].strip()}</blockquote>")
        elif line == "":
            if in_para: out.append("</p>"); in_para = False
        else:
            line = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", line)
            line = re.sub(r"(?<!\*)\*([^*]+)\*(?!\*)", r"<em>\1</em>", line)
            line = re.sub(r"`([^`]+)`", r"<code>\1</code>", line)
            if not in_para:
                out.append("<p>")
                in_para = True
            out.append(line)
    if in_para:
        out.append("</p>")
    return "\n".join(out)


def build_viewer(synthesis_md, corpus, evidence, title="Scriptorium synthesis"):
    # Filter corpus + evidence to citations actually present in synthesis
    cited_ids = set(m.group(1) for m in TOKEN_RE.finditer(synthesis_md))
    corpus_filtered = [p for p in corpus if p["paper_id"] in cited_ids]
    evidence_filtered = [e for e in evidence if e["paper_id"] in cited_ids]

    paper_lookup = {p["paper_id"]: p for p in corpus_filtered}
    n_unresolved = sum(
        1
        for m in TOKEN_RE.finditer(synthesis_md)
        if m.group(1) not in paper_lookup
    )

    # Slim payload for the viewer
    data_blob = {
        "papers": {
            p["paper_id"]: {
                "paper_id": p["paper_id"],
                "title": p.get("title", ""),
                "authors": p.get("authors", []),
                "year": p.get("year"),
                "doi": p.get("doi", ""),
                "venue": p.get("venue", ""),
            }
            for p in corpus_filtered
        },
        "evidence": [
            {
                "paper_id": e["paper_id"],
                "locator": e["locator"],
                "claim": (e.get("claim") or "")[:400],
                "quote": (e.get("quote") or "")[:600],
                "direction": e.get("direction", ""),
                "concept": e.get("concept", ""),
                "evidence_tier": e.get("evidence_tier", ""),
            }
            for e in evidence_filtered
        ],
    }
    data_json = json.dumps(data_blob).replace("</", "<\\/")
    synth_html = md_to_html(synthesis_md, paper_lookup)

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>{escape(title)} · click-to-source viewer</title>
<style>
:root {{ color-scheme: light; }}
* {{ box-sizing: border-box; }}
body {{ font-family: -apple-system, system-ui, BlinkMacSystemFont, "Segoe UI", sans-serif; margin: 0; padding: 0; background: #fafaf7; color: #1a1a1a; line-height: 1.65; }}
.app {{ display: grid; grid-template-columns: minmax(0, 1.6fr) minmax(0, 1fr); min-height: 100vh; }}
.doc {{ padding: 32px 40px; max-width: 760px; border-right: 0.5px solid rgba(0,0,0,0.12); }}
.pane {{ padding: 24px 28px; background: #f3f1ec; position: sticky; top: 0; height: 100vh; overflow-y: auto; }}
.topbar {{ display: flex; align-items: center; gap: 12px; padding: 10px 24px; border-bottom: 0.5px solid rgba(0,0,0,0.12); background: #fff; font-size: 12px; color: #555; }}
.topbar strong {{ color: #1a1a1a; font-weight: 500; }}
.pill {{ display: inline-flex; align-items: center; gap: 4px; padding: 2px 10px; border-radius: 999px; font-size: 11px; font-weight: 500; background: #eaf3de; color: #3b6d11; }}
h1 {{ font-size: 22px; font-weight: 500; margin: 0 0 18px; }}
h2 {{ font-size: 18px; font-weight: 500; margin: 28px 0 10px; padding-top: 8px; }}
h3 {{ font-size: 15px; font-weight: 500; margin: 20px 0 8px; color: #444; }}
p {{ font-size: 14px; line-height: 1.75; margin: 0 0 14px; }}
blockquote {{ font-family: "Iowan Old Style", Georgia, serif; font-style: italic; padding: 4px 14px; margin: 10px 0; border-left: 2px solid rgba(0,0,0,0.2); color: #444; font-size: 13.5px; }}
hr {{ border: none; border-top: 0.5px solid rgba(0,0,0,0.15); margin: 28px 0; }}
code {{ font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 12px; background: rgba(0,0,0,0.05); padding: 1px 5px; border-radius: 3px; }}
strong {{ font-weight: 500; }}
.cite {{ color: #185fa5; cursor: pointer; padding: 0 3px; border-radius: 3px; transition: background 0.1s; white-space: nowrap; font-weight: 500; }}
.cite:hover {{ background: #e6f1fb; }}
.cite.active {{ background: #b5d4f4; color: #042c53; }}
.cite-broken {{ color: #c82c2c; text-decoration: line-through; }}
.pane h4 {{ font-size: 11px; font-weight: 500; margin: 0 0 8px; color: #777; text-transform: uppercase; letter-spacing: 0.06em; }}
.empty {{ color: #888; font-size: 13px; line-height: 1.6; padding: 20px 0; }}
.card {{ background: #fff; border-radius: 10px; padding: 14px 16px; margin-bottom: 14px; border: 0.5px solid rgba(0,0,0,0.1); }}
.card .ttl {{ font-size: 14px; font-weight: 500; line-height: 1.35; margin-bottom: 6px; }}
.card .meta {{ font-size: 12px; color: #777; margin-bottom: 10px; }}
.card .meta a {{ color: #185fa5; text-decoration: none; }}
.tags {{ display: flex; flex-wrap: wrap; gap: 4px; margin: 8px 0; }}
.tag {{ display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 10px; font-weight: 500; }}
.tag-tier {{ background: #eee9dc; color: #5f5e5a; }}
.tag-positive {{ background: #eaf3de; color: #3b6d11; }}
.tag-negative {{ background: #fcebeb; color: #a32d2d; }}
.tag-neutral {{ background: #eee; color: #444; }}
.tag-mixed {{ background: #faeeda; color: #854f0b; }}
.tag-locator {{ background: #e6f1fb; color: #0c447c; font-family: ui-monospace, monospace; }}
.quote-block {{ background: #faf6e9; border-left: 3px solid #ef9f27; padding: 10px 14px; margin: 10px 0; font-size: 13px; line-height: 1.6; color: #444; border-radius: 4px; }}
.actions {{ display: flex; gap: 12px; font-size: 12px; margin-top: 12px; padding-top: 10px; border-top: 0.5px solid rgba(0,0,0,0.1); }}
.actions a {{ color: #185fa5; text-decoration: none; cursor: pointer; }}
.actions a:hover {{ text-decoration: underline; }}
@media (max-width: 720px) {{ .app {{ grid-template-columns: 1fr; }} .pane {{ position: static; height: auto; }} }}
</style>
</head>
<body>
<div class="topbar">
  <strong>{escape(title)} · click-to-source viewer</strong>
  <span class="pill">Scriptorium v0.2.0</span>
  <span style="margin-left: auto;">{len(corpus_filtered)} papers · {len(evidence_filtered)} evidence rows{"" if n_unresolved == 0 else f" · ⚠ {n_unresolved} unresolved citations"}</span>
</div>
<div class="app">
  <div class="doc" id="doc">{synth_html}</div>
  <div class="pane" id="pane">
    <h4>Source · click any author-year link to inspect</h4>
    <div class="empty" id="emptyState">
      Hover or click any blue author-year citation in the synthesis on the left.
      The card here shows the paper, the evidence-row metadata (tier, direction, locator),
      the verbatim quote that supports the cited claim, and a one-click link to the source.
    </div>
    <div id="cardSlot"></div>
  </div>
</div>
<script>
const DATA = {data_json};
function escapeHtml(s) {{ return String(s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }}
function renderCard(pid, loc) {{
  const paper = DATA.papers[pid];
  if (!paper) return '<div class="card"><div class="ttl">Citation broken</div><div class="meta">Could not resolve <code>'+pid+':'+loc+'</code></div></div>';
  const ev = DATA.evidence.find(e => e.paper_id === pid && e.locator === loc);
  const auths = paper.authors.join(', ');
  const doiHtml = paper.doi ? '<a href="https://doi.org/'+paper.doi+'" target="_blank">doi:'+paper.doi+'</a>' : '<span style="color:#999">no DOI</span>';
  const tier = ev ? ev.evidence_tier.replace(/_/g, ' ') : '—';
  const dir = ev ? ev.direction : '';
  const concept = ev ? ev.concept : '';
  const quote = ev ? ev.quote : '(no evidence row matched at this locator)';
  const claim = ev ? ev.claim : '';
  const openHref = paper.doi ? 'https://doi.org/'+paper.doi : '#';
  return `<div class="card">
    <div class="ttl">${{escapeHtml(paper.title)}}</div>
    <div class="meta">${{escapeHtml(auths)}} · <em>${{escapeHtml(paper.venue || 'unknown venue')}}</em> · ${{paper.year}}<br>${{doiHtml}}</div>
    <div class="tags">
      <span class="tag tag-tier">${{tier}}</span>
      ${{dir ? '<span class="tag tag-'+dir+'">'+dir+'</span>' : ''}}
      <span class="tag tag-locator">${{loc}}</span>
      ${{concept ? '<span class="tag tag-tier">'+concept.replace(/_/g, ' ')+'</span>' : ''}}
    </div>
    ${{claim ? '<div style="font-size:12px; color:#555; margin:8px 0; line-height:1.5;"><strong>Claim:</strong> '+escapeHtml(claim)+'</div>' : ''}}
    <div class="quote-block">${{escapeHtml(quote)}}</div>
    <div class="actions">
      <a href="${{openHref}}" target="_blank">Open paper ↗</a>
      <a onclick="copyQuote(this)" data-quote="${{escapeHtml(quote)}}">Copy quote</a>
      <a onclick="showRelated('${{pid}}')">Other claims from this paper</a>
    </div>
  </div>`;
}}
function copyQuote(el) {{ navigator.clipboard.writeText(el.dataset.quote); el.textContent = 'Copied ✓'; setTimeout(() => el.textContent = 'Copy quote', 1500); }}
function showRelated(pid) {{
  const rows = DATA.evidence.filter(e => e.paper_id === pid);
  const paper = DATA.papers[pid];
  document.getElementById('cardSlot').innerHTML = '<div class="card"><div class="ttl">All evidence rows · ' + escapeHtml(paper.title) + '</div>' +
    rows.map(r => '<div style="font-size:12px; padding:8px 0; border-top:0.5px solid #eee;"><strong>'+r.locator+'</strong> · <span class="tag tag-tier">'+r.evidence_tier.replace(/_/g,' ')+'</span><br>'+escapeHtml(r.claim)+'</div>').join('') + '</div>';
  document.getElementById('emptyState').style.display = 'none';
}}
function activate(el, pid, loc) {{
  document.querySelectorAll('.cite.active').forEach(c => c.classList.remove('active'));
  el.classList.add('active');
  document.getElementById('emptyState').style.display = 'none';
  document.getElementById('cardSlot').innerHTML = renderCard(pid, loc);
}}
document.querySelectorAll('.cite[data-pid]').forEach(el => {{
  el.addEventListener('click', () => activate(el, el.dataset.pid, el.dataset.loc));
}});
</script>
</body>
</html>
"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--synthesis", required=True, help="Path to synthesis.md")
    ap.add_argument("--corpus", required=True, help="Path to corpus.jsonl")
    ap.add_argument("--evidence", required=True, help="Path to evidence.jsonl")
    ap.add_argument("--out", required=True, help="Path to output viewer.html")
    ap.add_argument("--title", default="Scriptorium synthesis", help="Display title")
    args = ap.parse_args()

    synthesis = Path(args.synthesis).read_text()
    corpus = [json.loads(l) for l in Path(args.corpus).read_text().splitlines() if l.strip()]
    evidence = [json.loads(l) for l in Path(args.evidence).read_text().splitlines() if l.strip()]

    html = build_viewer(synthesis, corpus, evidence, title=args.title)
    out_path = Path(args.out)
    out_path.write_text(html)
    print(f"Wrote {out_path} ({out_path.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
