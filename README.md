# Daily Questions

The native macOS app stack is described in the [tech stack draft](specs/TECH_STACK.md).

Record technical explanations and check them against repository documentation and source code.

## First topic: chat message flow

Trace a chat message from the client through the Platform WebSocket, event bus, Redis streams, event router, and agent invocation, then trace the response back to the client.

The [original transcript](transcript.md) records the current understanding. Its architecture claims have not been verified.

## Validation goal

Compare the transcript with Platform documentation and source code. For each claim, identify what is correct, what needs correction, and what remains unclear. Cite the supporting file and line number.

Resolve these questions:

- Which component publishes the first event, and what does that event contain?
- How does the event router consume events and schedule work?
- What creates and handles an agent invocation request?
- What does the meta connector do?
- How do partial responses reach the client?
- What does `in_reply_to = None` mean, and what triggers a flush?

Use the findings to identify gaps in understanding and topics to study next.
