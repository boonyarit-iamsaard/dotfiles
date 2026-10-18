# Runbook: <procedure name>

- **Source:** `<path to issue or spec>`
- **Docs checked:** <YYYY-MM-DD>
- **Estimated time:** <minutes> · **Estimated cost:** <amount and basis>

Every identifier below is a placeholder. Substitute the real value on screen;
never write it into this file.

## Prerequisites

- [ ] <Tool and minimum version, with its install page>
- [ ] <Access the human needs before step 1>
- Region: `<region>`

## Decisions

| Fork | Choice | Why |
| --- | --- | --- |
| <option the docs leave open> | <chosen option> | <one line> |

## Steps

### - [ ] 1. Enable AWS Organizations with all features

- **Goal:** The existing account becomes the management account of an
  Organization.
- **Why:** Organizations lets member accounts be created and governed from one
  place; "all features" is needed for SCPs and centralized root access, where
  consolidated billing alone is not enough.
- **Where:** Console, signed in to `<MANAGEMENT_ACCOUNT_ID>` as root with
  MFA → AWS Organizations (per docs, verify on screen).
- **Do:**
  1. Choose **Create an organization**.
  2. Confirm the verification email sent to `<ROOT_EMAIL>`.
- **Expect:** The Organizations page lists one account, marked management
  account.
- **Verify:** `aws organizations describe-organization --profile <PROFILE>`
  shows `"FeatureSet": "ALL"` and `MasterAccountId` = `<MANAGEMENT_ACCOUNT_ID>`.
- **Undo:** ⚠️ Irreversible while member accounts exist; an organization can
  be deleted only after every member account is removed.
- **Ticks:** "AWS Organizations enabled with all features" in the source issue.
- **Source:** <official doc URL>

## Run log

### <YYYY-MM-DD>

- Completed: <steps>
- Deviations from docs: <what differed and how the step was corrected, or "none">
