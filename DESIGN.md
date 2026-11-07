---
name: Deutsche Verben
description: Native recall practice for German verb forms
colors:
  primary-light: "rgb(13% 34% 29%)"
  primary-dark: "rgb(45% 80% 67%)"
  prominent-label-light: "white"
  prominent-label-dark: "black"
typography:
  system:
    fontFamily: "-apple-system, BlinkMacSystemFont, sans-serif"
spacing:
  section: "24px"
  group: "20px"
  fields: "16px"
  accessibility-actions: "12px"
  related: "8px"
components:
  button-prominent-light:
    backgroundColor: "{colors.primary-light}"
    textColor: "{colors.prominent-label-light}"
  button-prominent-dark:
    backgroundColor: "{colors.primary-dark}"
    textColor: "{colors.prominent-label-dark}"
---

# Design System: Deutsche Verben

## Overview

**Creative North Star: "The Quiet Practice Desk"**

A quiet native practice desk: readable German forms, localized guidance, and one recall task at a time. The established web trainer supplies the restrained green accent and recall-first hierarchy; SwiftUI supplies navigation, controls, appearance, and interaction. Operate mode preserves product behavior while translating its presentation to iPhone and Mac.

Native SwiftUI for iPhone (iOS 18+) and Mac (macOS 15+). These are implemented platform targets, not an Android or browser design specification. Native defaults may change with the operating system; screenshots show one runtime, not fixed geometry to reproduce.

**Key Characteristics:**

- System typography and native controls.
- A vertically scrolling practice column with visible field labels.
- One green tint, adapted to light and dark appearance.
- Explicit text for assistance, scores, dates, and empty states.

## Colors

One green accent connects the native app to its incumbent trainer. The frontmatter preserves the source’s literal RGB proportions; it is normative for the custom colors.

### Primary

- **Forest Green** (`primary-light`): tint in light appearance, including prominent actions, selections, and progress.
- **Mint Green** (`primary-dark`): the same tint role in dark appearance.
- **Prominent labels**: white in light appearance; black in dark appearance, explicitly applied to prominent action labels.

### Neutral

Foregrounds use SwiftUI `primary` and `secondary`; backgrounds, separators, field surfaces, disabled states, and navigation materials are system-owned. They have no app-defined fixed color tokens. Status wording remains understandable without color.

**The One Tint Rule.** Use the appearance-aware green tint for app emphasis; let native semantic styles handle neutral surfaces and platform status treatment.

## Typography

The platform system font carries every role. The frontmatter font stack is a portable family description; SwiftUI semantic styles, not CSS font sizes, own actual rendering and Dynamic Type scaling.

- **Large title**: current infinitive (bold).
- **Title 2**: start/summary headings (semibold) and independent score (bold, monospaced digits).
- **Title 3**: meaning, feedback heading, and reference infinitives; weight varies by role.
- **Headline**: visible field labels, expected forms, summary values, and verb rows.
- **Body / callout**: instructions, contexts, original answers, examples, and explanations. German examples use italics; German forms/examples carry the German locale.
- **Subheadline / footnote / caption**: progress position, helper text, dates, and secondary guidance.

No fixed app font sizes, custom typefaces, tracking scale, or custom line heights are defined. Navigation titles and control typography remain native.

## Layout

Training is a `ScrollView` with a leading-aligned vertical stack. Its outer padding and section rhythm use the section token; its frame has a maximum width of 720 points and is centered in wider windows. The maximum includes the padded content. iPhone uses available width. Exercise and summary groups use the group token; fields use the fields token; closely related text uses the related token. The portable spacing tokens use CSS `px` notation for tooling; their native implementation unit is points.

Approach buttons and help buttons use horizontal rows at ordinary text sizes and vertical stacks with the accessibility-actions spacing at accessibility Dynamic Type sizes. Input fields stay vertically arranged. Scrolling accommodates content growth; do not infer a complete accessibility verification from one captured viewport.

Reference, progress, history, and data use native lists/forms and section spacing rather than imposing the training column’s measurements. Mac has one `Window` with minimum content size 540 × 560 points and default size 900 × 850 points. iPhone uses `WindowGroup`.

