# Visual language

- Canvas: deep navy `#0d1822`; card: `#142430`; border: `#293d4b`; primary text: `#f0f5f8`.
- Role-based colors: mint `#75e3c5` low, blue `#83bcff` moderate, amber `#f0c582` high, coral `#f48e92` very high/near capacity. Always pair color with a label. Neutral/missing uses slate; actual reported critical temperature uses distinct red `#ff6578` and a warning icon.
- One card grammar: title/info; current value; supporting units/context; time range; historical chart; time ticks; current meter; labeled state.
- Trends: opaque 2 px strokes with 10% fill. Store per-sample policy; interpolate crossing points without recoloring earlier data. Never lay the current meter over the historical trace.
- Bars: 6 px high, small threshold markers, bounded fill; exact numeric values remain unbounded.
- Cards: 14 px radius, 12 px internal padding, 10–14 px inter-card spacing. Compact header cards are 212 px high; detail cards are 220 px. Two columns of detail cards, three compact summary cards, at widths 480 px and above.
- Every chart says Last 2 minutes and shows −2m/−1m/now plus its current reference scale. Blank space means uncollected history, not zero.
- Every metric has ⓘ support for hover, focus, tap/click and keyboard pinning. Information is part of the product, not hidden solely in developer documentation.
- Header source/profile/battery/display values remain a compact summary; active hardware controls are unchanged. Overview prioritizes RAM/VRAM before display controls and cooling.

Documentation previews use synthetic history. Normal and critical fixtures must both be rendered during UI work. Use widget-only captures without personal desktop content.

Reference provenance must appear on hardware-dependent cards. Fan coral means Near reference, never a thermal danger claim; estimated references must be labeled on the card as well as in its info.
