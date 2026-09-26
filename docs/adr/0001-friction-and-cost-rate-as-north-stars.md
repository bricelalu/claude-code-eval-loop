# Friction rate and Cost rate as the north stars

We judge every Suggestion by two metrics: Friction rate (Friction events per hour of Active time) and Cost rate (USD per hour of Active time). Raw token counts were rejected because cache reads dominate them, so setup changes barely move them. Cost per session was rejected because it varies with task size. User corrections were left out of Friction events: detecting them needs semantic judgment on every prompt, which is either noisy (keyword rules) or expensive (an LLM at ingest).

## Consequences

Cost rate also moves when you switch models, so the analysis has to compare windows that used the same model mix before crediting a Suggestion.
