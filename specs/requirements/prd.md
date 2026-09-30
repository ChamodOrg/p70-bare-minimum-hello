# p70-bare-minimum-hello — PRD

## Problem Statement

Teams that need to stand up a new service on this platform have no minimal,
known-good reference to start from — every new project either copies an
existing, more complex service or builds its scaffolding from scratch,
costing time before any real feature work begins.

## Solution

A bare-minimum backend API with a single endpoint that returns a hello-world
greeting, reachable only by a signed-in caller. It exists as the smallest
possible working service on the platform: one authenticated endpoint, one
response, nothing else.

## Actors

- **Caller** — a signed-in user or system that has authenticated via Thunder
SSO and requests the greeting from the API.

## User Stories

1. As a Caller, I want to call the hello-world endpoint, so that I receive a
greeting message confirming the service is reachable and I am
authenticated.

## Product Decisions

- **Sign-in**: every call to the API must be authenticated via Thunder SSO,
this organization's platform IDP — an unauthenticated request is rejected.
- **Scope of the response**: the endpoint returns a fixed hello-world greeting
message; the greeting text itself is not configurable or personalized.
*assumed*
- **No web interface**: this project ships only the API — there is no page or
screen for a human to view the greeting in a browser.

## Out of Scope

- Any web page or UI for viewing the greeting.
- Any endpoint beyond the single hello-world greeting.
- User registration, roles, or permissions beyond being an authenticated
Thunder SSO caller.
- Personalizing or configuring the greeting message per caller.

## Open Questions

None at this time.