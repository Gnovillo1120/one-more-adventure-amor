# Editable personal letter

The final personal letter has **not been written by Guillermo**. The shipped story deliberately labels its placeholder rather than presenting generated private sentiments as his exact words.

Edit `data/story.json` → `personal_letter` → `paragraphs` to supply the final letter. Keep its title/placeholder flag accurate. The runtime should read this separate object for the beach letter; do not duplicate final letter prose inside scene dialogue.

Suggested topics, not attributed words: the unexpected meeting; funny memories; adventures shared; what Anami means to you; adventures still ahead. Use natural Spanish and “amor.”

Required closing:

> Te amo, amor.
>
> Felices 3 años. ❤️
>
> 21 de octubre de 2023 — 21 de octubre de 2026

After editing, preview the ending to check accents, wrapping, page progression and the closing. Set `is_placeholder` to `false` and choose a personal title when the final text is supplied.
