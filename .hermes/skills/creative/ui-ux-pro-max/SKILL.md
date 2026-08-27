---
name: ui-ux-pro-max
description: "Use when designing UI/UX, landing pages, or web apps."
version: 1.0.0
author: "madmasx + Hermes"
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [ui, ux, design, web, frontend, components, typography]
    homepage: https://github.com/NousResearch/hermes-agent
---

# UI/UX Pro Max

Advanced guidelines and workflow for designing high-end, conversion-focused, and accessible user interfaces and user experiences.

## Trigger Conditions
Use this skill when designing web applications, landing pages, dashboards, mobile interfaces, or refactoring existing UI/UX components.

## Core Design Principles
1. **Visual Hierarchy & Typography**: Use clear typographic scales (e.g., Inter, Plus Jakarta Sans, SF Pro). Limit font families to 1-2. Establish strong contrast for readability.
2. **Color Systems**: Adopt a semantic color palette (Neutral base, primary brand color, success/warning/error states). Support both dark and light modes with proper contrast ratios (WCAG AA/AAA).
3. **Spacing & Layout**: Use 4px/8px spacing grids (`p-2`, `p-4`, `space-y-4`). Prioritize whitespace to avoid cognitive overload.
4. **Feedback & Micro-interactions**: Provide instant visual feedback for user actions (hover states, active states, loading spinners, smooth transitions).
5. **Accessibility (a11y)**: Ensure correct ARIA labels, semantic HTML (`<header>`, `<main>`, `<button>`), keyboard navigation, and focus rings.

## Workflow Steps
1. **Define Requirements & User Flow**: Understand the core user goal and map out the primary journey.
2. **Establish Design Tokens**: Define colors, typography, border-radius, and shadows.
3. **Wireframe & Layout**: Draft the structural layout mobile-first before expanding to desktop.
4. **Component Implementation / Mockup**: Build clean, responsive HTML/CSS/JS or Tailwind components.
5. **Review & Refine**: Check against modern design standards (Stripe/Linear/Vercel aesthetic: clean borders, subtle gradients, micro-shadows).

## Common Pitfalls
- Overcrowding screens with too many competing focal points.
- Insufficient color contrast making text hard to read.
- Inconsistent padding, margins, or border-radius across components.
- Ignoring mobile responsiveness or touch target sizes (< 44x44px).

## Verification
- Verify responsiveness across mobile, tablet, and desktop viewports.
- Check color contrast ratios and keyboard accessibility.
- Ensure smooth transitions and zero layout shifts (CLS).
