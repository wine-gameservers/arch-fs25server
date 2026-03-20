#!/usr/bin/env sh
set -eu

FILE="js/frontend.js"

BEGIN='\/\* === FS-DEDICATED PATCH BEGIN === \*\/'
END='\/\* === FS-DEDICATED PATCH END === \*\/'
OLDMARK='FS-DEDICATED: UNIVERSAL HOST REWRITE \(AUTO\)'

if [ ! -f "$FILE" ]; then
  echo "ERROR: $FILE not found"
  exit 1
fi

# 1) Remove any previously injected patch blocks (BEGIN..END)
# 2) Also remove the older marker-based patch if present
tmp="$(mktemp)"
awk -v begin_re="$BEGIN" -v end_re="$END" -v oldmark_re="$OLDMARK" '
  BEGIN {skip=0}
  $0 ~ oldmark_re {skip_old=1}
  $0 ~ begin_re {skip=1}
  skip==0 {print}
  $0 ~ end_re {skip=0; next}
' "$FILE" > "$tmp"

# (If you had the older patch without BEGIN/END markers and want it removed too,
# we can extend this — but most setups used the markers.)

mv "$tmp" "$FILE"

# If the fixed patch is already present (by marker), do nothing
if grep -q "FS-DEDICATED PATCH BEGIN" "$FILE"; then
  echo "OK: Web IP patch already applied"
  exit 0
fi

# Append the fixed patch
cat >>"$FILE" <<'EOF'

/* === FS-DEDICATED PATCH BEGIN === */
(function () {
  if (window.__fsUniversalRewriteInstalled) return;
  window.__fsUniversalRewriteInstalled = true;

  function isIPv4(h) { return /^(\d{1,3}\.){3}\d{1,3}$/.test(h); }

  function isPrivateIPv4(ip) {
    var p = ip.split(".").map(Number);
    if (p.length !== 4) return false;
    for (var i = 0; i < 4; i++) if (p[i] < 0 || p[i] > 255) return false;

    var a = p[0], b = p[1];
    return (
      a === 10 ||
      (a === 172 && b >= 16 && b <= 31) ||
      (a === 192 && b === 168) ||
      a === 127 ||
      (a === 169 && b === 254) ||
      a === 0
    );
  }

  function isInternalHost(hostname) {
    if (!hostname) return false;
    var h = hostname.toLowerCase();
    if (h === "localhost" || h.endsWith(".local")) return true;
    if (isIPv4(h) && isPrivateIPv4(h)) return true;
    return false;
  }

  // Force target port 7999 always
  var TARGET_HOSTNAME = window.location.hostname;
  var TARGET_HOSTPORT = TARGET_HOSTNAME + ":7999";

  // If you are browsing using an internal/private address, do nothing.
  // This avoids internal->internal rewrites and mutation loops.
  if (isInternalHost(TARGET_HOSTNAME)) return;

  var scheduled = false;
  var inRewrite = false;

  function rewrite() {
    if (inRewrite) return;
    inRewrite = true;
    scheduled = false;

    // Disconnect observer while rewriting to prevent self-trigger storms
    var obs = window.__fsUniversalRewriteObserver;
    if (obs) obs.disconnect();

    try {
      var anchors = document.querySelectorAll("a[href]");
      for (var i = 0; i < anchors.length; i++) {
        var a = anchors[i];
        var raw = a.getAttribute("href");
        if (!raw) continue;

        var u;
        try { u = new URL(raw, window.location.href); }
        catch (e) { continue; }

        if (u.protocol !== "http:" && u.protocol !== "https:") continue;

        if (isInternalHost(u.hostname)) {
          u.hostname = TARGET_HOSTNAME;
          u.port = "7999";
          var newHref = u.toString();
          if (a.getAttribute("href") !== newHref) a.setAttribute("href", newHref);
        }

        if (a.textContent) {
          var oldText = a.textContent;
          var newText = oldText.replace(
            /\b(?:localhost|(?:\d{1,3}\.){3}\d{1,3})(?::\d+)?\b/g,
            function (m) {
              var host = m.split(":")[0];
              return isInternalHost(host) ? TARGET_HOSTPORT : m;
            }
          );
          if (newText !== oldText) a.textContent = newText;
        }
      }
    } finally {
      // Reconnect observer
      try {
        if (obs) {
          obs.observe(document.body || document.documentElement, { childList: true, subtree: true });
        }
      } catch (e) {}
      inRewrite = false;
    }
  }

  function scheduleRewrite() {
    if (scheduled) return;
    scheduled = true;
    setTimeout(rewrite, 50);
  }

  function start() {
    rewrite();
    try {
      var mo = new MutationObserver(scheduleRewrite);
      window.__fsUniversalRewriteObserver = mo;
      mo.observe(document.body || document.documentElement, { childList: true, subtree: true });
    } catch (e) {}
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", start);
  } else {
    start();
  }
})();
/* === FS-DEDICATED PATCH END === */
EOF

echo "OK: Web IP Patch installed/updated in $FILE"
