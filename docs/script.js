(() => {
  'use strict';

  /* ----------------------------------------------------------
     Copy install command to clipboard
     ---------------------------------------------------------- */
  const cmdEl = document.getElementById('install-cmd');
  const btn = document.getElementById('copy-btn');

  if (cmdEl && btn) {
    const label = btn.querySelector('.copy-label');
    let resetTimer = null;

    const setState = (state) => {
      if (state === 'copied') {
        btn.classList.add('copied');
        if (label) label.textContent = 'Copied';
        btn.setAttribute('aria-label', 'Install command copied to clipboard');
      } else {
        btn.classList.remove('copied');
        if (label) label.textContent = 'Copy';
        btn.setAttribute('aria-label', 'Copy install command to clipboard');
      }
    };

    const copy = async () => {
      const text = cmdEl.textContent.trim();
      try {
        await navigator.clipboard.writeText(text);
      } catch {
        // fallback for older browsers / http
        const range = document.createRange();
        range.selectNode(cmdEl);
        const sel = window.getSelection();
        sel.removeAllRanges();
        sel.addRange(range);
        try { document.execCommand('copy'); } catch (_) { /* noop */ }
        sel.removeAllRanges();
      }
      setState('copied');
      clearTimeout(resetTimer);
      resetTimer = setTimeout(() => setState('idle'), 1800);
    };

    btn.addEventListener('click', copy);

    // Keyboard accessible: also allow clicking the code itself to copy.
    cmdEl.addEventListener('click', () => {
      // only treat as copy intent if user did not select text
      const sel = window.getSelection();
      if (sel && sel.toString().length > 0) return;
      copy();
    });
  }

  /* ----------------------------------------------------------
     Pull live GitHub stars + latest tag, replace the version chip.
     Best-effort: silently skip on rate-limit / offline.
     ---------------------------------------------------------- */
  const versionChip = document.querySelector('.chip-accent');
  if (versionChip && 'fetch' in window) {
    fetch('https://api.github.com/repos/ricciviero/Mole/releases/latest', {
      headers: { Accept: 'application/vnd.github+json' }
    })
      .then(r => (r.ok ? r.json() : null))
      .then(data => {
        if (!data || !data.tag_name) return;
        const tag = String(data.tag_name).replace(/^[Vv]/, 'v');
        versionChip.textContent = tag;
      })
      .catch(() => { /* keep static label */ });
  }
})();