## Elevation & Depth

The app defines no custom shadows or elevation scale. System tab/navigation surfaces, grouped forms, bordered buttons, separators, and confirmation presentations provide hierarchy. There is no app-defined motion or transition vocabulary; standard SwiftUI behavior remains platform-owned.

## Shapes

Use system bordered and bordered-prominent buttons, rounded-border text fields, segmented auxiliary selection, native lists, forms, and disclosure groups. The app defines no reusable corner-radius scale or custom card component. Do not freeze the current OS’s capsule radius, material, or control outlines into new tokens.

## Components

### Navigation

Four `TabView` destinations, each with a `NavigationStack`: **Practice**, **Reference**, **Progress**, **Data**. Each uses a text label and SF Symbol. The table’s “Rules” button opens the rules separately. Original-answer history is a navigation drill-down from Progress, not a fifth tab.

### Buttons and fields

Primary actions use `.borderedProminent` and `.controlSize(.large)` with explicit appearance-specific label foregrounds. Approach/help actions use `.bordered` and large controls. Other list/form actions retain native defaults. Status is conveyed in titles and text, not just tint.

Präteritum and Partizip II have persistent visible labels and instruction text; their text fields use `.roundedBorder`, disable autocorrection, and disable iOS autocapitalization. Perfekt auxiliary selection is a labelled segmented picker with “Choose”, “haben”, and “sein”. Checking disables the answer controls and exposes inline feedback. Focus moves past → participle → auxiliary. Command-Return checks; Return advances a checked answer.

### Feedback and history

A divider separates the checked result from the input. Expected forms and original answers remain distinct and selectable. Independent results show numeric score and textual per-form status; assisted results say “Assisted” and omit independent score presentation. History uses disclosure rows to keep long records compact; expanding details reveals forms and counts as help. Summary separates independent and assisted attempt counts.

### Progress and reference

Native `ProgressView` presents exercise position and SM-2-adapted practice stages, with explicit accessibility labels/values. Stage percentages describe practice history, not recall probability or language level. The policy and ten sources are in [Documentation/RESEARCH.md](Documentation/RESEARCH.md). Reference uses aligned columns with a fixed header: Infinitiv, translation, Präteritum, Partizip II. Narrow windows put the translation below the infinitive. The Partizip II cell places the quieter inflected auxiliary directly before the participle, for example “ist gegangen” or “hat gehabt”. A row opens context and example; search and group filtering remain. Exposed forms count as help.

### Data and recovery

Use system alerts for errors and import results, confirmation dialogs before merge/restore, and JSON file import/export sheets. Merge preserves existing answers; restore is a separately labelled destructive action with a backup explanation. Drafts, paused approaches, original answers, help records, and JSON compatibility belong to the core package, not visual-only state. Do not alter them to simplify a screen.

## Do's and Don'ts

### Do:

- **Do** use semantic SwiftUI text styles and primary/secondary foregrounds.
- **Do** keep field labels and context visible before the learner answers.
- **Do** retain original answers beside feedback and label assisted attempts in text.
- **Do** let accessibility text sizes scroll and stack approach/help actions vertically.
- **Do** use system alerts, confirmation dialogs, file importers, and file exporters.

### Don't:

- **Don’t** replace native controls with fixed web dimensions or copied browser chrome.
- **Don’t** use color alone to communicate correctness or assistance.
- **Don’t** present study groups or practice-stage percentages as CEFR or memory probability.
- **Don’t** introduce custom animation, decorative shadows, or a second brand accent.

## Learning copy

Keep screens focused on the learning task. Do not show repeated CEFR/study-group disclaimers, research/diagnostic caveats, algorithm names, storage paths, help-event counters or raw event kinds. Detailed scientific and storage rationale belongs in README/Documentation. Keep field instructions, verb context, concise assistance labels, scoring feedback, actionable empty/error states and import/restore consequences. Explanation of the progress scale stays collapsed under “How to read the scale”. No extra training hero above the controls; the native navigation title supplies the heading.
