# Claude Code Eval Loop

A self-hosted telemetry homelab for Claude Code usage, plus an analysis loop that turns that telemetry into concrete improvements to how Claude Code is set up.

## Language

**Friction event**:
A moment in a Session where Claude Code's work was blocked or wasted: a tool failure, a permission denial, or a user interrupt.
_Avoid_: error, issue, problem

**Tool failure**:
A tool call that returned unsuccessfully.
_Avoid_: tool error, failed call

**Permission denial**:
A tool call that the user or a hook rejected before it ran.
_Avoid_: rejection, block

**Interrupt**:
The user stopping Claude Code mid-turn.
_Avoid_: cancel, abort, correction

**Session**:
One Claude Code session, as identified by its session id. Work done by subagents counts toward the parent Session.
_Avoid_: conversation, run

**Active time**:
The time within a Session during which the user or Claude Code was actually working. Idle time does not count.

**Friction rate**:
The number of Friction events per hour of Active time. It is one of the two north-star metrics used to judge whether a Suggestion helped.
_Avoid_: efficiency score, friction score

**Cost rate**:
The US dollars spent per hour of Active time. It is the second north-star metric.
_Avoid_: token rate, spend, burn

**Suggestion**:
A proposed change to the Claude Code setup (a skill, hook, permission rule or CLAUDE.md line) that targets a specific source of Friction events.
_Avoid_: recommendation, improvement, fix
