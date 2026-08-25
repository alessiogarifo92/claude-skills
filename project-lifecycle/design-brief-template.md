# Design brief for Claude Design

Fill this in and paste it into a new Claude Design conversation (claude.ai/design) when
phase 3.5's canvas directions didn't land, or when the screens need real interaction that
static artboards can't show. Everything below is meant to be *specific* — a brief that could
describe any app produces a design that looks like any app.

Where the project already has a component library, run `/design-sync` first so the prototype
starts from the real components instead of generic ones, and say so in section 6.

---

## 1. What this is
One or two sentences: what the product does, for whom, and the single job of the screens
being prototyped. Name the platform and viewport (mobile app 390×844, web dashboard 1440×900, …).

## 2. Screens to prototype
List them by name, 2-4 maximum, with the one job of each. These are the same screens across
every direction — that's what makes the directions comparable.

- `<Screen name>` — <its one job>

## 3. Real content, not lorem
Paste actual example data in the shapes the app really produces: real labels, real names,
real amounts with their currency and format, realistic lengths (including the awkward long
one). Lorem ipsum hides exactly the layout problems this phase exists to catch.

## 4. States that must exist
For each screen, which states the prototype has to render — not just the happy one:
empty, loading, error, partial/degraded, success, and any domain-specific state
(overdue, pending approval, archived, …).

## 5. Interactions to make clickable
Write them as `tap X → Y happens`. Only the ones that carry a product decision; a prototype
that reproduces every gesture is a rebuild, not a prototype.

- tap `<element>` → `<result>`

## 6. Visual constraints
- **Tokens already decided** (leave blank if greenfield): palette as named hex, type roles and
  scale, spacing scale, radii, elevation. If these exist, they are *constraints* — the prototype
  explores layout, density, and hierarchy inside them, not around them.
- **Component library**: which one, and whether the prototype must match it or may invent.
- **Light/dark**: which the prototype must render.

## 7. Product constraints that shape the UI
Anything that changes what can be on screen: i18n (how many locales, which are the long ones),
accessibility floor, currency/number formatting, offline behaviour, permissions and role
differences, legal/compliance text, what the product deliberately does *not* do.

## 8. What to avoid
Name the defaults you don't want, concretely: overused typefaces, the palette the last attempt
produced, layout clichés that don't fit this product, and any direction already rejected — with
the reason it was rejected, so it isn't re-derived.

## 9. What to hand back
- How many distinct directions (default: 3), each with a name.
- Distinct means a different thesis — type pairing, layout density, hierarchy of the primary
  screen — not the same layout recolored.
- Whether each direction needs to be clickable or only the chosen one.
- The export you need back: shareable prototype link, PNG/PDF, or component handoff.
