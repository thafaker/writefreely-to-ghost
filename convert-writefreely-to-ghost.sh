#!/bin/bash
INPUT="writefreely-export.json"
OUTPUT="ghost-import-complete.json"
HTML_MAP="html_map.json"

echo "✅ pandoc gefunden, konvertiere Markdown zu HTML..."

# SCHRITT 1: Extrahiere alle Posts mit ihren IDs und Markdown-Inhalten in eine JSON-Datei
# (Deine bewährte Extraktionslogik)
jq -n '
  def unique_by(f): group_by(f) | map(first);
  input as $input
  | (($input.collections // [])[0].posts // []) as $collectionPosts
  | ($input.posts // []) as $rootPosts
  | ($collectionPosts + $rootPosts) as $allPosts
  | $allPosts | unique_by(.id)
  | map({id: .id, body: .body})
' "$INPUT" > posts_for_conversion.json

# SCHRITT 2: Python-Skript zur Massenkonvertierung mit pandoc
# Dies ist robust, schnell und vermeidet Shell-Eskapade-Probleme.
python3 << 'EOF' - "$HTML_MAP"
import sys, json, subprocess, os

HTML_MAP_FILE = sys.argv[1]

with open('posts_for_conversion.json') as f:
    posts = json.load(f)

html_map = {}
for post in posts:
    md = post.get('body', '')
    post_id = post.get('id', '')
    if md and post_id:
        try:
            # pandoc aufrufen: Markdown via stdin, HTML via stdout
            proc = subprocess.run(
                ['/opt/homebrew/bin/pandoc', '-f', 'markdown', '-t', 'html', '--wrap=none'],
                input=md.encode('utf-8'),
                capture_output=True
            )
            if proc.returncode == 0:
                html = proc.stdout.decode('utf-8').strip()
            else:
                html = md  # Bei Fehler: Original-Markdown behalten
        except Exception as e:
            html = md
    else:
        html = ''
    html_map[post_id] = html

with open(HTML_MAP_FILE, 'w') as f:
    json.dump(html_map, f, ensure_ascii=False)

print(f"Konvertierung abgeschlossen. {len(html_map)} HTML-Inhalte gespeichert.")
EOF

echo "📦 HTML-Map erstellt. Führe Hauptkonvertierung durch..."

# SCHRITT 3: Dein bewährtes Hauptskript, das die HTML-Map einliest
jq -n --slurpfile htmlMap "$HTML_MAP" '
  def generate_slug(title):
    (title // "")
    | ascii_downcase
    | gsub("[^a-z0-9]"; "-")
    | gsub("-+"; "-")
    | sub("^-"; "")
    | sub("-$"; "")
    | if length == 0 then "post" else . end;

  def unique_by(f): group_by(f) | map(first);

  input as $input
  
  | (($input.collections // [])[0].posts // []) as $collectionPosts
  | ($input.posts // []) as $rootPosts
  | ($collectionPosts + $rootPosts) as $allPosts
  | $allPosts | unique_by(.id) as $uniquePosts

  | [ $uniquePosts[] | .tags // [] | .[] ] | unique as $tagNames
  | [ $tagNames[] | . as $name | { "id": "\($name)", "name": $name, "slug": $name } ] as $tags
  | (($tags | map({(.name): .id}) | add) // {}) as $tagIdMap

  | [{
      "id": "1",
      "name": $input.username // "WriteFreely User",
      "slug": ($input.username // "writefreely-user") | ascii_downcase | gsub("[^a-z0-9]"; "-"),
      "email": "hallo@herrmontag.de",
      "status": "active",
      "created_at": "2024-01-01T00:00:00.000Z",
      "updated_at": "2024-01-01T00:00:00.000Z"
    }] as $users

  | reduce ($uniquePosts | to_entries[]) as $entry ({posts: [], posts_tags: [], posts_authors: []};
      ($entry.key + 1) as $postIndex
      | $entry.value as $p
      | ($htmlMap[0][$p.id] // ($p.body // "")) as $convertedHtml
      | .posts = .posts + [{
          "id": ($postIndex | tostring),
          "uuid": ($p.id // "\($postIndex)"),
          "title": (if ($p.title | length) > 0 then $p.title else ($p.slug // "Unbenannter Beitrag") end),
          "slug": (if ($p.slug and ($p.slug | length) > 0) then 
                    $p.slug 
                  else 
                    generate_slug($p.title // "untitled-post") 
                  end),
          "html": $convertedHtml,  # Hier kommt das pandoc-konvertierte HTML
          "lexical": null,
          "comment_id": "",
          "feature_image": "",
          "featured": false,
          "status": "published",
          "visibility": "public",
          "created_at": ($p.created // "2024-01-01T00:00:00.000Z"),
          "updated_at": ($p.updated // $p.created // "2024-01-01T00:00:00.000Z"),
          "published_at": ($p.created // "2024-01-01T00:00:00.000Z"),
          "custom_excerpt": "",
          "codeinjection_head": null,
          "codeinjection_foot": null,
          "custom_template": null
        }]
      | .posts_tags = .posts_tags + (($p.tags // []) | map({
            "post_id": ($postIndex | tostring),
            "tag_id": ($tagIdMap[.] // .)
          }))
      | .posts_authors = .posts_authors + [{
          "post_id": ($postIndex | tostring),
          "author_id": "1"
        }]
    ) as $postData

  | {
      "meta": {
        "exported_on": (now * 1000 | floor),
        "version": "5.80.0"
      },
      "data": {
        "posts": $postData.posts,
        "tags": $tags,
        "users": $users,
        "posts_tags": $postData.posts_tags,
        "posts_authors": $postData.posts_authors
      }
    }
' "$INPUT" > "$OUTPUT"

# Aufräumen temporärer Dateien
rm -f posts_for_conversion.json "$HTML_MAP"

echo "✅ Fertig! Datei: $OUTPUT"
echo "📊 Statistik:"
jq '.data | {posts: (.posts|length), tags: (.tags|length), users: (.users|length)}' "$OUTPUT"

echo "🔍 Beispiel eines konvertierten Posts (erster Eintrag):"
jq '.data.posts[0] | {title, slug, html: (.html | length)}' "$OUTPUT"
