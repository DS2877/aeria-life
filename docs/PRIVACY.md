# Privacy

This mirrors what the in-app Privacy Center actually shows — master prompt
§ 34: privacy is a product principle, not a page of legal text that says
something different from what the code does.

## Where data lives

Everything Aeria stores lives in this app's local SwiftData store, on this
device only. There is no backend server. CloudKit sync is not enabled by
default — see [`ARCHITECTURE.md`](ARCHITECTURE.md) § Persistence & sync for
why, and what turning it on later requires.

## What's processed, and where

- **Document scanning** (Vault): OCR runs on-device via Apple's `Vision`
  framework. The image and extracted text never leave the device.
- **Ask Aeria**: the default `RuleBasedIntelligenceProvider` is keyword
  matching + `NSDataDetector` — no model, no network call, nothing to send
  anywhere. The optional `FoundationModelsIntelligenceProvider` (not enabled
  by default) uses Apple's on-device Foundation Models — still no network
  call.
- **Search**: `NLEmbedding` sentence embeddings are computed on-device.
- **Weather**: only requested if WeatherKit is explicitly enabled (it isn't,
  by default) — see `Context/WeatherContextProvider.swift`.

## Permissions Aeria requests, and why

| Permission | Why | When asked |
|---|---|---|
| Calendar (full access) | Build Today, find free time | Onboarding, contextual |
| Reminders (full access) | Keep Today/Loose Ends complete | Onboarding, contextual |
| Location (when in use) | Travel time, local weather, Life Mode | Onboarding, contextual |
| Camera | Scan documents into Vault | First scan attempt |
| Photo Library | Import an existing photo of a document | First import attempt |
| Face ID | Optional Vault lock | Settings, opt-in |

Every permission is requested with an on-screen explanation immediately
before the system prompt (`PermissionStepView`) — never a blanket ask on one
screen (master prompt § 52).

## Memory

`MemoryFact` records are tagged by kind — explicit preference, inferred
preference, temporary context, or system fact (`MemoryKind`) — and "What
Aeria Knows" is a direct, unfiltered view over that table. Any fact can be
disabled (stops being used, stays inspectable) or deleted outright.

## Deleting everything

Privacy Center → Delete Everything removes every SwiftData record and every
file in the Vault storage directory. This is destructive and cannot be
undone — there's no server-side copy to restore from.
