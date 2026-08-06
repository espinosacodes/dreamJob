# 01 — Product spec

**Status: specified.** No product surface is built yet.

## Problem

Job applying is three chores stacked: finding postings scattered across thousands of boards, reading each one to discover it doesn't match, and tailoring a resume per application — the step that decides the outcome and the step everyone skips.

## Product statement

dreamJob turns the job hunt into a short daily deck of pre-filtered cards. Swipe right and an agent tailors your resume and cover letter to that specific posting, shows you the result, and submits it.

## Primary user

One person, running the system for themselves, on their own machine.

- Software engineer or adjacent (the initial matcher vocabulary is engineering-shaped).
- Applying actively — tens of applications over weeks, not one a quarter.
- Has a master resume they consider decent and no time to rewrite it 40 times.
- Cares about not getting their LinkedIn account banned.

Explicitly **not** the initial user: recruiters, agencies, or anyone applying on behalf of someone else. Multi-tenant is out of scope through M7.

## Core user stories

| # | As a user I want | So that | Milestone |
| --- | --- | --- | --- |
| U1 | postings pulled automatically from the boards I care about | I stop tab-hopping | M1 |
| U2 | one canonical card per role even when it's cross-posted five places | my deck isn't 5× duplicates | M1 |
| U3 | to state my preferences once, in one file | filtering is predictable and auditable | M2 |
| U4 | anything below my bar dropped before I see it | a day's deck is finishable in five minutes | M2 |
| U5 | to see comp, work mode, and location on the card face | I never open a posting to learn it's onsite abroad | M3 |
| U6 | left-swipes to teach the matcher | the deck improves without me editing weights | M3 / M7 |
| U7 | my resume tailored to the specific posting on a right-swipe | I clear ATS keyword screens | M4 |
| U8 | to read and edit every application before it goes out | I never send the wrong company's name | M4 |
| U9 | one-click submit where the platform permits it | tailoring, not form-filling, is where my time goes | M5b |
| U10 | an archive of exactly what I sent where, and when | I can follow up and answer "did I apply here?" | M6 |
| U11 | to answer "notice period", "work authorization", "expected salary" once, not forty times | the boring half of applying stops being manual | M5a |
| U12 | the agent to fill the employer's own web form and let me press submit | I'm not limited to the minority of jobs with an application API | M5b |
| U13 | account signups and their email codes handled for me | a Workday tenant I'll use once doesn't cost me ten minutes | M5a |
| U14 | replies detected from my inbox and matched to what I sent | I know my reply rate without keeping a spreadsheet | M6 |

## Scope

**In scope through M7**

- Ingestion from ATS platforms with public job-board APIs (Greenhouse, Lever, Ashby, Workable).
- Per-site scraping for individual company career pages the user adds.
- Preference-driven matching with a learned component.
- A local swipe UI.
- Per-application resume and cover-letter tailoring driven by the existing resume skills, rendered to an ATS-verified PDF ([17](17-resume-artifacts.md)).
- Submission through a documented application endpoint where one exists; otherwise the employer's own web form, filled by a browser agent with a human pressing submit ([14](14-browser-agent.md)); a prefilled draft everywhere else.
- Employer-system accounts the applications need, with credentials in the OS keychain and email verification handled ([15](15-accounts-identity.md)).
- Mailbox-driven application tracking and follow-up reminders ([16](16-mailbox.md)).

**Out of scope**

- LinkedIn and Indeed automation of any kind, including Easy Apply. See [09](09-compliance.md) and [15](15-accounts-identity.md) for what *is* supported — the user's own data export, profile keyword work, referral drafting.
- Solving CAPTCHAs, rotating IPs, spoofing fingerprints, or otherwise evading anti-automation controls. Unchanged by the browser agent: a site that blocks automation has succeeded, and the application falls back to a manual draft.
- Unattended submission. A human presses submit on every application through M6.
- Sending email as the user, or automating SMS verification with virtual numbers.
- Hosting other people's resumes. Single-user, local-first.
- Interview scheduling, offer negotiation, salary benchmarking.
- A web version. The UI is a Flutter app targeting Android and iOS; the desktop build exists only as a development convenience. See [11](11-frontend.md).
- Any volume play — see the quality bar below. Browser submission widens *which* jobs are reachable; it does not raise the cap.

## Non-goals, stated as constraints

1. **Not a spray-and-pray tool.** Target output is ~20 strong tailored applications per week. Mass low-effort applying is precisely what ATS filters catch. Any feature that raises volume at the cost of per-application quality is a non-goal.
2. **Not autonomous through M6.** A human reads every application before it is sent and presses submit on every one of them, including the browser-driven ones. The gates are removed only when the output is boringly reliable, and never silently.
3. **Not a resume generator.** The system never invents a metric, employer, date, or skill — and never a form answer either. See the honesty rules in [09](09-compliance.md).
4. **Not an account farm.** Every employer account it creates is the user's, created with the user's knowledge, one approval at a time ([15](15-accounts-identity.md)).

## Success metrics

Measured per user, over rolling 30 days.

| Metric | Definition | Target |
| --- | --- | --- |
| Deck completion | share of daily decks swiped to the bottom | > 80% |
| Right-swipe rate | right-swipes ÷ cards shown | 10–25% (below is a matcher that's too loose, above is one that's too tight) |
| False-positive rate | right-swipes the user later abandons at the review gate | < 10% |
| Time to application | right-swipe → submitted | < 10 min, of which < 3 min is user time |
| Reply rate | employer responses ÷ applications sent | beat the user's pre-dreamJob baseline, which M6 must capture first |
| Wrong-send incidents | applications sent with another company's name, a stale bullet, an unfilled placeholder, or a generic resume where a tailored one was reported | 0 |
| Unverified submissions | forms submitted with neither a confirmation page nor a confirmation email | < 5% of browser submissions |

The wrong-send row is a release blocker, not a target.

## Open questions

- Does the deck have a daily cap, or is it just "everything above threshold"? A cap protects U4 but may hide good matches.
- Is cover-letter generation always on, or per-posting opt-in? Some ATS forms make it optional and a weak letter can hurt.
- Should the system ever re-surface a left-swiped posting when the profile changes materially?
