# Interrupts come from filtered transcripts

Claude Code's OpenTelemetry export has no interrupt event, so the collector on the Mac tails the local session transcripts and forwards only interrupt markers (session id and timestamp). It drops every other line before anything leaves the Mac. Shipping full transcripts would put code and pasted content on a shared host and grow Loki's disk use. The analyzer skill can still read the full transcripts locally when it needs detail.
